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
# 2. Xen hypervisor UUID starts with 'ec2'. This catches Linux HVM & paravirt instances
# 3. DMI bios version data mentions amazon. This catches HVM instances in a VPC on the Xen based hypervisor
# 3. DMI bios vendor data mentions amazon. This catches HVM instances in a VPC on the non-Xen based hypervisor
# 4. Kernel data mentioned Amazon. This catches Windows HVM & paravirt instances

Ohai.plugin(:EC2) do
  require_relative "../mixin/ec2_metadata"
  require_relative "../mixin/http_helper"
  require "base64"

  include Ohai::Mixin::Ec2Metadata
  include Ohai::Mixin::HttpHelper

  provides "ec2"

  # look for amazon string in dmi vendor bios data within the sys tree.
  # this works even if the system lacks dmidecode use by the Dmi plugin
  # this gets us detection of new Xen-less HVM instances that are within a VPC
  # @return [Boolean] do we have Amazon DMI data?
  def has_ec2_amazon_dmi?
    # detect a version of '4.2.amazon'
    if file_val_if_exists("/sys/class/dmi/id/bios_vendor") =~ /Amazon/
      logger.trace("Plugin EC2: has_ec2_amazon_dmi? == true")
      true
    else
      logger.trace("Plugin EC2: has_ec2_amazon_dmi? == false")
      false
    end
  end

  # look for amazon string in dmi bios version data within the sys tree.
  # this works even if the system lacks dmidecode use by the Dmi plugin
  # this gets us detection of HVM instances that are within a VPC
  # @return [Boolean] do we have Amazon DMI data?
  def has_ec2_xen_dmi?
    # detect a version of '4.2.amazon'
    if file_val_if_exists("/sys/class/dmi/id/bios_version") =~ /amazon/
      logger.trace("Plugin EC2: has_ec2_xen_dmi? == true")
      true
    else
      logger.trace("Plugin EC2: has_ec2_xen_dmi? == false")
      false
    end
  end

  # looks for a xen UUID that starts with ec2 from within the Linux sys tree
  # @return [Boolean] do we have a Xen UUID or not?
  def has_ec2_xen_uuid?
    if file_val_if_exists("/sys/hypervisor/uuid") =~ /^ec2/
      logger.trace("Plugin EC2: has_ec2_xen_uuid? == true")
      return true
    end
    logger.trace("Plugin EC2: has_ec2_xen_uuid? == false")
    false
  end

  # looks at the identifying number WMI value to see if it starts with ec2.
  # this is actually the same value we're looking at in has_ec2_xen_uuid? on
  # linux hosts
  # @return [Boolean] do we have a Xen Identifying Number or not?
  def has_ec2_identifying_number?
    if RUBY_PLATFORM =~ /mswin|mingw32|windows/
      require "wmi-lite/wmi"
      wmi = WmiLite::Wmi.new
      if wmi.first_of("Win32_ComputerSystemProduct")["identifyingnumber"] =~ /^ec2/
        logger.trace("Plugin EC2: has_ec2_identifying_number? == true")
        return true
      end
    else
      logger.trace("Plugin EC2: has_ec2_identifying_number? == false")
      false
    end
  end

  # return the contents of a file if the file exists
  # @param path[String] abs path to the file
  # @return [String] contents of the file if it exists
  def file_val_if_exists(path)
    if ::File.exist?(path)
      ::File.read(path)
    end
  end

  # a single check that combines all the various detection methods for EC2
  # @return [Boolean] Does the system appear to be on EC2
  def looks_like_ec2?
    return true if hint?("ec2")

    # Even if it looks like EC2 try to connect first
    if has_ec2_xen_uuid? || has_ec2_amazon_dmi? || has_ec2_xen_dmi? || has_ec2_identifying_number?
      return true if can_socket_connect?(Ohai::Mixin::Ec2Metadata::EC2_METADATA_ADDR, 80)
    end
  end

  collect_data do
    if looks_like_ec2?
      logger.trace("Plugin EC2: looks_like_ec2? == true")
      ec2 Mash.new
      fetch_metadata.each do |k, v|
        # fetch_metadata returns IAM security credentials, including the IAM user's
        # secret access key. We'd rather not have ohai send this information
        # to the server.
        # http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AESDG-chapter-instancedata.html#instancedata-data-categories
        next if k == "iam" && !hint?("iam")

        ec2[k] = v
      end
      ec2[:userdata] = fetch_userdata
      ec2[:account_id] = fetch_dynamic_data["accountId"]
      ec2[:availability_zone] = fetch_dynamic_data["availabilityZone"]
      ec2[:region] = fetch_dynamic_data["region"]
      # ASCII-8BIT is equivalent to BINARY in this case
      if ec2[:userdata] && ec2[:userdata].encoding.to_s == "ASCII-8BIT"
        logger.trace("Plugin EC2: Binary UserData Found. Storing in base64")
        ec2[:userdata] = Base64.encode64(ec2[:userdata])
      end
    else
      logger.trace("Plugin EC2: looks_like_ec2? == false")
      false
    end
  end
end
