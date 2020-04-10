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

Ohai.plugin(:DMI) do
  provides "dmi"

  DMI_TO_WIN32OLE = {
    chassis: "SystemEnclosure",
    processor: "Processor",
    bios: "Bios",
    system: "ComputerSystemProduct",
    base_board: "BaseBoard",
  }.freeze

  SPLIT_REGEX = /[A-Z][a-z0-9]+|[A-Z]{2,}(?=[A-Z][a-z0-9])|[A-Z]{2,}/.freeze

  collect_data(:windows) do
    require "ohai/common/dmi"
    require "wmi-lite/wmi"
    wmi = WmiLite::Wmi.new

    dmi Mash.new

    DMI_TO_WIN32OLE.each do |dmi_key, ole_key|
      wmi_object = wmi.first_of("Win32_#{ole_key}").wmi_ole_object

      split_name_properties = Mash.new
      properties = Mash.new

      wmi_object.properties_.each do |property|
        property_name = property.name
        value = wmi_object.invoke(property_name)

        split_name = property_name.scan(SPLIT_REGEX).join(" ")
        split_name_properties[split_name] = value
        properties[property_name] = value
      end

      dmi[dmi_key] = Mash.new(all_records: [split_name_properties], _all_records: [properties])
    end

    Ohai::Common::DMI.convenience_keys(dmi)

    dmi.each_value do |records|
      records[:all_records] = records.delete(:_all_records)
    end
  end
end
