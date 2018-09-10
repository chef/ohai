#
# Author:: Matt Ray (<matt@chef.io>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2012-2016 Chef Software, Inc.
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
  require "ohai/mixin/ec2_metadata"
  require "ohai/mixin/http_helper"
  include Ohai::Mixin::Ec2Metadata
  include Ohai::Mixin::HttpHelper

  provides "openstack"
  depends "dmi"
  depends "etc"

  # do we have the openstack dmi data
  def openstack_dmi?
    # detect a manufacturer of OpenStack Foundation
    if get_attribute(:dmi, :system, :all_records, 0, :Manufacturer) =~ /OpenStack/
      logger.trace("Plugin Openstack: has_openstack_dmi? == true")
      true
    elsif get_attribute(:dmi, :system, :product_name) == "OpenStack Compute"
      logger.trace("Plugin Openstack: has_openstack_dmi? == true")
      true
    else
      logger.trace("Plugin Openstack: has_openstack_dmi? == false")
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

  # dreamhost systems have the dhc-user on them
  def openstack_provider
    return "dreamhost" if get_attribute("etc", "passwd", "dhc-user")
    "openstack"
  end

  collect_data do
    # fetch data if we look like openstack
    if openstack_hint? || openstack_dmi?
      openstack Mash.new
      openstack[:provider] = openstack_provider

      # fetch the metadata if we can do a simple socket connect first
      if can_socket_connect?(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR, 80, 10)
        fetch_metadata.each do |k, v|
          openstack[k] = v
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
