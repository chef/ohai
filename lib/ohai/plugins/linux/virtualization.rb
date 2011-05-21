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
    virtualization[:system] = "xen"
    virtualization[:role] = "host"
elsif File.exists?("/proc/sys/xen/independent_wallclock")
  virtualization[:system] = "xen"
  virtualization[:role] = "guest"
end

# Detect KVM hosts by kernel module
if File.exists?("/proc/modules")
  if File.read("/proc/modules") =~ /^kvm/
    virtualization[:system] = "kvm"
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
    virtualization[:system] = "kvm"
    virtualization[:role] = "guest"
  end
end

# http://wiki.openvz.org/Proc/user_beancounters
if File.exists?("/proc/user_beancounters")
  if File.read("/proc/user_beancounters") =~ /\n\s+0:\s+/
    virtualization[:emulator] = "openvz"
    virtualization[:role] = "host"
  else
    virtualization[:emulator] = "openvz"
    virtualization[:role] = "guest"
  end
end

# http://www.dmo.ca/blog/detecting-virtualization-on-linux
if File.exists?("/usr/sbin/dmidecode")
  popen4("dmidecode") do |pid, stdin, stdout, stderr|
    stdin.close
    dmi_info = stdout.read
    case dmi_info
    when /Manufacturer: Microsoft/
      if dmi_info =~ /Product Name: Virtual Machine/ 
        virtualization[:system] = "virtualpc"
        virtualization[:role] = "guest"
      end 
    when /Manufacturer: VMware/
      if dmi_info =~ /Product Name: VMware Virtual Platform/ 
        virtualization[:system] = "vmware"
        virtualization[:role] = "guest"
      end
    when /Manufacturer: Xen/
      if dmi_info =~ /Product Name: HVM domU/
        virtualization[:system] = "xen"
        virtualization[:role] = "guest"  
      end
    else
      nil
    end

  end
end

# Detect Linux-VServer
if File.exists?("/proc/self/status")
  proc_self_status = File.read("/proc/self/status")
  vxid = proc_self_status.match(/^(s_context|VxID): (\d+)$/)
  if vxid and vxid[2]
    virtualization[:system] = "linux-vserver"
    if vxid[2] == "0"
      virtualization[:role] = "host"
    else
      virtualization[:role] = "guest"
     end
  end
end

# Detect OpenVZ
# something in /proc/vz/veinfo
