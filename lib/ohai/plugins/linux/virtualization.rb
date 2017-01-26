#
# Author:: Thom May (<thom@clearairturbulence.org>)
# Copyright:: Copyright (c) 2009-2016 Chef Software, Inc.
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

  def lxc_version_exists?
    which("lxc-version")
  end

  def nova_exists?
    which("nova")
  end

  collect_data(:linux) do
    virtualization Mash.new unless virtualization
    virtualization[:systems] = Mash.new unless virtualization[:systems]

    ## Xen
    # /proc/xen is an empty dir for EL6 + Linode Guests + Paravirt EC2 instances
    if File.exist?("/proc/xen")
      virtualization[:system] = "xen"
      # Assume guest
      virtualization[:role] = "guest"
      virtualization[:systems][:xen] = "guest"

      # This file should exist on most Xen systems, normally empty for guests
      if File.exist?("/proc/xen/capabilities")
        if File.read("/proc/xen/capabilities") =~ /control_d/i
          Ohai::Log.debug("Plugin Virtualization: /proc/xen/capabilities contains control_d. Detecting as Xen host")
          virtualization[:role] = "host"
          virtualization[:systems][:xen] = "host"
        end
      end
    end

    # Xen Notes:
    # - cpuid of guests, if we could get it, would also be a clue
    # - may be able to determine if under paravirt from /dev/xen/evtchn (See OHAI-253)
    # - Additional edge cases likely should not change the above assumptions
    #   but rather be additive - btm

    # Detect Virtualbox from kernel module
    if File.exist?("/proc/modules")
      modules = File.read("/proc/modules")
      if modules =~ /^vboxdrv/
        Ohai::Log.debug("Plugin Virtualization: /proc/modules contains vboxdrv. Detecting as vbox host")
        virtualization[:system] = "vbox"
        virtualization[:role] = "host"
        virtualization[:systems][:vbox] = "host"
      elsif modules =~ /^vboxguest/
        Ohai::Log.debug("Plugin Virtualization: /proc/modules contains vboxguest. Detecting as vbox guest")
        virtualization[:system] = "vbox"
        virtualization[:role] = "guest"
        virtualization[:systems][:vbox] = "guest"
      end
    end

    # if nova binary is present we're on an openstack host
    if nova_exists?
      Ohai::Log.debug("Plugin Virtualization: nova command exists. Detecting as openstack host")
      virtualization[:system] = "openstack"
      virtualization[:role] = "host"
      virtualization[:systems][:openstack] = "host"
    end

    # Detect paravirt KVM/QEMU from cpuinfo, report as KVM
    if File.exist?("/proc/cpuinfo")
      if File.read("/proc/cpuinfo") =~ /QEMU Virtual CPU|Common KVM processor|Common 32-bit KVM processor/
        Ohai::Log.debug("Plugin Virtualization: /proc/cpuinfo lists a KVM paravirt CPU string. Detecting as kvm guest")
        virtualization[:system] = "kvm"
        virtualization[:role] = "guest"
        virtualization[:systems][:kvm] = "guest"
      end
    end

    # Detect KVM systems via /sys
    # guests will have the hypervisor cpu feature that hosts don't have
    if File.exist?("/sys/devices/virtual/misc/kvm")
      virtualization[:system] = "kvm"
      if File.read("/proc/cpuinfo") =~ /hypervisor/
        Ohai::Log.debug("Plugin Virtualization: /sys/devices/virtual/misc/kvm present and /proc/cpuinfo lists the hypervisor feature. Detecting as kvm guest")
        virtualization[:role] = "guest"
        virtualization[:systems][:kvm] = "guest"
      else
        Ohai::Log.debug("Plugin Virtualization: /sys/devices/virtual/misc/kvm present and /proc/cpuinfo does not list the hypervisor feature. Detecting as kvm host")
        virtualization[:role] = "host"
        virtualization[:systems][:kvm] = "host"
      end
    end

    # Detect OpenVZ / Virtuozzo.
    # http://wiki.openvz.org/BC_proc_entries
    if File.exist?("/proc/bc/0")
      Ohai::Log.debug("Plugin Virtualization: /proc/bc/0 exists. Detecting as openvz host")
      virtualization[:system] = "openvz"
      virtualization[:role] = "host"
      virtualization[:systems][:openvz] = "host"
    elsif File.exist?("/proc/vz")
      Ohai::Log.debug("Plugin Virtualization: /proc/vz exists. Detecting as openvz guest")
      virtualization[:system] = "openvz"
      virtualization[:role] = "guest"
      virtualization[:systems][:openvz] = "guest"
    end

    # Detect Parallels virtual machine from pci devices
    if File.exist?("/proc/bus/pci/devices")
      if File.read("/proc/bus/pci/devices") =~ /1ab84000/
        Ohai::Log.debug("Plugin Virtualization: /proc/bus/pci/devices contains '1ab84000' pci device. Detecting as parallels guest")
        virtualization[:system] = "parallels"
        virtualization[:role] = "guest"
        virtualization[:systems][:parallels] = "guest"
      end
    end

    # parse dmidecode to discover various virtualization guests
    if File.exist?("/usr/sbin/dmidecode")
      guest = guest_from_dmi(shell_out("dmidecode").stdout)
      if guest
        Ohai::Log.debug("Plugin Virtualization: dmidecode contains string indicating #{guest} guest")
        virtualization[:system] = guest
        virtualization[:role] = "guest"
        virtualization[:systems][guest.to_sym] = "guest"
      end
    end

    # Detect Linux-VServer
    if File.exist?("/proc/self/status")
      proc_self_status = File.read("/proc/self/status")
      vxid = proc_self_status.match(/^(s_context|VxID):\s*(\d+)$/)
      if vxid && vxid[2]
        virtualization[:system] = "linux-vserver"
        if vxid[2] == "0"
          Ohai::Log.debug("Plugin Virtualization: /proc/self/status contains 's_context' or 'VxID' with a value of 0. Detecting as linux-vserver host")
          virtualization[:role] = "host"
          virtualization[:systems]["linux-vserver"] = "host"
        else
          Ohai::Log.debug("Plugin Virtualization: /proc/self/status contains 's_context' or 'VxID' with a non-0 value. Detecting as linux-vserver guest")
          virtualization[:role] = "guest"
          virtualization[:systems]["linux-vserver"] = "guest"
        end
      end
    end

    # Detect LXC/Docker
    #
    # /proc/self/cgroup will look like this inside a docker container:
    # <index #>:<subsystem>:/lxc/<hexadecimal container id>
    #
    # /proc/self/cgroup could have a name including alpha/digit/dashes
    # <index #>:<subsystem>:/lxc/<named container id>
    #
    # /proc/self/cgroup could have a non-lxc cgroup name indicating other uses
    # of cgroups.  This is probably not LXC/Docker.
    # <index #>:<subsystem>:/Charlie
    #
    # A host which supports cgroups, and has capacity to host lxc containers,
    # will show the subsystems and root (/) namespace.
    # <index #>:<subsystem>:/
    #
    # Full notes, https://tickets.opscode.com/browse/OHAI-551
    # Kernel docs, https://www.kernel.org/doc/Documentation/cgroups
    if File.exist?("/proc/self/cgroup")
      cgroup_content = File.read("/proc/self/cgroup")
      if cgroup_content =~ %r{^\d+:[^:]+:/(lxc|docker)/.+$} ||
          cgroup_content =~ %r{^\d+:[^:]+:/[^/]+/(lxc|docker)-.+$}
        Ohai::Log.debug("Plugin Virtualization: /proc/self/cgroup indicates #{$1} container. Detecting as #{$1} guest")
        virtualization[:system] = $1
        virtualization[:role] = "guest"
        virtualization[:systems][$1.to_sym] = "guest"
      elsif lxc_version_exists? && File.read("/proc/self/cgroup") =~ %r{\d:[^:]+:/$}
        # lxc-version shouldn't be installed by default
        # Even so, it is likely we are on an LXC capable host that is not being used as such
        # So we're cautious here to not overwrite other existing values (OHAI-573)
        unless virtualization[:system] && virtualization[:role]
          Ohai::Log.debug("Plugin Virtualization: /proc/self/cgroup and lxc-version command exist. Detecting as lxc host")
          virtualization[:system] = "lxc"
          virtualization[:role] = "host"
        end
        # In general, the 'systems' framework from OHAI-182 is less susceptible to conflicts
        # But, this could overwrite virtualization[:systems][:lxc] = "guest"
        # If so, we may need to look further for a differentiator (OHAI-573)
        virtualization[:systems][:lxc] = "host"
      end
    elsif File.exist?("/.dockerenv") || File.exist?("/.dockerinit")
      Ohai::Log.debug("Plugin Virtualization: .dockerenv or .dockerinit exist. Detecting as docker guest")
      virtualization[:system] = "docker"
      virtualization[:role] = "guest"
      virtualization[:systems][:docker] = "guest"
    end

    # Detect LXD
    # See https://github.com/lxc/lxd/blob/master/doc/dev-lxd.md
    if File.exist?("/dev/lxd/sock")
      Ohai::Log.debug("Plugin Virtualization: /dev/lxd/sock exists. Detecting as lxd guest")
      virtualization[:system] = "lxd"
      virtualization[:role] = "guest"
    elsif File.exist?("/var/lib/lxd/devlxd")
      Ohai::Log.debug("Plugin Virtualization: /var/lib/lxd/devlxd exists. Detecting as lxd host")
      virtualization[:system] = "lxd"
      virtualization[:role] = "host"
    end
  end
end
