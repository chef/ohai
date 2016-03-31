#
# Author:: Tim Dysinger (<tim@dysinger.net>)
# Author:: Benjamin Black (<bb@chef.io>)
# Author:: Christopher Brown (<cb@chef.io>)
# Author:: Tim Smith (<tsmith@chef.io>)
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

# How we detect EC2 from easiest to hardest & least reliable
# 1. Ohai ec2 hint exists. This always works
# 2. DMI data mentions amazon. This catches HVM instances in a VPC
# 2. Kernel data mentioned Amazon. This catches Windows instances
# 3. Has a xen MAC + can connect to metadata. This catches paravirt instances not in a VPC
# 4. Has ec2metadata binary + can connect to metadata. This catches paravirt instances in a VPC

require "ohai/mixin/ec2_metadata"
require "base64"

Ohai.plugin(:EC2) do
  include Ohai::Mixin::Ec2Metadata

  provides "ec2"

  depends "network/interfaces"
  depends "dmi"
  depends "kernel"

  # look for ec2metadata and see if we get data back
  # this gets us detection of paravirt instances that are within a VPC
  def has_ec2metadata_bin?
    if File.exist?("/usr/bin/ec2metadata")
      # make sure actual data is returned when we run it. Otherwise we might be on GCE or Rackspace
      if shell_out("/usr/bin/ec2metadata").stdout =~ /id: ami-/
        Ohai::Log.debug("ec2 plugin: has_ec2metadata_bin? == true")
        return true
      else
        Ohai::Log.debug("ec2 plugin: has_ec2metadata_bin? found ec2metadata but no metadata returned. Not on EC2")
        return false
      end
    else
      Ohai::Log.debug("ec2 plugin: has_ec2metadata_bin? == false")
      return false
    end
  end

  # look for xen arp address
  # this gets us detection of paravirt instances that are NOT within a VPC
  def has_xen_mac?
    network[:interfaces].values.each do |iface|
      unless iface[:arp].nil?
        if iface[:arp].value?("fe:ff:ff:ff:ff:ff")
          # using MAC addresses from ARP is unreliable because they could time-out from the table
          # fe:ff:ff:ff:ff:ff is actually a sign of Xen, not specifically EC2
          deprecation_message <<-EOM
ec2 plugin: Detected EC2 by the presence of fe:ff:ff:ff:ff:ff in the ARP table. This method is unreliable and will be removed in a future version of ohai. Bootstrap using knife-ec2 or create "/etc/chef/ohai/hints/ec2.json" instead.
EOM
          Ohai::Log.warn(deprecation_message)
          Ohai::Log.debug("ec2 plugin: has_xen_mac? == true")
          return true
        end
      end
    end
    Ohai::Log.debug("ec2 plugin: has_xen_mac? == false")
    false
  end

  # look for amazon string in dmi bios data
  # this gets us detection of HVM instances that are within a VPC
  def has_ec2_dmi?
    begin
      # detect a version of '4.2.amazon'
      if dmi[:bios][:all_records][0][:Version] =~ /amazon/
        Ohai::Log.debug("ec2 plugin: has_ec2_dmi? == true")
        true
      end
    rescue NoMethodError
      Ohai::Log.debug("ec2 plugin: has_ec2_dmi? == false")
      false
    end
  end

  # looks for the Amazon.com Organization in Windows Kernel data
  # this gets us detection of Windows systems
  def has_amazon_org?
    begin
      # detect an Organization of 'Amazon.com'
      if kernel[:os_info][:organization] =~ /Amazon/
        Ohai::Log.debug("ec2 plugin: has_amazon_org? == true")
        true
      end
    rescue NoMethodError
      Ohai::Log.debug("ec2 plugin: has_amazon_org? == false")
      false
    end
  end

  def looks_like_ec2?
    return true if hint?("ec2")

    # Even if it looks like EC2 try to connect first
    if has_ec2_dmi? || has_amazon_org? || has_xen_mac? || has_ec2metadata_bin?
      return true if can_metadata_connect?(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR, 80)
    end
  end

  collect_data do
    if looks_like_ec2?
      Ohai::Log.debug("ec2 plugin: looks_like_ec2? == true")
      ec2 Mash.new
      fetch_metadata.each do |k, v|
        # fetch_metadata returns IAM security credentials, including the IAM user's
        # secret access key. We'd rather not have ohai send this information
        # to the server.
        # http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AESDG-chapter-instancedata.html#instancedata-data-categories
        next if k == "iam" && !hint?("iam")
        ec2[k] = v
      end
      ec2[:userdata] = self.fetch_userdata
      # ASCII-8BIT is equivalent to BINARY in this case
      if ec2[:userdata] && ec2[:userdata].encoding.to_s == "ASCII-8BIT"
        Ohai::Log.debug("ec2 plugin: Binary UserData Found. Storing in base64")
        ec2[:userdata] = Base64.encode64(ec2[:userdata])
      end
    else
      Ohai::Log.debug("ec2 plugin: looks_like_ec2? == false")
      false
    end
  end
end
