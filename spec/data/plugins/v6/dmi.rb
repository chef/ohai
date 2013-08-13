#
# Author:: Kurt Yoder (ktyopscode@yoderhome.com)
# Copyright:: Copyright (c) 2010 Kurt Yoder
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

require "ohai/plugins/dmi_common"

provides "dmi"

# dmidecode does not return data without access to /dev/mem (or its equivalent)

dmi Mash.new

# all output lines should fall within one of these patterns
handle_line = /^Handle (0x[0-9A-F]{4}), DMI type (\d+), (\d+) bytes/
type_line = /^([A-Z][a-zA-Z ]+)( Information)?/
blank_line = /^\s*$/
data_line = /^\t([^:]+):(?: (.*))?/
extended_data_line = /^\t\t(.+)/
# first lines may contain some interesting information:
# # dmidecode 2.10
# SMBIOS 2.5 present.
# 5 structures occupying 352 bytes.
# Table at 0x000E1000.
dmidecode_version_line = /^# dmidecode (\d+\.\d+)/
smbios_version_line = /^SMBIOS (\d+\.\d+) present\./
structures_line = /^(\d+) structures occupying (\d+) bytes\./
table_location_line = /^Table at (0x[0-9A-E]+)\./

dmi_record = nil
field = nil

popen4("dmidecode") do |pid, stdin, stdout, stderr|
  stdin.close
  
  # ==== EXAMPLE RECORD: ====
  #Handle 0x0000, DMI type 0, 24 bytes
  #BIOS Information
  #        Vendor: American Megatrends Inc.
  #        Version: 080012 
  # ... similar lines trimmed
  #        Characteristics:
  #                ISA is supported
  #                PCI is supported
  # ... similar lines trimmed
  stdout.each do |line|
    next if blank_line.match(line)

    if dmidecode_version = dmidecode_version_line.match(line)
      dmi[:dmidecode_version] = dmidecode_version[1]

    elsif smbios_version = smbios_version_line.match(line)
      dmi[:smbios_version] = smbios_version[1]

    elsif structures = structures_line.match(line)
      dmi[:structures] = Mash.new
      dmi[:structures][:count] = structures[1]
      dmi[:structures][:size] = structures[2]

    elsif table_location = table_location_line.match(line)
      dmi[:table_location] = table_location[1]

    elsif handle = handle_line.match(line)
      # Don't overcapture for now (OHAI-260)
      next unless DMI::IdToCapture.include?(handle[2].to_i)

      dmi_record = {:type => DMI.id_lookup(handle[2])}

      dmi[dmi_record[:type]] = Mash.new unless dmi.has_key?(dmi_record[:type])
      dmi[dmi_record[:type]][:all_records] = [] unless dmi[dmi_record[:type]].has_key?(:all_records)
      dmi_record[:position] = dmi[dmi_record[:type]][:all_records].length
      dmi[dmi_record[:type]][:all_records].push(Mash.new)
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][:record_id] = handle[1]
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][:size] = handle[2]
      field = nil
    
    elsif type = type_line.match(line)
      if dmi_record == nil
        Ohai::Log.debug("unexpected data line found before header; discarding:\n#{line}")
        next
      end
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][:application_identifier] = type[1]

    elsif data = data_line.match(line)
      if dmi_record == nil
        Ohai::Log.debug("unexpected data line found before header; discarding:\n#{line}")
        next
      end
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][data[1]] = data[2]
      field = data[1]
    
    elsif extended_data = extended_data_line.match(line)
      if dmi_record == nil
        Ohai::Log.debug("unexpected extended data line found before header; discarding:\n#{line}")
        next
      end
      if field == nil
        Ohai::Log.debug("unexpected extended data line found outside data section; discarding:\n#{line}")
        next
      end
      # overwrite "raw" value with a new Mash
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][field] = Mash.new unless dmi[dmi_record[:type]][:all_records][dmi_record[:position]][field].class.to_s == 'Mash'
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][field][extended_data[1]] = nil

    else
      Ohai::Log.debug("unrecognized output line; discarding:\n#{line}")

    end
  end
end

DMI.convenience_keys(dmi)
