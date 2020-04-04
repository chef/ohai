#
# Author:: Pete Higgins (pete@peterhiggins.org)
# Copyright:: Copyright (c) 2020 Kurt Yoder
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

=begin
Here are the 5 sections of node['dmi'] that are returned on my Ubuntu workstation, and what I believe are the Win32 equivalents.

chassis: https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-systemenclosure
processor: https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-processor
bios: https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-bios
system: https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-computersystemproduct
base_board: https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-baseboard

I think these are the equivalents.

Note the first one is what is in the system_enclosure plugin today. We can copy that pattern into the dmi plugin and use it to pull all of the sections. The system_enclosure plugin should then be set for future deprecation.
=end

Ohai.plugin(:DMI) do
  provides "dmi"

  DMI_TO_WIN32OLE = {
    chassis: "SystemEnclosure",
    processor: "Processor",
    bios: "Bios",
    system: "ComputerSystemProduct",
    base_board: "BaseBoard",
  }

  collect_data(:windows) do
    require "wmi-lite/wmi"
    wmi = WmiLite::Wmi.new

    dmi Mash.new

    DMI_TO_WIN32OLE.each do |dmi_key, ole_key|
      properties = wmi.first_of("Win32_#{ole_key}").instance_variable_get("@property_map")

      dmi[dmi_key] = Mash.new(properties)
    end
  end
end
