# frozen_string_literal: true
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Ohai.plugin(:Azure) do
  require_relative "../mixin/azure_metadata"
  require_relative "../mixin/http_helper"
  require_relative "../mixin/smbios"

  include Ohai::Mixin::AzureMetadata
  include Ohai::Mixin::HttpHelper
  include Ohai::Mixin::Smbios

  provides "azure"

  collect_data do
    # Before we had the metadata endpoint we relied exclusively on
    # the knife-azure plugin populating data to the hint file.
    # Please see the lib/chef/knife/azure_server_create.rb file in that
    # project for details
    azure_metadata_from_hints = hint?("azure")
    if azure_metadata_from_hints
      logger.trace("Plugin Azure: Azure hint is present. Parsing any hint data.")
      azure Mash.new
      azure_metadata_from_hints.each { |k, v| azure[k] = v }
      azure["metadata"] = parse_metadata
    elsif has_azure_chassis_asset_tag?
      logger.trace("Plugin Azure: No hints present, but the Azure chassis asset tag is.")
      azure Mash.new
      azure["metadata"] = parse_metadata
    elsif has_waagent? || has_dhcp_option_245? || has_reddog_dhcp_domain?
      metadata = parse_metadata
      if metadata.nil? && other_cloud_metadata_service?
        # The agent and DHCP lease files survive moving a disk to another
        # cloud, so the metadata service is the better signal here.
        logger.trace("Plugin Azure: Azure agent or DHCP options found, but the metadata service at #{Ohai::Mixin::AzureMetadata::AZURE_METADATA_ADDR} has no Azure endpoint. Not on Azure.")
        false
      else
        logger.trace("Plugin Azure: No hints present, but system appears to be on Azure.")
        azure Mash.new
        azure["metadata"] = metadata
      end
    else
      logger.trace("Plugin Azure: No hints present and doesn't appear to be on Azure.")
      false
    end
  end

  # check for either the waagent or the unknown-245 DHCP option that Azure uses
  # http://blog.mszcool.com/index.php/2015/04/detecting-if-a-virtual-machine-runs-in-microsoft-azure-linux-windows-to-protect-your-software-when-distributed-via-the-azure-marketplace/
  def has_azure_chassis_asset_tag?
    if smbios_value(:chassis_asset_tag) == Ohai::Mixin::AzureMetadata::AZURE_CHASSIS_ASSET_TAG
      logger.trace("Plugin Azure: Found the Azure chassis asset tag.")
      true
    else
      false
    end
  end

  def has_waagent?
    if Ohai::Mixin::AzureMetadata::WAAGENT_PATHS.any? { |path| file_exist?(path) } || dir_exist?("C:\\WindowsAzure")
      logger.trace("Plugin Azure: Found waagent used by Azure.")
      true
    end
  end

  def has_dhcp_option_245?
    has_245 = false
    if file_exist?("/var/lib/dhcp/dhclient.eth0.leases")
      file_open("/var/lib/dhcp/dhclient.eth0.leases").each do |line|
        if line.include?("unknown-245")
          logger.trace("Plugin Azure: Found unknown-245 DHCP option used by Azure.")
          has_245 = true
          break
        end
      end
    end
    has_245
  end

  def has_reddog_dhcp_domain?
    tcp_ip_dhcp_domain == "reddog.microsoft.com"
  end

  def tcp_ip_dhcp_domain
    return unless RUBY_PLATFORM.match?(/mswin|mingw|windows/)

    if ChefUtils.windows?
      require "win32/registry" unless defined?(Win32::Registry)
    end

    begin
      key = Win32::Registry::HKEY_LOCAL_MACHINE.open("SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters")
      dhcp_domain = key["DhcpDomain"]
      Ohai::Log.trace("Plugin Azure: DhcpDomain registry value is #{dhcp_domain}")
    rescue Win32::Registry::Error
      Ohai::Log.trace("Plugin Azure: DhcpDomain registry value cannot be found")
    end

    dhcp_domain
  end

  # create the basic structure we'll store our data in
  def initialize_metadata_mash_compute
    metadata = Mash.new
    metadata["compute"] = Mash.new
    metadata
  end

  def initialize_metadata_mash_network(metadata)
    metadata["network"] = Mash.new
    metadata["network"]["interfaces"] = Mash.new
    %w{public_ipv4 local_ipv4 public_ipv6 local_ipv6}.each do |type|
      metadata["network"][type] = []
    end
    metadata
  end

  # an interface can lack an address family, and an address can lack a
  # public IP (it is an empty string or missing)
  def fetch_ip_data(data, type, field)
    Array(data.dig(type, "ipAddress")).filter_map do |val|
      ip = val[field]
      ip unless ip.nil? || ip.empty?
    end
  end

  # EC2 and other clouds run their own metadata service on the same link-local
  # address. It accepts the connection but answers 404 for Azure's instance
  # metadata path, which Azure itself always serves.
  def other_cloud_metadata_service?
    return false unless @metadata_endpoint_reachable

    http_get("/metadata/instance?api-version=#{best_api_version}").code == "404"
  rescue => e
    logger.trace("Plugin Azure: Unable to query the metadata service: #{e}")
    false
  end

  def parse_metadata
    @metadata_endpoint_reachable = can_socket_connect?(Ohai::Mixin::AzureMetadata::AZURE_METADATA_ADDR, 80)
    return nil unless @metadata_endpoint_reachable

    endpoint_data = begin
                      fetch_metadata
                    rescue => e
                      # a transient metadata service error shouldn't drop azure
                      # data the agent, asset tag or hint already established
                      logger.warn("Plugin Azure: Unable to fetch Azure metadata: #{e.class}: #{e.message}")
                      nil
                    end
    return nil if endpoint_data.nil?

    metadata = initialize_metadata_mash_compute

    # blindly add everything in compute to our data structure
    (endpoint_data["compute"] || {}).each do |k, v|
      metadata["compute"][k] = v
    end

    # receiving network output is not guaranteed
    unless endpoint_data["network"].nil?
      metadata = initialize_metadata_mash_network(metadata)
      # parse out per interface interface IP data
      Array(endpoint_data["network"]["interface"]).each do |int|
        metadata["network"]["interfaces"][int["macAddress"]] = Mash.new
        metadata["network"]["interfaces"][int["macAddress"]]["mac"] = int["macAddress"]
        metadata["network"]["interfaces"][int["macAddress"]]["public_ipv6"] = fetch_ip_data(int, "ipv6", "publicIpAddress")
        metadata["network"]["interfaces"][int["macAddress"]]["public_ipv4"] = fetch_ip_data(int, "ipv4", "publicIpAddress")
        metadata["network"]["interfaces"][int["macAddress"]]["local_ipv6"] = fetch_ip_data(int, "ipv6", "privateIpAddress")
        metadata["network"]["interfaces"][int["macAddress"]]["local_ipv4"] = fetch_ip_data(int, "ipv4", "privateIpAddress")
      end

      # aggregate the total IP data
      %w{public_ipv4 local_ipv4 public_ipv6 local_ipv6}.each do |type|
        metadata["network"]["interfaces"].each_value do |val|
          metadata["network"][type].concat val[type] unless val[type].empty?
        end
      end
    end

    metadata
  end
end
