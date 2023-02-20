# frozen_string_literal: true
#
# Author:: Thom May (<thom@clearairturbulence.org>)
# Copyright:: Copyright (c) Chef Software Inc.
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
  depends "dmi"
  depends "cpu"
  require_relative "../../mixin/dmi_decode"
  include Ohai::Mixin::DmiDecode

  def lxc_version_exists?
    which("lxc-version") || which("lxc-start")
  end

  def nova_exists?
    which("nova")
  end

  def docker_exists?
    which("docker")
  end

  def podman_exists?
    which("podman")
  end

  collect_data(:linux) do
    virtualization Mash.new unless virtualization
    virtualization[:systems] ||= Mash.new

    # Docker hosts
    if docker_exists?
      virtualization[:system] = "docker"
      virtualization[:role] = "host"
      virtualization[:systems][:docker] = "host"
    end

    # Podman hosts
    if podman_exists?
      virtualization[:system] = "podman"
      virtualization[:role] = "host"
      virtualization[:systems][:podman] = "host"
    end

    # Xen Notes:
    # - /proc/xen is an empty dir for EL6 + Linode Guests + Paravirt EC2 instances
    # - cpuid of guests, if we could get it, would also be a clue
    # - may be able to determine if under paravirt from /dev/xen/evtchn (See OHAI-253)
    # - Additional edge cases likely should not change the above assumptions
    #   but rather be additive - btm
    if file_exist?("/proc/xen")
      virtualization[:system] = "xen"
      # Assume guest
      virtualization[:role] = "guest"
      virtualization[:systems][:xen] = "guest"

      # This file should exist on most Xen systems, normally empty for guests
      if file_exist?("/proc/xen/capabilities")
        if /control_d/i.match?(file_read("/proc/xen/capabilities"))
          logger.trace("Plugin Virtualization: /proc/xen/capabilities contains control_d. Detecting as Xen host")
          virtualization[:role] = "host"
          virtualization[:systems][:xen] = "host"
        end
      end
    end

    # Detect Virtualbox from kernel module
    if file_exist?("/proc/modules")
      modules = file_read("/proc/modules")
      if /^vboxdrv/.match?(modules)
        logger.trace("Plugin Virtualization: /proc/modules contains vboxdrv. Detecting as vbox host")
        virtualization[:system] = "vbox"
        virtualization[:role] = "host"
        virtualization[:systems][:vbox] = "host"
      elsif /^vboxguest/.match?(modules)
        logger.trace("Plugin Virtualization: /proc/modules contains vboxguest. Detecting as vbox guest")
        virtualization[:system] = "vbox"
        virtualization[:role] = "guest"
        virtualization[:systems][:vbox] = "guest"
      end
    end

    # if nova binary is present we're on an openstack host
    if nova_exists?
      logger.trace("Plugin Virtualization: nova command exists. Detecting as openstack host")
      virtualization[:system] = "openstack"
      virtualization[:role] = "host"
      virtualization[:systems][:openstack] = "host"
    end

    # Detect paravirt KVM/QEMU from cpuinfo, report as KVM
    if file_exist?("/proc/cpuinfo")
      if /QEMU Virtual CPU|Common KVM processor|Common 32-bit KVM processor/.match?(file_read("/proc/cpuinfo"))
        logger.trace("Plugin Virtualization: /proc/cpuinfo lists a KVM paravirt CPU string. Detecting as kvm guest")
        virtualization[:system] = "kvm"
        virtualization[:role] = "guest"
        virtualization[:systems][:kvm] = "guest"
      end
    end

    # Detect KVM systems via /sys
    # guests will have the hypervisor cpu feature that hosts don't have
    if file_exist?("/sys/devices/virtual/misc/kvm")
      virtualization[:system] = "kvm"
      if file_read("/proc/cpuinfo").include?("hypervisor")
        logger.trace("Plugin Virtualization: /sys/devices/virtual/misc/kvm present and /proc/cpuinfo lists the hypervisor feature. Detecting as kvm guest")
        virtualization[:role] = "guest"
        virtualization[:systems][:kvm] = "guest"
      else
        logger.trace("Plugin Virtualization: /sys/devices/virtual/misc/kvm present and /proc/cpuinfo does not list the hypervisor feature. Detecting as kvm host")
        virtualization[:role] = "host"
        virtualization[:systems][:kvm] = "host"
      end
    elsif get_attribute(:cpu, :hypervisor_vendor)
      if get_attribute(:cpu, :hypervisor_vendor) == "KVM"
        virtualization[:system] = "kvm"
        if /(para|full)/.match?(get_attribute(:cpu, :virtualization_type))
          virtualization[:role] = "guest"
          virtualization[:systems][:kvm] = "guest"
        end
      end
    end

    # parse dmi to discover various virtualization guests
    # we do this *after* the kvm detection so that OpenStack isn't detected as KVM
    logger.trace("Looking up DMI data manufacturer: '#{get_attribute(:dmi, :system, :manufacturer)}' product_name: '#{get_attribute(:dmi, :system, :product_name)}' version: '#{get_attribute(:dmi, :system, :version)}'")
    guest = guest_from_dmi_data(get_attribute(:dmi, :system, :manufacturer), get_attribute(:dmi, :system, :product_name), get_attribute(:dmi, :system, :version))
    if guest
      logger.trace("Plugin Virtualization: DMI data indicates #{guest} guest")
      virtualization[:system] = guest
      virtualization[:role] = "guest"
      virtualization[:systems][guest.to_sym] = "guest"
    end

    # Detect OpenVZ / Virtuozzo.
    # http://wiki.openvz.org/BC_proc_entries
    if file_exist?("/proc/bc/0")
      logger.trace("Plugin Virtualization: /proc/bc/0 exists. Detecting as openvz host")
      virtualization[:system] = "openvz"
      virtualization[:role] = "host"
      virtualization[:systems][:openvz] = "host"
    elsif file_exist?("/proc/vz")
      logger.trace("Plugin Virtualization: /proc/vz exists. Detecting as openvz guest")
      virtualization[:system] = "openvz"
      virtualization[:role] = "guest"
      virtualization[:systems][:openvz] = "guest"
    end

    # Detect Hyper-V guest and the hostname of the host
    if file_exist?("/var/lib/hyperv/.kvp_pool_3")
      logger.trace("Plugin Virtualization: /var/lib/hyperv/.kvp_pool_3 contains string indicating Hyper-V guest")
      data = file_read("/var/lib/hyperv/.kvp_pool_3")
      hyperv_host = data[/\HostName(.*?)HostingSystemEditionId/, 1].scan(/[[:print:]]/).join.downcase
      virtualization[:system] = "hyperv"
      virtualization[:role] = "guest"
      virtualization[:systems][:hyperv] = "guest"
      virtualization[:hypervisor_host] = hyperv_host
    end

    # Detect Linux-VServer
    if file_exist?("/proc/self/status")
      proc_self_status = file_read("/proc/self/status")
      vxid = proc_self_status.match(/^(s_context|VxID):\s*(\d+)$/)
      if vxid && vxid[2]
        virtualization[:system] = "linux-vserver"
        if vxid[2] == "0"
          logger.trace("Plugin Virtualization: /proc/self/status contains 's_context' or 'VxID' with a value of 0. Detecting as linux-vserver host")
          virtualization[:role] = "host"
          virtualization[:systems]["linux-vserver"] = "host"
        else
          logger.trace("Plugin Virtualization: /proc/self/status contains 's_context' or 'VxID' with a non-0 value. Detecting as linux-vserver guest")
          virtualization[:role] = "guest"
          virtualization[:systems]["linux-vserver"] = "guest"
        end
      end
    end

    # Detect LXC/Docker/Nspawn
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
    # Kernel docs, https://web.archive.org/web/20100514070914/http://www.kernel.org/doc/Documentation/cgroups/
    if file_exist?("/proc/self/cgroup")
      cgroup_content = file_read("/proc/self/cgroup")
      # These two REs catch many different examples. Here's a specific one
      # from when it is docker and there is no subsystem name.
      # https://rubular.com/r/dV13hiU9KxmiWB
      if cgroup_content =~ %r{^\d+:[^:]*:/(lxc|docker)/.+$} ||
          cgroup_content =~ %r{^\d+:[^:]*:/[^/]+/(lxc|docker)-?.+$}
        logger.trace("Plugin Virtualization: /proc/self/cgroup indicates #{$1} container. Detecting as #{$1} guest")
        virtualization[:system] = $1
        virtualization[:role] = "guest"
        virtualization[:systems][$1.to_sym] = "guest"
      elsif file_read("/proc/1/environ").include?("container=lxc")
        logger.trace("Plugin Virtualization: /proc/1/environ indicates lxc container. Detecting as lxc guest")
        virtualization[:system] = "lxc"
        virtualization[:role] = "guest"
        virtualization[:systems][:lxc] = "guest"
      elsif file_read("/proc/1/environ").include?("container=systemd-nspawn")
        logger.trace("Plugin Virtualization: /proc/1/environ indicates nspawn container. Detecting as nspawn guest")
        virtualization[:system] = "nspawn"
        virtualization[:role] = "guest"
        virtualization[:systems][:nspawn] = "guest"
      elsif file_read("/proc/1/environ").include?("container=podman")
        logger.trace("Plugin Virtualization: /proc/1/environ indicates podman container. Detecting as podman guest")
        virtualization[:system] = "podman"
        virtualization[:role] = "guest"
        virtualization[:systems][:podman] = "guest"
      # Detect any containers that appear to be using docker such as those running on Github Actions virtual machines
      # but aren't triggered by the cgroup regex above. It's pretty safe to assume if the cgroup contains containerd,
      # it's likely using docker.
      # https://rubular.com/r/qhSmV113cPmEBT
      elsif %r{^\d+:[^:]*:/[^/]+/(containerd)-?.+$}.match?(cgroup_content)
        logger.trace("Plugin Virtualization: /proc/self/cgroup indicates docker container. Detecting as docker guest")
        virtualization[:system] = "docker"
        virtualization[:role] = "guest"
        virtualization[:systems][:docker] = "guest"
      elsif lxc_version_exists? && file_read("/proc/self/cgroup") =~ %r{\d:[^:]+:/$}
        # lxc-version shouldn't be installed by default
        # Even so, it is likely we are on an LXC capable host that is not being used as such
        # So we're cautious here to not overwrite other existing values (OHAI-573)
        unless virtualization[:system] && virtualization[:role]
          logger.trace("Plugin Virtualization: /proc/self/cgroup and lxc-version command exist. Detecting as lxc host")
          virtualization[:system] = "lxc"
          virtualization[:role] = "host"
          virtualization[:systems][:lxc] = "host"
        end
        # In general, the 'systems' framework from OHAI-182 is less susceptible to conflicts
        # But, this could overwrite virtualization[:systems][:lxc] = "guest"
        # If so, we may need to look further for a differentiator (OHAI-573)
        virtualization[:systems][:lxc] = "host"
      end
    end

    # regardless of what we found above, if we're a docker container inside
    # of the above, lets report as a docker container
    if file_exist?("/.dockerenv") || file_exist?("/.dockerinit")
      logger.trace("Plugin Virtualization: .dockerenv or .dockerinit exist. Detecting as docker guest")
      virtualization[:system] = "docker"
      virtualization[:role] = "guest"
      virtualization[:systems][:docker] = "guest"
    end

    # Detect LXD
    # See https://github.com/lxc/lxd/blob/master/doc/dev-lxd.md
    if file_exist?("/dev/lxd/sock")
      logger.trace("Plugin Virtualization: /dev/lxd/sock exists. Detecting as lxd guest")
      virtualization[:system] = "lxd"
      virtualization[:role] = "guest"
      virtualization[:systems][:lxd] = "guest"
    else
      # 'How' LXD is installed dictates the runtime data location
      #
      # Installations of LXD from a .deb (Ubuntu's main and backports repos) utilize '/var/lib/lxd/' for runtime data
      #   - used by stable releases 2.0.x in trusty/xenial, and 3.0.x in bionic
      #   - xenial-backports includes versions 2.1 through 2.21
      #
      # Snap based installations utilize '/var/snap/lxd/common/lxd/'
      #   - includes all future releases starting with 2.21, and will be the only source of 3.1+ feature releases post-bionic
      ["/var/lib/lxd/devlxd", "/var/snap/lxd/common/lxd/devlxd"].each do |devlxd|
        if file_exist?(devlxd)
          logger.trace("Plugin Virtualization: #{devlxd} exists. Detecting as lxd host")
          virtualization[:system] = "lxd"
          virtualization[:role] = "host"
          virtualization[:systems][:lxd] = "host"
          break
        end
      end
    end
  end
end
