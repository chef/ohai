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

## Xen
# /proc/xen is an empty dir for EL6 + Linode Guests
if File.exists?("/proc/xen")
  virtualization[:system] = "xen"
  # Assume guest
  virtualization[:role] = "guest"

  # This file should exist on most Xen systems, normally empty for guests
  if File.exists?("/proc/xen/capabilities")
    if File.read("/proc/xen/capabilities") =~ /control_d/i
      virtualization[:role] = "host"
    end
  end
end

# Xen Notes:
# - cpuid of guests, if we could get it, would also be a clue
# - may be able to determine if under paravirt from /dev/xen/evtchn (See OHAI-253)
# - EL6 guests carry a 'hypervisor' cpu flag
# - Additional edge cases likely should not change the above assumptions
#   but rather be additive - btm

# Detect from kernel module
if File.exists?("/proc/modules")
  modules = File.read("/proc/modules")
  if modules =~ /^kvm/
    virtualization[:system] = "kvm"
    virtualization[:role] = "host"
  elsif modules =~ /^vboxdrv/
    virtualization[:system] = "vbox"
    virtualization[:role] = "host"
  elsif modules =~ /^vboxguest/
    virtualization[:system] = "vbox"
    virtualization[:role] = "guest"
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

# Detect OpenVZ / Virtuozzo.
# http://wiki.openvz.org/BC_proc_entries
if File.exists?("/proc/bc/0")
  virtualization[:system] = "openvz"
  virtualization[:role] = "host"
elsif File.exists?("/proc/vz")
  virtualization[:system] = "openvz"
  virtualization[:role] = "guest"
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
