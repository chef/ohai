#
# Author:: Sean Walbran (<seanwalbran@gmail.com>)
# Author:: Kurt Yoder (<ktyopscode@yoderhome.com>)
# Copyright:: Copyright (c) 2009-2016 Chef Software, Inc.
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

require "ohai/mixin/dmi_decode"

Ohai.plugin(:Virtualization) do
  include Ohai::Mixin::DmiDecode
  provides "virtualization"

  def collect_solaris_guestid
    command = "/usr/sbin/zoneadm list -p"
    so = shell_out(command)
    so.stdout.split(":").first
  end

  collect_data(:solaris2) do
    virtualization Mash.new
    virtualization[:systems] = Mash.new

    # Detect paravirt KVM/QEMU from cpuinfo, report as KVM
    psrinfo_path = Ohai.abs_path( "/usr/sbin/psrinfo" )
    if File.exist?(psrinfo_path)
      so = shell_out("#{psrinfo_path} -pv")
      if so.stdout =~ /QEMU Virtual CPU|Common KVM processor|Common 32-bit KVM processor/
        virtualization[:system] = "kvm"
        virtualization[:role] = "guest"
        virtualization[:systems][:kvm] = "guest"
      end
    end

    # Pass smbios information to the dmi_decode mixin to
    # identify possible virtualization systems
    smbios_path = Ohai.abs_path("/usr/sbin/smbios")
    if File.exist?(smbios_path)
      guest = guest_from_dmi(shell_out(smbios_path).stdout)
      if guest
        virtualization[:system] = guest
        virtualization[:role] = "guest"
        virtualization[:systems][guest.to_sym] = "guest"
      end
    end

    if File.executable?("/usr/sbin/zoneadm")
      zones = Mash.new
      so = shell_out("zoneadm list -pc")
      so.stdout.lines do |line|
        info = line.chomp.split(/:/)
        zones[info[1]] = {
          "id" => info[0],
          "state" => info[2],
          "root" => info[3],
          "uuid" => info[4],
          "brand" => info[5],
          "ip" => info[6],
        }
      end

      if zones.length == 1
        first_zone = zones.keys[0]
        if first_zone == "global"
          virtualization[:system] = "zone"
          virtualization[:role] = "host"
          virtualization[:systems][:zone] = "host"
        else
          virtualization[:system] = "zone"
          virtualization[:role] = "guest"
          virtualization[:systems][:zone] = "guest"
          virtualization[:guest_uuid] = zones[first_zone]["uuid"]
          virtualization[:guest_id] = collect_solaris_guestid
        end
      elsif zones.length > 1
        virtualization[:system] = "zone"
        virtualization[:role] = "host"
        virtualization[:systems][:zone] = "host"
        virtualization[:guests] = zones
      end
    end
  end
end
