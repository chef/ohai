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

# all output lines should fall within one of these patterns
header_type_line = /^ID\s+SIZE\s+TYPE/
header_information_line = /^(\d+)\s+(\d+)\s+(\S+)\s+\(([^\)]+)\)/
header_type = /^SMB_TYPE_(\S+)$/
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
      if type = header_type.match(header_information[3])
        dmi_record[:type] = type[1].downcase
      else
        dmi_record[:type] = header_information[3].downcase
        Ohai::Log.warn("unrecognized header type pattern; falling back to #{dmi_record[:type]}")
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
