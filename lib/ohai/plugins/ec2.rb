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

require 'ohai/mixin/ec2_metadata'
require 'base64'

Ohai.plugin(:EC2) do
  include Ohai::Mixin::Ec2Metadata

  provides "ec2"

  depends "network/interfaces"
  depends "dmi"

  # look for arp address that non-VPC hosts will have
  def has_ec2_mac?
    network[:interfaces].values.each do |iface|
      unless iface[:arp].nil?
        if iface[:arp].value?("fe:ff:ff:ff:ff:ff")
          # using MAC addresses from ARP is unreliable because they could time-out from the table
          # fe:ff:ff:ff:ff:ff is actually a sign of Xen, not specifically EC2
          deprecation_message <<-EOM
Detected EC2 by the presence of fe:ff:ff:ff:ff:ff in the ARP table. This method is unreliable and will be removed in a future version of ohai. Use knife-ec2 or create "/etc/chef/ohai/hints/ec2.json" instead.
EOM
          Ohai::Log.warn(deprecation_message)
          Ohai::Log.debug("has_ec2_mac? == true")
          return true
        end
      end
    end
    Ohai::Log.debug("has_ec2_mac? == false")
    false
  end

  # look for amazon string in dmi bios data
  # this only works on hvm instances as paravirt instances have no dmi data
  def has_ec2_dmi?
    begin
      # detect a version of '4.2.amazon'
      if dmi[:bios][:all_records][0][:Version] =~ /amazon/
        Ohai::Log.debug("has_ec2_dmi? == true")
        true
      end
    rescue NoMethodError
      Ohai::Log.debug("has_ec2_dmi? == false")
      false
    end
  end


  def looks_like_ec2?
    # Try non-blocking connect so we don't "block" if
    # the Xen environment is *not* EC2
    hint?('ec2') || ( has_ec2_dmi? || has_ec2_mac?) && can_metadata_connect?(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR,80)
  end

  collect_data do
    if looks_like_ec2?
      Ohai::Log.debug("looks_like_ec2? == true")
      ec2 Mash.new
      fetch_metadata.each do |k, v|
        # fetch_metadata returns IAM security credentials, including the IAM user's
        # secret access key. We'd rather not have ohai send this information
        # to the server.
        # http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AESDG-chapter-instancedata.html#instancedata-data-categories
        next if k == 'iam' && !hint?('iam')
        ec2[k] = v
      end
      ec2[:userdata] = self.fetch_userdata
      #ASCII-8BIT is equivalent to BINARY in this case
      if ec2[:userdata] && ec2[:userdata].encoding.to_s == "ASCII-8BIT"
        Ohai::Log.debug("Binary UserData Found. Storing in base64")
        ec2[:userdata] = Base64.encode64(ec2[:userdata])
      end
    else
      Ohai::Log.debug("looks_like_ec2? == false")
      false
    end
  end
end
