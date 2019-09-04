#
# Author:: Matt Ray (<matt@chef.io>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2012-2019 Chef Software, Inc.
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
  require "etc" unless defined?(Etc)
  include Ohai::Mixin::Ec2Metadata
  include Ohai::Mixin::HttpHelper

  provides "openstack"
  depends "virtualization"

  # use virtualization data
  def openstack_virtualization?
    if get_attribute(:virtualization, :systems, :openstack)
      logger.trace("Plugin Openstack: has_openstack_virtualization? == true")
      true
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
    # dream host doesn't support windows so bail early if we're on windows
    return "openstack" if RUBY_PLATFORM =~ /mswin|mingw32|windows/

    if Etc.getpwnam("dhc-user")
      "dreamhost"
    end
  rescue ArgumentError # getpwnam raises ArgumentError if the user is not found
    "openstack"
  end

  collect_data do
    # fetch data if we look like openstack
    if openstack_hint? || openstack_virtualization?
      openstack Mash.new
      openstack[:provider] = openstack_provider

      timeout = Ohai::Config.ohai[:openstack_metadata_timeout] || 2

      # fetch the metadata if we can do a simple socket connect first
      if can_socket_connect?(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR, 80, timeout)
        fetch_metadata.each do |k, v|
          openstack[k] = v unless v.empty?
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
