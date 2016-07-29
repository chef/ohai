#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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

  collect_data(:freebsd, :openbsd, :netbsd, :dragonflybsd) do

    virtualization Mash.new unless virtualization
    virtualization[:systems] = Mash.new unless virtualization[:systems]

    # detect when in a jail or when a jail is actively running (not in stopped state)
    so = shell_out("sysctl -n security.jail.jailed")
    if so.stdout.split($/)[0].to_i == 1
      virtualization[:system] = "jail"
      virtualization[:role] = "guest"
      virtualization[:systems][:jail] = "guest"
      Ohai::Log.debug("Plugin Virtualization: Guest running in FreeBSD jail detected")
    end

    # run jls to get a list of running jails
    # -n: name=value 1 line per jail format
    # -d: list the dying jails as well as active jails
    so = shell_out("jls -nd")
    if (so.stdout || "").lines.count >= 1
      virtualization[:system] = "jail"
      virtualization[:role] = "host"
      virtualization[:systems][:jail] = "host"
      Ohai::Log.debug("Plugin Virtualization: Host running FreeBSD jails detected")
    end

    # detect from modules
    so = shell_out("#{Ohai.abs_path('/sbin/kldstat')}")
    so.stdout.lines do |line|
      case line
      when /vboxdrv/
        virtualization[:system] = "vbox"
        virtualization[:role] = "host"
        virtualization[:systems][:vbox] = "host"
        Ohai::Log.debug("Plugin Virtualization: Guest running on VirtualBox detected")
      when /vboxguest/
        virtualization[:system] = "vbox"
        virtualization[:role] = "guest"
        virtualization[:systems][:vbox] = "guest"
        Ohai::Log.debug("Plugin Virtualization: Host running VirtualBox detected")
      end
    end

    # Detect bhyve by presence of /dev/vmm
    if File.exist?("/dev/vmm")
      virtualization[:system] = "bhyve"
      virtualization[:role] = "host"
      virtualization[:systems][:bhyve] = "host"
      Ohai::Log.debug("Plugin Virtualization: Host running bhyve detected")
    end

    # Detect KVM/QEMU paravirt guests from cpu, report as KVM
    # hw.model: QEMU Virtual CPU version 0.9.1
    so = shell_out("sysctl -n hw.model")
    if so.stdout.split($/)[0] =~ /QEMU Virtual CPU|Common KVM processor|Common 32-bit KVM processor/
      virtualization[:system] = "kvm"
      virtualization[:role] = "guest"
      virtualization[:systems][:kvm] = "guest"
      Ohai::Log.debug("Plugin Virtualization: Guest running on KVM detected")
    end

    # gather hypervisor of guests from sysctl kern.vm_guest
    # there are a limited number of hypervisors detected here, BUT it doesn't
    # require dmidecode to be installed and dmidecode isn't in freebsd out of the box
    so = shell_out("sysctl -n kern.vm_guest")
    case so.stdout
    when /vmware/
      virtualization[:system] = "vmware"
      virtualization[:role] = "guest"
      virtualization[:systems][:vmware] = "guest"
      Ohai::Log.debug("Plugin Virtualization: Guest running on VMware detected")
    when /hv/
      virtualization[:system] = "hyperv"
      virtualization[:role] = "guest"
      virtualization[:systems][:hyperv] = "guest"
      Ohai::Log.debug("Plugin Virtualization: Guest running on Hyper-V detected")
    when /xen/
      virtualization[:system] = "xen"
      virtualization[:role] = "guest"
      virtualization[:systems][:xen] = "guest"
      Ohai::Log.debug("Plugin Virtualization: Guest running on Xen detected")
    when /bhyve/
      virtualization[:system] = "bhyve"
      virtualization[:role] = "guest"
      virtualization[:systems][:bhyve] = "guest"
      Ohai::Log.debug("Plugin Virtualization: Guest running on bhyve detected")
    end

    # parse dmidecode to discover various virtualization guests
    if File.exist?("/usr/local/sbin/dmidecode") || File.exist?("/usr/pkg/sbin/dmidecode")
      guest = guest_from_dmi(shell_out("dmidecode").stdout)
      if guest
        virtualization[:system] = guest
        virtualization[:role] = "guest"
        virtualization[:systems][guest.to_sym] = "guest"
        Ohai::Log.debug("Plugin Virtualization: Guest running on #{guest} detected")
      end
    end
  end
end
