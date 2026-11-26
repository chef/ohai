# frozen_string_literal: true
#
# Author:: Sean Walbran (<seanwalbran@gmail.com>)
# Author:: Kurt Yoder (<ktyopscode@yoderhome.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
  require_relative "../../mixin/dmi_decode"
  include Ohai::Mixin::DmiDecode
  provides "virtualization"
  depends "dmi"

  def collect_solaris_guestid
    shell_out("/usr/sbin/zoneadm list -p").stdout.split(":").first
  end

  # Records a kernel zone or logical domain. It becomes the primary system
  # unless a guest was already found, or, for a host role, unless the global
  # zone hosts other zones.
  def add_virtinfo_system(system, role)
    virtualization[:systems][system] = role
    return if virtualization[:role] == "guest"
    return if role == "host" && virtualization.key?(:guests)

    virtualization[:system] = system
    virtualization[:role] = role
  end

  # Solaris 11.4 virtinfo(8) lists a "kernel-zone" environment in the
  # "current" class when run inside a kernel zone. virtinfo before 11.4 has
  # no get subcommand and never prints such a row.
  def kernel_zone_guest?(virtinfo_path)
    shell_out("#{virtinfo_path} get all").stdout.lines.any? do |line|
      line.split[0..1] == %w{kernel-zone current}
    end
  end

  # SPARC only: the DOMAINROLE line of `virtinfo -ap` says whether this
  # logical domain is the control domain
  def ldom_role(virtinfo_path)
    domainrole = shell_out("#{virtinfo_path} -ap").stdout.lines.find { |line| line.start_with?("DOMAINROLE|") }
    return unless domainrole

    fields = domainrole.chomp.split("|").drop(1).to_h do |field|
      key, value = field.split("=", 2)
      [key, value]
    end
    return unless fields["impl"] == "LDoms"

    fields["control"] == "true" ? "host" : "guest"
  end

  collect_data(:solaris2) do
    virtualization Mash.new
    virtualization[:systems] = Mash.new

    # Detect paravirt KVM/QEMU from cpuinfo, report as KVM
    psrinfo_path = Ohai.abs_path( "/usr/sbin/psrinfo" )
    if file_exist?(psrinfo_path)
      so = shell_out("#{psrinfo_path} -pv")
      if /QEMU Virtual CPU|Common KVM processor|Common 32-bit KVM processor/.match?(so.stdout)
        virtualization[:system] = "kvm"
        virtualization[:role] = "guest"
        virtualization[:systems][:kvm] = "guest"
      end
    end

    # parse dmi to discover various virtualization guests
    guest = guest_from_dmi_data(get_attribute(:dmi, :system, :manufacturer), get_attribute(:dmi, :system, :product), get_attribute(:dmi, :system, :version))
    if guest
      logger.trace("Plugin Virtualization: DMI data indicates #{guest} guest")
      virtualization[:system] = guest
      virtualization[:role] = "guest"
      virtualization[:systems][guest.to_sym] = "guest"
    end

    if File.executable?("/usr/sbin/zoneadm")
      zones = Mash.new
      shell_out("zoneadm list -pc").stdout.lines do |line|
        info = line.chomp.split(":")
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
        virtualization[:system] = "zone"
        if first_zone == "global"
          virtualization[:role] = "host"
          virtualization[:systems][:zone] = "host"
        else
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

      if zones.values.any? { |zone| zone["brand"] == "solaris-kz" }
        virtualization[:systems]["kernel-zone"] = "host"
      end
    end

    virtinfo_path = Ohai.abs_path("/usr/sbin/virtinfo")
    if file_exist?(virtinfo_path)
      add_virtinfo_system("kernel-zone", "guest") if kernel_zone_guest?(virtinfo_path)

      role = ldom_role(virtinfo_path)
      add_virtinfo_system("ldom", role) if role
    end
  end
end
