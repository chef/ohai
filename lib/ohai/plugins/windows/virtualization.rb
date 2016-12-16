#
# Author:: Pavel Yudin (<pyudin@parallels.com>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2015 Pavel Yudin
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

Ohai.plugin(:Virtualization) do
  provides "virtualization"

  collect_data(:windows) do
    require "wmi-lite/wmi"

    virtualization Mash.new unless virtualization
    virtualization[:systems] = Mash.new unless virtualization[:systems]

    # Grab BIOS data from WMI to determine vendor information
    wmi = WmiLite::Wmi.new
    bios = wmi.instances_of("Win32_BIOS")

    case bios[0]["manufacturer"]
    when "innotek GmbH"
      virtualization[:system] = "vbox"
      virtualization[:role] = "guest"
      virtualization[:systems][:vbox] = "guest"
    when "Parallels Software International Inc."
      virtualization[:system] = "parallels"
      virtualization[:role] = "guest"
      virtualization[:systems][:parallels] = "guest"
    when "Bochs"
      virtualization[:system] = "kvm"
      virtualization[:role] = "guest"
      virtualization[:systems][:kvm] = "guest"
    when "American Megatrends Inc."
      if bios[0]["version"] =~ /VRTUAL -/
        virtualization[:system] = "hyper-v"
        virtualization[:role] = "guest"
        virtualization[:systems][:hyperv] = "guest"
      end
    when "Xen"
      virtualization[:system] = "xen"
      virtualization[:role] = "guest"
      virtualization[:systems][:xen] = "guest"
    when "Veertu"
      virtualization[:system] = "veertu"
      virtualization[:role] = "guest"
      virtualization[:systems][:veertu] = "guest"
    end

    # vmware fusion detection
    if bios[0]["serialnumber"] =~ /VMware/
      virtualization[:system] = "vmware"
      virtualization[:role] = "guest"
      virtualization[:systems][:vmware] = "guest"
    end
  end
end
