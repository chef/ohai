# Copyright:: Copyright 2013-2017 Chef Software, Inc.
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

  include Ohai::Mixin::AzureMetadata
  include Ohai::Mixin::HttpHelper

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
    elsif has_waagent? || has_dhcp_option_245?
      logger.trace("Plugin Azure: No hints present, but system appears to be on Azure.")
      azure Mash.new
      azure["metadata"] = parse_metadata
    else
      logger.trace("Plugin Azure: No hints present and doesn't appear to be on Azure.")
      false
    end
  end

  # check for either the waagent or the unknown-245 DHCP option that Azure uses
  # http://blog.mszcool.com/index.php/2015/04/detecting-if-a-virtual-machine-runs-in-microsoft-azure-linux-windows-to-protect-your-software-when-distributed-via-the-azure-marketplace/
  def has_waagent?
    if File.exist?("/usr/sbin/waagent") || Dir.exist?('C:\WindowsAzure')
      logger.trace("Plugin Azure: Found waagent used by Azure.")
      true
    end
  end

  def has_dhcp_option_245?
    has_245 = false
    if File.exist?("/var/lib/dhcp/dhclient.eth0.leases")
      File.open("/var/lib/dhcp/dhclient.eth0.leases").each do |line|
        if line =~ /unknown-245/
          logger.trace("Plugin Azure: Found unknown-245 DHCP option used by Azure.")
          has_245 = true
          break
        end
      end
    end
    has_245
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

  def fetch_ip_data(data, type, field)
    ips = []

    data[type]["ipAddress"].each do |val|
      ips << val[field] unless val[field].empty?
    end
    ips
  end

  def parse_metadata
    return nil unless can_socket_connect?(Ohai::Mixin::AzureMetadata::AZURE_METADATA_ADDR, 80)

    endpoint_data = fetch_metadata
    return nil if endpoint_data.nil?

    metadata = initialize_metadata_mash_compute

    # blindly add everything in compute to our data structure
    endpoint_data["compute"].each do |k, v|
      metadata["compute"][k] = v
    end

    # receiving network output is not guaranteed
    unless endpoint_data["network"].nil?
      metadata = initialize_metadata_mash_network(metadata)
      # parse out per interface interface IP data
      endpoint_data["network"]["interface"].each do |int|
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
