#
# Author:: Tim Smith <tsmith@chef.io>
# Copyright:: Copyright (c) 2015-2018 Chef Software, Inc.
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
  def guest_from_dmi_data(manufacturer, product, version)
    case manufacturer
    when /OpenStack/
      return "openstack"
    when /Xen/
      return "xen"
    when /VMware/
      return "vmware"
    when /Microsoft/
      return "hyperv" if product =~ /Virtual Machine/
    when /Amazon EC2/
      return "amazonec2"
    when /QEMU/
      return "kvm"
    when /Veertu/
      return "veertu"
    when /Parallels/
      return "parallels"
    end

    case product
    when /VirtualBox/
      return "vbox"
    when /OpenStack/ # yes this is here twice. Product catches Redhat's version
      return "openstack"
    when /(KVM|RHEV)/
      return "kvm"
    when /BHYVE/
      return "bhyve"
    end

    nil # doesn't look like a virt
  end
end
