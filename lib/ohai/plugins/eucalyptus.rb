#
# Author:: Tim Dysinger (<tim@dysinger.net>)
# Author:: Benjamin Black (<bb@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'ohai/mixin/ec2_metadata'

Ohai.plugin(:Eucalyptus) do
  include Ohai::Mixin::Ec2Metadata

  provides "eucalyptus"

  depends "network/interfaces"

  def get_mac_address(addresses)
    detected_addresses = addresses.detect { |address, keypair| keypair == {"family"=>"lladdr"} }
    if detected_addresses
      return detected_addresses.first
    else
      return ""
    end
  end

  def has_euca_mac?
    network[:interfaces].values.each do |iface|
      has_mac = (get_mac_address(iface[:addresses]) =~ /^[dD]0:0[dD]:/)
      Ohai::Log.debug("has_euca_mac? == #{!!has_mac}")
      return true if has_mac
    end

    Ohai::Log.debug("has_euca_mac? == false")
    false
  end

  def looks_like_euca?
    # Try non-blocking connect so we don't "block" if
    # the Xen environment is *not* EC2
    hint?('eucalyptus') || has_euca_mac? && can_metadata_connect?(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR,80)
  end

  collect_data do
    if looks_like_euca?
      Ohai::Log.debug("looks_like_euca? == true")
      eucalyptus Mash.new
      self.fetch_metadata.each do |k, v|
        # Eucalyptus 3.4+ supports IAM roles and Instance Profiles much like AWS
        # https://www.eucalyptus.com/blog/2013/10/15/iam-roles-and-instance-profiles-eucalyptus-34
        #
        # fetch_metadata returns IAM security credentials, including the IAM user's
        # secret access key. We'd rather not have ohai send this information
        # to the server.
        # http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AESDG-chapter-instancedata.html#instancedata-data-categories
        next if k == 'iam' && !hint?('iam')
        eucalyptus[k] = v
      end
      eucalyptus[:userdata] = self.fetch_userdata
    else
      Ohai::Log.debug("looks_like_euca? == false")
      false
    end
  end
end
