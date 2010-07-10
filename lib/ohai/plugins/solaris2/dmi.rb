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

# bad Solaris shows strings defined by system instead of SMB IDs 
# this is what the *real* IDs are:
# pulled from http://src.opensolaris.org/source/xref/nwam/nwam1/usr/src/uts/common/sys/smbios.h
smb_to_id = {
  'SMB_TYPE_BIOS' =>         0, # BIOS information (R)
  'SMB_TYPE_SYSTEM' =>       1, # system information (R)
  'SMB_TYPE_BASEBOARD' =>    2, # base board
  'SMB_TYPE_CHASSIS' =>      3, # system enclosure or chassis (R)
  'SMB_TYPE_PROCESSOR' =>    4, # processor (R)
  'SMB_TYPE_MEMCTL' =>       5, # memory controller (O)
  'SMB_TYPE_MEMMOD' =>       6, # memory module (O)
  'SMB_TYPE_CACHE' =>        7, # processor cache (R)
  'SMB_TYPE_PORT' =>         8, # port connector
  'SMB_TYPE_SLOT' =>         9, # upgradeable system slot (R)
  'SMB_TYPE_OBDEVS' =>       10, # on-board devices
  'SMB_TYPE_OEMSTR' =>       11, # OEM string table
  'SMB_TYPE_SYSCONFSTR' =>   12, # system configuration string table
  'SMB_TYPE_LANG' =>         13, # BIOS language information
  'SMB_TYPE_GROUP' =>        14, # group associations
  'SMB_TYPE_EVENTLOG' =>     15, # system event log
  'SMB_TYPE_MEMARRAY' =>     16, # physical memory array (R)
  'SMB_TYPE_MEMDEVICE' =>    17, # memory device (R)
  'SMB_TYPE_MEMERR32' =>     18, # 32-bit memory error information
  'SMB_TYPE_MEMARRAYMAP' =>  19, # memory array mapped address (R)
  'SMB_TYPE_MEMDEVICEMAP' => 20, # memory device mapped address (R)
  'SMB_TYPE_POINTDEV' =>     21, # built-in pointing device
  'SMB_TYPE_BATTERY' =>      22, # portable battery
  'SMB_TYPE_RESET' =>        23, # system reset settings
  'SMB_TYPE_SECURITY' =>     24, # hardware security settings
  'SMB_TYPE_POWERCTL' =>     25, # system power controls
  'SMB_TYPE_VPROBE' =>       26, # voltage probe
  'SMB_TYPE_COOLDEV' =>      27, # cooling device
  'SMB_TYPE_TPROBE' =>       28, # temperature probe
  'SMB_TYPE_IPROBE' =>       29, # current probe
  'SMB_TYPE_OOBRA' =>        30, # out-of-band remote access facility
  'SMB_TYPE_BIS' =>          31, # boot integrity services
  'SMB_TYPE_BOOT' =>         32, # system boot status (R)
  'SMB_TYPE_MEMERR64' =>     33, # 64-bit memory error information
  'SMB_TYPE_MGMTDEV' =>      34, # management device
  'SMB_TYPE_MGMTDEVCP' =>    35, # management device component
  'SMB_TYPE_MGMTDEVDATA' =>  36, # management device threshold data
  'SMB_TYPE_MEMCHAN' =>      37, # memory channel
  'SMB_TYPE_IPMIDEV' =>      38, # IPMI device information
  'SMB_TYPE_POWERSUP' =>     39, # system power supply
  'SMB_TYPE_INACTIVE' =>     126, # inactive table entry
  'SMB_TYPE_EOT' =>          127, # end of table
  'SMB_TYPE_OEM_LO' =>       128, # start of OEM-specific type range
  'SUN_OEM_EXT_PROCESSOR' => 132, # processor extended info
  'SUN_OEM_PCIEXRC' =>       138, # PCIE RootComplex/RootPort info
  'SUN_OEM_EXT_MEMARRAY' =>  144, # phys memory array extended info
  'SUN_OEM_EXT_MEMDEVICE' => 145, # memory device extended info
  'SMB_TYPE_OEM_HI' =>       256, # end of OEM-specific type range
}

# all output lines should fall within one of these patterns
header_type_line = /^ID\s+SIZE\s+TYPE/
header_information_line = /^(\d+)\s+(\d+)\s+(\S+)\s+\(([^\)]+)\)/
blank_line = /^\s*$/
data_line = /^  ([^:]+): (.*)/
extended_data_line = /^\t(\S+) \((.+)\)/

dmi_record = nil
field = nil

popen4("smbios") do |pid, stdin, stdout, stderr|
  stdin.close
  
  # ==== EXAMPLE: ====
  # ID    SIZE TYPE
  # 0     40   SMB_TYPE_BIOS (BIOS information)
  # 
  #   Vendor: HP
  #   Version String: 2.16  
  # ... similar lines trimmed
  #   Characteristics: 0x7fc9da80
  #         SMB_BIOSFL_PCI (PCI is supported)
  # ... similar lines trimmed
  # note the second level of indentation is via a *tab*
  stdout.each do |line|
    next if header_type_line.match(line)
    next if blank_line.match(line)

    if header_information = header_information_line.match(line)
      dmi_record = {}

      # look up SMB ID
      if smb_to_id.has_key?(header_information[3])
        dmi_record[:type] = smb_to_id[header_information[3]]
  
        # look up DMI ID
        if (dmi_record[:type] >= 128) and (dmi_record[:type] <= 255)
          dmi_record[:type] = "oem_#{dmi_record[:type]}"
        elsif id_to_description.has_key?(dmi_record[:type])
          dmi_record[:type] = id_to_description[dmi_record[:type]]
        else
          dmi_record[:type] = 'unknown'
          Ohai::Log.warn("unrecognized header id; falling back to 'unknown'")
        end

      else
        dmi_record[:type] = header_information[3].downcase
        Ohai::Log.warn("unrecognized header type; falling back to #{dmi_record[:type]}")
      end

      dmi[dmi_record[:type]] = Mash.new unless dmi.has_key?(dmi_record[:type])
      dmi[dmi_record[:type]][:all_records] = [] unless dmi[dmi_record[:type]].has_key?(:all_records)
      dmi_record[:position] = dmi[dmi_record[:type]][:all_records].length
      dmi[dmi_record[:type]][:all_records].push(Mash.new)
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][:record_id] = header_information[1]
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][:size] = header_information[2]
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][:os_identifier] = header_information[4]
      field = nil
    
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
      dmi[dmi_record[:type]][:all_records][dmi_record[:position]][field][extended_data[1]] = extended_data[2]

    else
      Ohai::Log.warn("unrecognized output line; discarding:\n#{line}")

    end
  end
end

# create simplified convenience access keys for each record type
# for single occurrences of one type, copy to top level all fields and values
# for multiple occurrences of same type, copy to top level all fields and values that are common to all records
dmi.each{ |type, records|
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
