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

require 'ohai/mixin/dmi_decode'

include Ohai::Mixin::DmiDecode

Ohai.plugin(:Virtualization) do
  provides 'virtualization'

  collect_data(:freebsd, :openbsd, :netbsd, :dragonflybsd) do

    virtualization Mash.new unless virtualization
    virtualization[:systems] = Mash.new unless virtualization[:systems]

    # detect when in a jail or when a jail is actively running (not in stopped state)
    so = shell_out("sysctl -n security.jail.jailed")
    if so.stdout.split($/)[0].to_i == 1
      virtualization[:system] = "jail"
      virtualization[:role] = "guest"
      virtualization[:systems][:jail] = 'guest'
    end

    so = shell_out('jls -n')
    if (so.stdout || '').lines.count >= 1
      virtualization[:system] = 'jail'
      virtualization[:role] = 'host'
      virtualization[:systems][:jail] = 'host'
    end

    # detect from modules
    so = shell_out("#{Ohai.abs_path('/sbin/kldstat')}")
    so.stdout.lines do |line|
      case line
      when /vboxdrv/
        virtualization[:system] = 'vbox'
        virtualization[:role] = 'host'
        virtualization[:systems][:vbox] = 'host'
      when /vboxguest/
        virtualization[:system] = 'vbox'
        virtualization[:role] = 'guest'
        virtualization[:systems][:vbox] = 'guest'
      end
    end

    # Detect KVM/QEMU from cpu, report as KVM
    # hw.model: QEMU Virtual CPU version 0.9.1
    so = shell_out('sysctl -n hw.model')
    if so.stdout.split($/)[0] =~ /QEMU Virtual CPU|Common KVM processor|Common 32-bit KVM processor/
      virtualization[:system] = 'kvm'
      virtualization[:role] = 'guest'
      virtualization[:systems][:kvm] = 'guest'
    end

    # parse dmidecode to discover various virtualization guests
    if File.exist?('/usr/local/sbin/dmidecode') || File.exist?('/usr/pkg/sbin/dmidecode')
      guest = determine_guest(shell_out('dmidecode').stdout)
      if guest
        virtualization[:system] = guest
        virtualization[:role] = 'guest'
        virtualization[:systems][guest.to_sym] = 'guest'
      end
    end
  end
end
