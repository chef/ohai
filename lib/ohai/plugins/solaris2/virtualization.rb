#
# Author:: Sean Walbran (<seanwalbran@gmail.com>)
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

# Detect KVM/QEMU from cpuinfo, report as KVM
psrinfo_path="/usr/sbin/psrinfo"
if File.exists?(psrinfo_path)
  popen4(psrinfo_path + " -pv") do |pid, stdin, stdout, stderr|
    stdin.close
    psr_info = stdout.read
    if psr_info =~ /QEMU Virtual CPU/
      virtualization[:emulator] = "kvm"
      virtualization[:role] = "guest"
    end
  end
end

# http://www.dmo.ca/blog/detecting-virtualization-on-linux
smbios_path="/usr/sbin/smbios"
if File.exists?(smbios_path)
  popen4(smbios_path) do |pid, stdin, stdout, stderr|
    stdin.close
    dmi_info = stdout.read
    case dmi_info
    when /Manufacturer: Microsoft/
      if dmi_info =~ /Product: Virtual Machine/ 
        virtualization[:emulator] = "virtualpc"
        virtualization[:role] = "guest"
      end 
    when /Manufacturer: VMware/
      if dmi_info =~ /Product: VMware Virtual Platform/ 
        virtualization[:emulator] = "vmware"
        virtualization[:role] = "guest"
      end
    else
      nil
    end

  end
end
