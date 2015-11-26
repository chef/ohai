#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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
  provides 'virtualization'

  collect_data(:freebsd, :openbsd, :netbsd, :dragonflybsd) do
    virtualization Mash.new

    so = shell_out("sysctl -n security.jail.jailed")
    if so.stdout.split($/)[0].to_i == 1
      virtualization[:system] = "jail"
      virtualization[:role] = "guest"
    end

    # detect from modules
    so = shell_out("#{Ohai.abs_path('/sbin/kldstat')}")
    so.stdout.lines do |line|
      case line
      when /vboxdrv/
        virtualization[:system] = 'vbox'
        virtualization[:role] = 'host'
      when /vboxguest/
        virtualization[:system] = 'vbox'
        virtualization[:role] = 'guest'
      end
    end

    # XXX doesn't work when jail is there but not running (ezjail-admin stop)
    so = shell_out('jls -n')
    if (so.stdout || '').lines.count >= 1
      virtualization[:system] = 'jail'
      virtualization[:role] = 'host'
    end

    # KVM Host support for FreeBSD is in development
    # http://feanor.sssup.it/~fabio/freebsd/lkvm/

    # Detect KVM/QEMU from cpu, report as KVM
    # hw.model: QEMU Virtual CPU version 0.9.1
    so = shell_out('sysctl -n hw.model')
    if so.stdout.split($INPUT_RECORD_SEPARATOR)[0] =~ /QEMU Virtual CPU|Common KVM processor|Common 32-bit KVM processor/
      virtualization[:system] = 'kvm'
      virtualization[:role] = 'guest'
    end

    # http://www.dmo.ca/blog/detecting-virtualization-on-linux
    if File.exist?('/usr/local/sbin/dmidecode') || File.exist?('/usr/pkg/sbin/dmidecode')
      so = shell_out('dmidecode')
      case so.stdout
      when /Manufacturer: Microsoft/
        if so.stdout =~ /Product Name: Virtual Machine/
          if so.stdout =~ /Version: VS2005R2/
            virtualization[:system] = 'virtualserver'
            virtualization[:role] = 'guest'
          else
            virtualization[:system] = 'virtualpc'
            virtualization[:role] = 'guest'
            virtualization[:systems][:virtualpc] = 'guest'
          end
        end
      when /Manufacturer: VMware/
        if so.stdout =~ /Product Name: VMware Virtual Platform/
          virtualization[:system] = 'vmware'
          virtualization[:role] = 'guest'
          virtualization[:systems][:vmware] = 'guest'
        end
      when /Manufacturer: Xen/
        if so.stdout =~ /Product Name: HVM domU/
          virtualization[:system] = 'xen'
          virtualization[:role] = 'guest'
          virtualization[:systems][:xen] = 'guest'
        end
      when /Manufacturer: Oracle Corporation/
        if so.stdout =~ /Product Name: VirtualBox/
          virtualization[:system] = 'vbox'
          virtualization[:role] = 'guest'
          virtualization[:systems][:vbox] = 'guest'
        end
      when /Product Name: OpenStack/
        virtualization[:system] = 'openstack'
        virtualization[:role] = 'guest'
        virtualization[:systems][:openstack] = 'guest'
      when /Manufacturer: QEMU|Product Name: (KVM|RHEV)/
        virtualization[:system] = 'kvm'
        virtualization[:role] = 'guest'
        virtualization[:systems][:kvm] = 'guest'
      end
    end
  end
end
