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

provides "dmi"

# dmidecode does not return data without access to /dev/mem (or its equivalent)

dmi Mash.new

# List of IDs and what they translate to
# from 'man 8 dmidecode'
id_to_description= {
  0 =>   'bios',
  1 =>   'system',
  2 =>   'baseboard',
  3 =>   'chassis',
  4 =>   'processor',
  5 =>   'memory_controller',
  6 =>   'memory_module',
  7 =>   'cache',
  8 =>   'port_connector',
  9 =>   'system_slots',
  10 =>  'on_board_devices',
  11 =>  'oem_strings',
  12 =>  'system_configuration_options',
  13 =>  'bios_language',
  14 =>  'group_associations',
  15 =>  'system_event_log',
  16 =>  'physical_memory_array',
  17 =>  'memory_device',
  18 =>  '32_bit_memory_error',
  19 =>  'memory_array_mapped_address',
  20 =>  'memory_device_mapped_address',
  21 =>  'built_in_pointing_device',
  22 =>  'portable_battery',
  23 =>  'system_reset',
  24 =>  'hardware_security',
  25 =>  'system_power_controls',
  26 =>  'voltage_probe',
  27 =>  'cooling_device',
  28 =>  'temperature_probe',
  29 =>  'electrical_current_probe',
  30 =>  'out_of_band_remote_access',
  31 =>  'boot_integrity_services',
  32 =>  'system_boot',
  33 =>  '64_bit_memory_error',
  34 =>  'management_device',
  35 =>  'management_device_component',
  36 =>  'management_device_threshold_data',
  37 =>  'memory_channel',
  38 =>  'ipmi_device',
  39 =>  'power_supply',
  126 => 'disabled_entries',
  127 => 'end_of_table_marker',
}
# 128-255 are 'OEM Data'
# Everything else is unknown

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
      dmi_record = {:type => handle[2]}

      # look up DMI ID
      if (dmi_record[:type].to_i >= 128) and (dmi_record[:type].to_i <= 255)
        dmi_record[:type] = "oem_#{dmi_record[:type]}"
      elsif id_to_description.has_key?(dmi_record[:type].to_i)
        dmi_record[:type] = id_to_description[dmi_record[:type].to_i]
      else
        dmi_record[:type] = 'unknown'
        Ohai::Log.warn("unrecognized header id; falling back to 'unknown'")
      end

      dmi[dmi_record[:type]] = Mash.new unless dmi.has_key?(dmi_record[:type])
      dmi[dmi_record[:type]][:all_records] = [] unless dmi[dmi_record[:type]].has_key?(:all_records)
      dmi_record[:position] = dmi[dmi_record[:type]][:all_records].length
      dmi[dmi_record[:type]][:all_records].push(Mash.new)
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][:record_id] = handle[1]
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][:size] = handle[2]
      field = nil
    
    elsif type = type_line.match(line)
      if dmi_record == nil
        Ohai::Log.warn("unexpected data line found before header; discarding:\n#{line}")
        next
      end
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][:os_identifier] = type[1]

    elsif data = data_line.match(line)
      if dmi_record == nil
        Ohai::Log.warn("unexpected data line found before header; discarding:\n#{line}")
        next
      end
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][data[1]] = data[2]
      field = data[1]
    
    elsif extended_data = extended_data_line.match(line)
      if dmi_record == nil
        Ohai::Log.warn("unexpected extended data line found before header; discarding:\n#{line}")
        next
      end
      if field == nil
        Ohai::Log.warn("unexpected extended data line found outside data section; discarding:\n#{line}")
        next
      end
      # overwrite "raw" value with a new Mash
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][field] = Mash.new unless dmi[dmi_record[:type]][:all_records][dmi_record[:position]][field].class.to_s == 'Mash'
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][field][extended_data[1]] = nil

    else
      Ohai::Log.warn("unrecognized output line; discarding:\n#{line}")

    end
  end
end

# create simplified convenience access keys for each record type
# for single occurrences of one type, copy to top level all fields and values
# for multiple occurrences of same type, copy to top level all fields and values that are common to all records
dmi.each{ |type, records|
  next unless records.class.to_s == 'Mash'
  next unless records.has_key?(:all_records)
  in_common = Mash.new
  records[:all_records].each{ |record| 
    record.each{ |field, value| 
      next if value.class.to_s == 'Mash'
      next if field.to_s == 'os_identifier'
      next if field.to_s == 'size'
      next if field.to_s == 'record_id'
      translated = field.downcase.gsub(/[^a-z0-9]/, '_')
      if in_common.has_key?(translated)
        in_common[translated] = nil unless in_common[translated] == value
      else
        in_common[translated] = value
      end
    }
  }
  in_common.each{ |field, value|
    next if value == nil
    dmi[type][field] = value
  }
}
