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

require 'ohai/util/file_helper'

include Ohai::Util::FileHelper

Ohai.plugin(:Virtualization) do
  provides "virtualization"

  def lxc_version_exists?
    which('lxc-version')
  end

  def docker_exists?
    which('docker')
  end

  collect_data(:linux) do
    virtualization Mash.new unless virtualization
    virtualization[:systems] = Mash.new unless virtualization[:systems]

    # if it is possible to detect paravirt vs hardware virt, it should be put in
    # virtualization[:mechanism]

    ## Xen
    # /proc/xen is an empty dir for EL6 + Linode Guests
    if File.exists?("/proc/xen")
      virtualization[:system] = "xen"
      # Assume guest
      virtualization[:role] = "guest"
      virtualization[:systems][:xen] = "guest"

      # This file should exist on most Xen systems, normally empty for guests
      if File.exists?("/proc/xen/capabilities")
        if File.read("/proc/xen/capabilities") =~ /control_d/i
          virtualization[:role] = "host"
          virtualization[:systems][:xen] = "host"
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
        virtualization[:systems][:kvm] = "host"
      elsif modules =~ /^vboxdrv/
        virtualization[:system] = "vbox"
        virtualization[:role] = "host"
        virtualization[:systems][:vbox] = "host"
      elsif modules =~ /^vboxguest/
        virtualization[:system] = "vbox"
        virtualization[:role] = "guest"
        virtualization[:systems][:vbox] = "guest"
      end
    end

    # Detect KVM/QEMU from cpuinfo, report as KVM
    # We could pick KVM from 'Booting paravirtualized kernel on KVM' in dmesg
    # 2.6.27-9-server (intrepid) has this / 2.6.18-6-amd64 (etch) does not
    # It would be great if we could read pv_info in the kernel
    # Wait for reply to: http://article.gmane.org/gmane.comp.emulators.kvm.devel/27885
    if File.exists?("/proc/cpuinfo")
      if File.read("/proc/cpuinfo") =~ /QEMU Virtual CPU|Common KVM processor|Common 32-bit KVM processor/
        virtualization[:system] = "kvm"
        virtualization[:role] = "guest"
        virtualization[:systems][:kvm] = "guest"
      end
    end

    # Detect OpenVZ / Virtuozzo.
    # http://wiki.openvz.org/BC_proc_entries
    if File.exists?("/proc/bc/0")
      virtualization[:system] = "openvz"
      virtualization[:role] = "host"
      virtualization[:systems][:openvz] = "host"
    elsif File.exists?("/proc/vz")
      virtualization[:system] = "openvz"
      virtualization[:role] = "guest"
      virtualization[:systems][:openvz] = "guest"
    end

    # http://www.dmo.ca/blog/detecting-virtualization-on-linux
    if File.exists?("/usr/sbin/dmidecode")
      so = shell_out("dmidecode")
      case so.stdout
      when /Manufacturer: Microsoft/
        if so.stdout =~ /Product Name: Virtual Machine/
          virtualization[:system] = "virtualpc"
          virtualization[:role] = "guest"
          virtualization[:systems][:virtualpc] = "guest"
        end
      when /Manufacturer: VMware/
        if so.stdout =~ /Product Name: VMware Virtual Platform/
          virtualization[:system] = "vmware"
          virtualization[:role] = "guest"
          virtualization[:systems][:vmware] = "guest"
        end
      when /Manufacturer: Xen/
        if so.stdout =~ /Product Name: HVM domU/
          virtualization[:system] = "xen"
          virtualization[:role] = "guest"
          virtualization[:systems][:xen] = "guest"
        end
      when /Manufacturer: Oracle Corporation/
        if so.stdout =~ /Product Name: VirtualBox/
          virtualization[:system] = "vbox"
          virtualization[:role] = "guest"
          virtualization[:systems][:vbox] = "guest"
        end
      when /Product Name: OpenStack/
        virtualization[:system] = "openstack"
        virtualization[:role] = "guest"
        virtualization[:systems][:openstack] = "guest"
      else
        nil
      end
    end

    # Detect Linux-VServer
    if File.exists?("/proc/self/status")
      proc_self_status = File.read("/proc/self/status")
      vxid = proc_self_status.match(/^(s_context|VxID):\s*(\d+)$/)
      if vxid and vxid[2]
        virtualization[:system] = "linux-vserver"
        if vxid[2] == "0"
          virtualization[:role] = "host"
          virtualization[:systems]["linux-vserver"] = "host"
        else
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
    if File.exists?("/proc/self/cgroup")
      if File.read("/proc/self/cgroup") =~ %r{^\d+:[^:]+:/(lxc|docker)/.+$}
        virtualization[:system] = $1
        virtualization[:role] = "guest"
        virtualization[:systems][$1.to_sym] = "guest"
      elsif lxc_version_exists? && File.read("/proc/self/cgroup") =~ %r{\d:[^:]+:/$}
        # lxc-version shouldn't be installed by default
        # Even so, it is likely we are on an LXC capable host that is not being used as such
        # So we're cautious here to not overwrite other existing values (OHAI-573)
        unless virtualization[:system] && virtualization[:role]
          virtualization[:system] = "lxc"
          virtualization[:role] = "host"
        end
        # In general, the 'systems' framework from OHAI-182 is less susceptible to conflicts
        # But, this could overwrite virtualization[:systems][:lxc] = "guest"
        # If so, we may need to look further for a differentiator (OHAI-573)
        virtualization[:systems][:lxc] = "host"
      end
    elsif File.exists?("/.dockerenv") || File.exists?("/.dockerinit")
        virtualization[:system] = "docker"
        virtualization[:role] = "guest"
        virtualization[:systems][:docker] = "guest"
    end
  end
end
