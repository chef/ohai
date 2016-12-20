#
# Author:: Tim Smith <tsmith@chef.io>
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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

# http://www.dmo.ca/blog/detecting-virtualization-on-linux
module ::Ohai::Mixin::DmiDecode
  def guest_from_dmi(dmi_data)
    dmi_data.each_line do |line|
      case line
      when /Manufacturer: Microsoft/
        if dmi_data =~ /Product.*: Virtual Machine/
          if dmi_data =~ /Version: (7.0|Hyper-V)/
            return "hyperv"
          elsif dmi_data =~ /Version: (VS2005R2|6.0)/
            return "virtualpc"
          elsif dmi_data =~ /Version: 5.0/
            return "virtualserver"
          end
        end
      when /Manufacturer: VMware/
        return "vmware"
      when /Manufacturer: Xen/
        return "xen"
      when /Product.*: VirtualBox/
        return "vbox"
      when /Product.*: OpenStack/
        return "openstack"
      when /Manufacturer: QEMU|Product Name: (KVM|RHEV)/
        return "kvm"
      when /Product.*: BHYVE/
        return "bhyve"
      when /Manufacturer: Veertu/
        return "veertu"
      end
    end
    return nil
  end
end
