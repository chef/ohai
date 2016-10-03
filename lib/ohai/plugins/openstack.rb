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

require "info_getter/mixin/ec2_metadata"

info_getter.plugin(:Openstack) do
  include info_getter::Mixin::Ec2Metadata

  provides "openstack"
  depends "dmi"
  depends "etc"

  # do we have the openstack dmi data
  def openstack_dmi?
    # detect a manufacturer of OpenStack Foundation
    if get_attribute(:dmi, :system, :all_records, 0, :Manufacturer) =~ /OpenStack/
      info_getter::Log.debug("Plugin Openstack: has_openstack_dmi? == true")
      return true
    else
      info_getter::Log.debug("Plugin Openstack: has_openstack_dmi? == false")
      return false
    end
  end

  # check for the info_getter hint and log debug messaging
  def openstack_hint?
    if hint?("openstack")
      info_getter::Log.debug("Plugin Openstack: openstack hint present")
      return true
    else
      info_getter::Log.debug("Plugin Openstack: openstack hint not present")
      return false
    end
  end

  # dreamhost systems have the dhc-user on them
  def openstack_provider
    return "dreamhost" if get_attribute("etc", "passwd", "dhc-user")
    return "openstack"
  end

  collect_data do
    # fetch data if we look like openstack
    if openstack_hint? || openstack_dmi?
      openstack Mash.new
      openstack[:provider] = openstack_provider

      # fetch the metadata if we can do a simple socket connect first
      if can_metadata_connect?(info_getter::Mixin::Ec2Metadata::EC2_METADATA_ADDR, 80)
        fetch_metadata.each do |k, v|
          openstack[k] = v
        end
        info_getter::Log.debug("Plugin Openstack: Successfully fetched Openstack metadata from the metadata endpoint")
      else
        info_getter::Log.debug("Plugin Openstack: Timed out connecting to Openstack metadata endpoint. Skipping metadata.")
      end
    else
      info_getter::Log.debug("Plugin Openstack: Node does not appear to be an Openstack node")
    end
  end
end
