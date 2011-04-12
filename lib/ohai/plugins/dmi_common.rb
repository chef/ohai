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

module DMI
  # List of IDs and what they translate to
  # from 'man 8 dmidecode'
  # all-lowercase, all non-alphanumeric converted to '_'
  # 128-255 are 'oem_data_[id]'
  # Everything else is 'unknown'
  IdToDescription = {
    0 =>   'bios',
    1 =>   'system',
    2 =>   'base_board',
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

  # list of IDs to collect, otherwise we generate pages of hashes about cache chip size and whatnot
  # See OHAI-260. When we can give the user a choice, this will be a default.
  IdToCapture = [ 0, 1, 2, 3, 4, 6, 11 ]

  # look up DMI ID
  def DMI.id_lookup(id)
    begin
      id = id.to_i
      if (id >= 128) and (id <= 255)
        id = "oem_data_#{id}"
      elsif DMI::IdToDescription.has_key?(id)
        id = DMI::IdToDescription[id]
      else
        Ohai::Log.debug("unrecognized header id; falling back to 'unknown'")
        id = 'unknown'
      end
    rescue
      Ohai::Log.debug("failed to look up id #{id}, returning unchanged")
      id
    end
  end

  # create simplified convenience access keys for each record type
  # for single occurrences of one type, copy to top level all fields and values
  # for multiple occurrences of same type, copy to top level all fields and values that are common to all records
  def DMI.convenience_keys(dmi)
    dmi.each{ |type, records|
      in_common = Mash.new
      next unless records.class.to_s == 'Mash'
      next unless records.has_key?('all_records')
      records[:all_records].each{ |record| 
        record.each{ |field, value| 
          next if value.class.to_s == 'Mash'
          next if field.to_s == 'application_identifier'
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
  end

end
