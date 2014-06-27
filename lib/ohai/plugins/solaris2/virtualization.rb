#
# Author:: Sean Walbran (<seanwalbran@gmail.com>)
# Author:: Kurt Yoder (<ktyopscode@yoderhome.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# Copyright:: Copyright (c) 2010 Kurt Yoder
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

Ohai.plugin(:Virtualization) do
  provides "virtualization"

  def collect_solaris_guestid
    command = '/usr/sbin/zoneadm list -p'
    so = shell_out(command)
    so.stdout.split(':').first
  end

  collect_data(:solaris2) do
    virtualization Mash.new

    # Detect KVM/QEMU from cpuinfo, report as KVM
    psrinfo_path = Ohai.abs_path( "/usr/sbin/psrinfo" )
    if File.exists?(psrinfo_path)
      so = shell_out("#{psrinfo_path} -pv")
      if so.stdout =~ /QEMU Virtual CPU/
        virtualization[:system] = "kvm"
        virtualization[:role] = "guest"
      end
    end

    # http://www.dmo.ca/blog/detecting-virtualization-on-linux
    smbios_path= Ohai.abs_path( "/usr/sbin/smbios" )
    if File.exists?(smbios_path)
      so = shell_out(smbios_path)
      case so.stdout
      when /Manufacturer: Microsoft/
        if so.stdout =~ /Product: Virtual Machine/ 
          virtualization[:system] = "virtualpc"
          virtualization[:role] = "guest"
        end 
      when /Manufacturer: VMware/
        if so.stdout =~ /Product: VMware Virtual Platform/ 
          virtualization[:system] = "vmware"
          virtualization[:role] = "guest"
        end
      else
        nil
      end
    end

    if File.executable?('/usr/sbin/zoneadm')
      zones = Mash.new
      so = shell_out("zoneadm list -pc")
      so.stdout.lines do |line|
        info = line.chomp.split(/:/)
        zones[info[1]] = {
          'id' => info[0],
          'state' => info[2],
          'root' => info[3],
          'uuid' => info[4],
          'brand' => info[5],
          'ip' => info[6],
        }
      end
        
      if (zones.length == 1)
        first_zone = zones.keys[0]
        unless( first_zone == 'global')
          virtualization[:system] = 'zone'
          virtualization[:role] = 'guest'
          virtualization[:guest_uuid] = zones[first_zone]['uuid']
          virtualization[:guest_id] = collect_solaris_guestid
        end
      elsif (zones.length > 1)
        virtualization[:system] = 'zone'
        virtualization[:role] = 'host'
        virtualization[:guests] = zones
      end
    end
  end
end
