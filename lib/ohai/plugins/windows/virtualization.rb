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
  require "ohai/mixin/dmi_decode"
  include Ohai::Mixin::DmiDecode

  collect_data(:windows) do
    
    virtualization Mash.new unless virtualization
    virtualization[:systems] = Mash.new unless virtualization[:systems]

    # Grab system DMI data from WMI to determine vendor information

    dmi_results = shell_out('Get-WmiObject "Win32_ComputerSystemProduct" | ForEach-Object { Write-Host "$($_.Vendor),$($_.Name),$($_.Version)" }').stdout.strip
    dmi_vendor, dmi_name, dmi_version = dmi_results.split(',',3)
    
    guest = guest_from_dmi_data(dmi_vendor, dmi_name, dmi_version)
    if guest
      logger.trace("Plugin Virtualization: DMI data in Win32_ComputerSystemProduct indicates #{guest} guest")
      virtualization[:system] = guest
      virtualization[:role] = "guest"
      virtualization[:systems][guest.to_sym] = "guest"
    end
  end
end
