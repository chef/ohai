# frozen_string_literal: true
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

Ohai.plugin(:DMI) do
  provides "dmi"

  # dmidecode does not return data without access to /dev/mem (or its equivalent)

  # /sys/class/dmi/id file => [record type, convenience key]. The kernel
  # exports these strings to any user, except the serial numbers and the
  # UUID, which are root-only.
  def dmi_sysfs_fields
    {
      "bios_vendor" => %w{bios vendor},
      "bios_version" => %w{bios version},
      "bios_date" => %w{bios release_date},
      "sys_vendor" => %w{system manufacturer},
      "product_name" => %w{system product_name},
      "product_version" => %w{system version},
      "product_serial" => %w{system serial_number},
      "product_uuid" => %w{system uuid},
      "product_sku" => %w{system sku_number},
      "product_family" => %w{system family},
      "board_vendor" => %w{base_board manufacturer},
      "board_name" => %w{base_board product_name},
      "board_version" => %w{base_board version},
      "board_serial" => %w{base_board serial_number},
      "board_asset_tag" => %w{base_board asset_tag},
      "chassis_vendor" => %w{chassis manufacturer},
      "chassis_version" => %w{chassis version},
      "chassis_serial" => %w{chassis serial_number},
      "chassis_asset_tag" => %w{chassis asset_tag},
    }
  end

  # When dmidecode isn't installed, or can't read the tables because it
  # isn't running as root, fill the main records' convenience keys from
  # sysfs. There are no all_records then: sysfs only has these strings.
  def collect_dmi_from_sysfs
    return if dmi.keys.intersect?(%w{bios system base_board chassis})

    dmi_sysfs_fields.each do |file, (type, key)|
      path = "/sys/class/dmi/id/#{file}"
      next unless file_exist?(path)

      value = begin
                file_read(path).strip
              rescue SystemCallError
                nil # root-only
              end
      next if value.nil? || value.empty?

      dmi[type] ||= Mash.new
      dmi[type][key] = value
    end
  end

  collect_data do
    require_relative "../common/dmi"
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

    begin
      so = shell_out("dmidecode")
      # ==== EXAMPLE RECORD: ====
      # Handle 0x0000, DMI type 0, 24 bytes
      # BIOS Information
      #        Vendor: American Megatrends Inc.
      #        Version: 080012
      # ... similar lines trimmed
      #        Characteristics:
      #                ISA is supported
      #                PCI is supported
      # ... similar lines trimmed
      so.stdout.lines do |line|
        next if blank_line.match(line)

        line = line.encode(line.encoding, universal_newline: true)

        if ( dmidecode_version = dmidecode_version_line.match(line) )
          dmi[:dmidecode_version] = dmidecode_version[1]

        elsif ( smbios_version = smbios_version_line.match(line) )
          dmi[:smbios_version] = smbios_version[1]

        elsif ( structures = structures_line.match(line) )
          dmi[:structures] = Mash.new
          dmi[:structures][:count] = structures[1]
          dmi[:structures][:size] = structures[2]

        elsif ( table_location = table_location_line.match(line) )
          dmi[:table_location] = table_location[1]

        elsif ( handle = handle_line.match(line) )
          unless Ohai::Common::DMI.allowlisted_ids.include?(handle[2].to_i)
            dmi_record = nil
            next
          end

          dmi_record = { type: Ohai::Common::DMI.id_lookup(handle[2]) }

          dmi[dmi_record[:type]] ||= Mash.new
          dmi[dmi_record[:type]][:all_records] ||= []
          dmi_record[:position] = dmi[dmi_record[:type]][:all_records].length
          dmi[dmi_record[:type]][:all_records].push(Mash.new)
          dmi[dmi_record[:type]][:all_records][dmi_record[:position]][:record_id] = handle[1]
          dmi[dmi_record[:type]][:all_records][dmi_record[:position]][:size] = handle[2]
          field = nil

        elsif ( type = type_line.match(line) )
          if dmi_record.nil?
            logger.trace("Plugin DMI: unexpected data line found before header; discarding:\n#{line}")
            next
          end
          dmi[dmi_record[:type]][:all_records][dmi_record[:position]][:application_identifier] = type[1]

        elsif ( data = data_line.match(line) )
          if dmi_record.nil?
            logger.trace("Plugin DMI: unexpected data line found before header; discarding:\n#{line}")
            next
          end
          dmi[dmi_record[:type]][:all_records][dmi_record[:position]][data[1]] = data[2]
          field = data[1]

        elsif ( extended_data = extended_data_line.match(line) )
          if dmi_record.nil?
            logger.trace("Plugin DMI: unexpected extended data line found before header; discarding:\n#{line}")
            next
          end
          if field.nil?
            logger.trace("Plugin DMI: unexpected extended data line found outside data section; discarding:\n#{line}")
            next
          end
          # overwrite "raw" value with a new Mash
          dmi[dmi_record[:type]][:all_records][dmi_record[:position]][field] = Mash.new unless dmi[dmi_record[:type]][:all_records][dmi_record[:position]][field].class.to_s == "Mash"
          dmi[dmi_record[:type]][:all_records][dmi_record[:position]][field][extended_data[1]] = nil

        else
          logger.trace("Plugin DMI: unrecognized output line; discarding:\n#{line}")

        end
      end

      Ohai::Common::DMI.convenience_keys(dmi)
    rescue Ohai::Exceptions::Exec
      logger.trace('Plugin DMI: Could not shell_out "dmidecode". Skipping data')
    end

    collect_dmi_from_sysfs
  end
end
