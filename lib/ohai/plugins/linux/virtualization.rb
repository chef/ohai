#
# Author:: Thom May (<thom@clearairturbulence.org>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

provides "virtualization"

virtualization Mash.new

# if it is possible to detect paravirt vs hardware virt, it should be put in
# virtualization[:mechanism]
if File.exists?("/proc/xen/capabilities") && File.read("/proc/xen/capabilities") =~ /control_d/i
    virtualization[:emulator] = "xen"
    virtualization[:role] = "host"
elsif File.exists?("/proc/sys/xen/independent_wallclock")
  virtualization[:emulator] = "xen"
  virtualization[:role] = "guest"
end

# Detect KVM hosts by kernel module
if File.exists?("/proc/modules")
  if File.read("/proc/modules") =~ /^kvm/
    virtualization[:emulator] = "kvm"
    virtualization[:role] = "host"
  end
end

# Detect KVM/QEMU from cpuinfo, report as KVM
# We could pick KVM from 'Booting paravirtualized kernel on KVM' in dmesg
# 2.6.27-9-server (intrepid) has this / 2.6.18-6-amd64 (etch) does not
# It would be great if we could read pv_info in the kernel
# Wait for reply to: http://article.gmane.org/gmane.comp.emulators.kvm.devel/27885
if File.exists?("/proc/cpuinfo")
  if File.read("/proc/cpuinfo") =~ /QEMU Virtual CPU/
    virtualization[:emulator] = "kvm"
    virtualization[:role] = "guest"
  end
end

# http://www.dmo.ca/blog/detecting-virtualization-on-linux
if File.exists?("/usr/sbin/dmidecode")
  popen4("dmidecode") do |pid, stdin, stdout, stderr|
    stdin.close
    found_virt_manufacturer = nil
    stdout.each do |line|
      case line
      when /Manufacturer: Microsoft/
        found_virt_manufacturer = "virtualpc"
      when / Product Name: Virtual Machine/
        if found_virt_manufacturer == "virtualpc" 
          virtualization[:emulator] = "virtualpc"
          virtualization[:role] = "guest"
        end
      when /Manufacturer: VMware/
        found_virt_manufacturer = "vmware"
      when /Product Name: VMware Virtual Platform/
        if found_virt_manufacturer == "vmware" 
          virtualization[:emulator] = "vmware"
          virtualization[:role] = "guest"
        end
      end
    end
  end
end
