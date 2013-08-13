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

Ohai.plugin do
  include Ohai::Mixin::Ec2Metadata
  
  provides "ec2"

  depends "fqdn", "domain"
  depends "kernel"
  depends "network", "counters/network"

  def has_ec2_mac?
    network[:interfaces].values.each do |iface|
      unless iface[:arp].nil?
        if iface[:arp].value?("fe:ff:ff:ff:ff:ff")
          Ohai::Log.debug("has_ec2_mac? == true")
          return true
        end
      end
    end
    Ohai::Log.debug("has_ec2_mac? == false")
    false
  end

  def looks_like_ec2?
    # Try non-blocking connect so we don't "block" if 
    # the Xen environment is *not* EC2
    hint?('ec2') || has_ec2_mac? && can_metadata_connect?(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR,80)
  end

  collect_data do
    if looks_like_ec2?
      Ohai::Log.debug("looks_like_ec2? == true")
      ec2 Mash.new
      fetch_metadata.each {|k, v| ec2[k] = v }
      ec2[:userdata] = self.fetch_userdata
    else
      Ohai::Log.debug("looks_like_ec2? == false")
      false
    end
  end
end
