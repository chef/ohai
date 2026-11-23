# frozen_string_literal: true
#
# Author:: Matt Ray (<matt@chef.io>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Ohai.plugin(:Openstack) do
  require_relative "../mixin/ec2_metadata"
  require_relative "../mixin/http_helper"
  require_relative "../mixin/smbios"
  include Ohai::Mixin::Ec2Metadata
  include Ohai::Mixin::HttpHelper
  include Ohai::Mixin::Smbios

  provides "openstack"
  depends "virtualization"

  # use virtualization data. "host" means the nova client or compute
  # service is installed, which a workstation can have too; only a guest is
  # running on OpenStack.
  def openstack_virtualization?
    if get_attribute(:virtualization, :systems, :openstack) == "guest"
      logger.trace("Plugin Openstack: has_openstack_virtualization? == true")
      true
    end
  end

  # chassis asset tags that OpenStack based public clouds set instead of the
  # usual Nova product name (the same values cloud-init's ds-identify uses)
  def openstack_asset_tags
    ["OpenTelekomCloud", "HUAWEICLOUD", "SAP CCloud VM"]
  end

  # look for OpenStack in the SMBIOS data directly. The virtualization
  # plugin only sees it through dmidecode, which needs root.
  def openstack_dmi?
    if smbios_value(:product_name).to_s.match?(/^OpenStack (Nova|Compute)/) || openstack_asset_tags.include?(smbios_value(:chassis_asset_tag))
      logger.trace("Plugin Openstack: openstack_dmi? == true")
      true
    else
      logger.trace("Plugin Openstack: openstack_dmi? == false")
      false
    end
  end

  # check for the ohai hint and log trace messaging
  def openstack_hint?
    if hint?("openstack")
      logger.trace("Plugin Openstack: openstack hint present")
      true
    else
      logger.trace("Plugin Openstack: openstack hint not present")
      false
    end
  end

  # dreamhost systems *had* the dhc-user on them < 2016. We should probably remove all this logic
  # https://help.dreamhost.com/hc/en-us/articles/228377408-How-to-find-the-default-user-of-an-image
  def openstack_provider
    # dream host doesn't support windows so bail early if we're on windows
    return "openstack" if RUBY_PLATFORM.match?(/mswin|mingw|windows/)

    if Etc::Passwd.entries.map(&:name).include?("dhc-user")
      "dreamhost"
    else
      "openstack"
    end
  end

  collect_data do
    require "etc" unless defined?(Etc)

    # fetch data if we look like openstack
    if openstack_hint? || openstack_virtualization? || openstack_dmi?
      openstack Mash.new
      openstack[:provider] = openstack_provider

      timeout = Ohai::Config.ohai[:openstack_metadata_timeout] || 2

      # fetch the metadata if we can do a simple socket connect first
      if can_socket_connect?(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR, 80, timeout)
        fetch_metadata.each do |k, v|
          # a path that returns 404 comes back as nil
          openstack[k] = v unless v.nil? || v.empty?
        end
        logger.trace("Plugin Openstack: Successfully fetched Openstack metadata from the metadata endpoint")
      else
        logger.trace("Plugin Openstack: Timed out connecting to Openstack metadata endpoint. Skipping metadata.")
      end
    else
      logger.trace("Plugin Openstack: Node does not appear to be an Openstack node")
    end
  end
end
