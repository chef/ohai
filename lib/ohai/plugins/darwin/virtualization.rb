# frozen_string_literal: true
#
# Author:: Pavel Yudin (<pyudin@parallels.com>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2015 Pavel Yudin
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
  depends "hardware"

  def vboxmanage_exists?
    which("VBoxManage")
  end

  def prlctl_exists?
    which("prlctl")
  end

  def ioreg_exists?
    which("ioreg")
  end

  def fusion_exists?
    file_exist?("/Applications/VMware\ Fusion.app/")
  end

  def docker_exists?
    which("docker")
  end

  collect_data(:darwin) do
    virtualization Mash.new unless virtualization
    virtualization[:systems] ||= Mash.new

    if docker_exists?
      virtualization[:system] = "docker"
      virtualization[:role] = "host"
      virtualization[:systems][:docker] = "host"
    end

    if vboxmanage_exists?
      virtualization[:system] = "vbox"
      virtualization[:role] = "host"
      virtualization[:systems][:vbox] = "host"
    end

    if hardware[:boot_rom_version].match?(/VirtualBox/i)
      virtualization[:system] = "vbox"
      virtualization[:role] = "guest"
      virtualization[:systems][:vbox] = "guest"
    end

    if fusion_exists?
      virtualization[:system] = "vmware"
      virtualization[:role] = "host"
      virtualization[:systems][:vmware] = "host"
    end

    if hardware[:boot_rom_version].match?(/VMW/i)
      virtualization[:system] = "vmware"
      virtualization[:role] = "guest"
      virtualization[:systems][:vmware] = "guest"
    end

    if ioreg_exists? && shell_out("ioreg -l").stdout.include?("pci1ab8,4000")
      virtualization[:system] = "parallels"
      virtualization[:role] = "guest"
      virtualization[:systems][:parallels] = "guest"
    elsif prlctl_exists?
      virtualization[:system] = "parallels"
      virtualization[:role] = "host"
      virtualization[:systems][:parallels] = "host"
    end
  end
end