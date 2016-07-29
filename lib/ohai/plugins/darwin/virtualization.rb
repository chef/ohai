#
# Author:: Pavel Yudin (<pyudin@parallels.com>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2015 Pavel Yudin
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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
    ::File.exist?("/Applications/VMware\ Fusion.app/")
  end

  collect_data(:darwin) do
    virtualization Mash.new unless virtualization
    virtualization[:systems] = Mash.new unless virtualization[:systems]

    if vboxmanage_exists?
      virtualization[:system] = "vbox"
      virtualization[:role] = "host"
      virtualization[:systems][:vbox] = "host"
    end

    if fusion_exists?
      virtualization[:system] = "vmware"
      virtualization[:role] = "host"
      virtualization[:systems][:vmware] = "host"
    end

    if prlctl_exists?
      virtualization[:system] = "parallels"
      virtualization[:role] = "host"
      virtualization[:systems][:parallels] = "host"
    elsif ioreg_exists?
      so = shell_out("ioreg -l")
      if so.stdout =~ /pci1ab8,4000/
        virtualization[:system] = "parallels"
        virtualization[:role] = "guest"
        virtualization[:systems][:parallels] = "guest"
      end
    end
  end
end
