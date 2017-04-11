#
# Author:: Tim Dysinger (<tim@dysinger.net>)
# Author:: Benjamin Black (<bb@chef.io>)
# Author:: Christopher Brown (<cb@chef.io>)
# Copyright:: Copyright (c) 2009-2016 Chef Software, Inc.
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

# eucalyptus metadata service is compatible with the ec2 service calls
require "ohai/mixin/ec2_metadata"
require "ohai/mixin/http_helper"

Ohai.plugin(:Eucalyptus) do
  include Ohai::Mixin::Ec2Metadata
  include Ohai::Mixin::HttpHelper

  provides "eucalyptus"
  depends "network/interfaces"

  # returns the mac address from the collection of all address types
  def get_mac_address(addresses)
    detected_addresses = addresses.detect { |address, keypair| keypair == { "family" => "lladdr" } }
    if detected_addresses
      return detected_addresses.first
    else
      return ""
    end
  end

  # detect if the mac address starts with d0:0d
  def has_euca_mac?
    network[:interfaces].values.each do |iface|
      mac = get_mac_address(iface[:addresses])
      if mac =~ /^[dD]0:0[dD]:/
        Ohai::Log.debug("Plugin Eucalyptus: has_euca_mac? == true (#{mac})")
        return true
      end
    end

    Ohai::Log.debug("Plugin Eucalyptus: has_euca_mac? == false")
    false
  end

  def looks_like_euca?
    # Try non-blocking connect so we don't "block" if
    # the metadata service doesn't respond
    hint?("eucalyptus") || has_euca_mac? && can_socket_connect?(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR, 80)
  end

  collect_data do
    if looks_like_euca?
      Ohai::Log.debug("Plugin Eucalyptus: looks_like_euca? == true")
      eucalyptus Mash.new
      self.fetch_metadata.each do |k, v|
        # Eucalyptus 3.4+ supports IAM roles and Instance Profiles much like AWS
        # https://www.eucalyptus.com/blog/2013/10/15/iam-roles-and-instance-profiles-eucalyptus-34
        #
        # fetch_metadata returns IAM security credentials, including the IAM user's
        # secret access key. We'd rather not have ohai send this information
        # to the server.
        # http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AESDG-chapter-instancedata.html#instancedata-data-categories
        next if k == "iam" && !hint?("iam")
        eucalyptus[k] = v
      end
      eucalyptus[:userdata] = self.fetch_userdata
    else
      Ohai::Log.debug("Plugin Eucalyptus: looks_like_euca? == false")
      false
    end
  end
end
