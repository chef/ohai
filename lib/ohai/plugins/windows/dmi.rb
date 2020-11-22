# frozen_string_literal: true
#
# Author:: Pete Higgins (pete@peterhiggins.org)
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

Ohai.plugin(:DMI) do
  provides "dmi"

  # Map the linux component types to their rough Windows API equivalents
  DMI_TO_WIN32OLE ||= {
    chassis: "SystemEnclosure",
    processor: "Processor",
    bios: "Bios",
    system: "ComputerSystemProduct",
    base_board: "BaseBoard",
  }.freeze

  # This regex is in 3 parts for the different supported patterns in camel
  # case names coming from the Windows API:
  # * Typical camelcase, eg Depth, PartNumber, NumberOfPowerCords
  # * Acronyms preceding camelcase, eg SMBIOSAssetTag
  # * Acronyms that occur at the end of the name, eg SKU, DeviceID
  #
  # This cannot handle some property names, eg SMBIOSBIOSVersion.
  # https://rubular.com/r/FBNtXod4wkZGAG
  SPLIT_REGEX ||= /[A-Z][a-z0-9]+|[A-Z]{2,}(?=[A-Z][a-z0-9])|[A-Z]{2,}/.freeze

  WINDOWS_TO_UNIX_KEYS ||= [
    %w{vendor manufacturer},
    %w{identifying_number serial_number},
    %w{name family},
  ].freeze

  collect_data(:windows) do
    require_relative "../../common/dmi"
    require "wmi-lite/wmi" unless defined?(WmiLite::Wmi)
    wmi = WmiLite::Wmi.new

    dmi Mash.new

    # The Windows API returns property names in camel case, eg "SerialNumber",
    # while `dmi` returns them as space separated strings, eg "Serial Number".
    # `Ohai::Common::DMI.convenience_keys` expects property names in `dmi`'s
    # format, so build two parallel hashes with the keys as they come from the
    # Windows API and in a faked-out `dmi` version. After the call to
    # `Ohai::Common::DMI.convenience_keys` replace the faked-out `dmi`
    # collection with the one with the original property names.
    DMI_TO_WIN32OLE.each do |dmi_key, ole_key|
      wmi_objects = wmi.instances_of("Win32_#{ole_key}").map(&:wmi_ole_object)

      split_name_properties = []
      properties = []

      wmi_objects.each do |wmi_object|
        split_name_properties << Mash.new
        properties << Mash.new

        wmi_object.properties_.each do |property|
          property_name = property.name
          value = wmi_object.invoke(property_name)

          split_name = property_name.scan(SPLIT_REGEX).join(" ")
          split_name_properties.last[split_name] = value
          properties.last[property_name] = value
        end
      end

      dmi[dmi_key] = Mash.new(all_records: split_name_properties, _all_records: properties)
    end

    Ohai::Common::DMI.convenience_keys(dmi)

    dmi.each_value do |records|
      records[:all_records] = records.delete(:_all_records)

      WINDOWS_TO_UNIX_KEYS.each do |windows_key, unix_key|
        records[unix_key] = records.delete(windows_key) if records.key?(windows_key)
      end
    end
  end
end
