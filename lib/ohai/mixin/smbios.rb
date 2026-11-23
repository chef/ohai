# frozen_string_literal: true
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright (c) 2026 Tim Smith
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

module Ohai
  module Mixin
    #
    # Reads individual SMBIOS (DMI) strings the way each OS exposes them to
    # an unprivileged user, so cloud plugins can identify their platform
    # without root and without dmidecode installed:
    #
    # - Linux: /sys/class/dmi/id (most files are world-readable; product_uuid
    #   and product_serial are root-only and return nil otherwise)
    # - FreeBSD / DragonFly: kenv smbios.*
    # - OpenBSD: sysctl hw.*
    # - NetBSD: sysctl machdep.dmi.*
    # - Solaris / illumos: smbios -t <type>
    # - Windows: WMI
    #
    # Plugins that include this must also have the file and shell_out helpers
    # every Ohai plugin has.
    #
    module Smbios
      # field => where each platform keeps it. A missing entry means the
      # platform doesn't expose that field.
      SMBIOS_FIELDS ||= {
        sys_vendor: {
          linux: "sys_vendor", kenv: "smbios.system.maker", openbsd: "hw.vendor",
          netbsd: "machdep.dmi.system-vendor", wmi: %w{Win32_ComputerSystemProduct vendor},
          solaris: %w{SMB_TYPE_SYSTEM Manufacturer}
        },
        product_name: {
          linux: "product_name", kenv: "smbios.system.product", openbsd: "hw.product",
          netbsd: "machdep.dmi.system-product", wmi: %w{Win32_ComputerSystemProduct name},
          solaris: %w{SMB_TYPE_SYSTEM Product}
        },
        product_uuid: {
          linux: "product_uuid", kenv: "smbios.system.uuid", openbsd: "hw.uuid",
          netbsd: "machdep.dmi.system-uuid", wmi: %w{Win32_ComputerSystemProduct uuid},
          solaris: %w{SMB_TYPE_SYSTEM UUID}
        },
        product_serial: {
          linux: "product_serial", kenv: "smbios.system.serial", openbsd: "hw.serialno",
          netbsd: "machdep.dmi.system-serial", wmi: %w{Win32_BIOS serialnumber},
          solaris: ["SMB_TYPE_SYSTEM", "Serial Number"]
        },
        bios_vendor: {
          linux: "bios_vendor", kenv: "smbios.bios.vendor",
          netbsd: "machdep.dmi.bios-vendor", wmi: %w{Win32_BIOS manufacturer},
          solaris: %w{SMB_TYPE_BIOS Vendor}
        },
        bios_version: {
          linux: "bios_version", kenv: "smbios.bios.version",
          netbsd: "machdep.dmi.bios-version", wmi: %w{Win32_BIOS smbiosbiosversion},
          solaris: ["SMB_TYPE_BIOS", "Version String"]
        },
        board_asset_tag: {
          linux: "board_asset_tag", kenv: "smbios.planar.tag", netbsd: "machdep.dmi.board-asset-tag",
          solaris: ["SMB_TYPE_BASEBOARD", "Asset Tag"]
        },
        chassis_asset_tag: {
          linux: "chassis_asset_tag", kenv: "smbios.chassis.tag",
          netbsd: "machdep.dmi.chassis-asset-tag", wmi: %w{Win32_SystemEnclosure smbiosassettag},
          solaris: ["SMB_TYPE_CHASSIS", "Asset Tag"]
        },
      }.freeze

      # @param field [Symbol] a key of SMBIOS_FIELDS
      #
      # @return [String, nil] the stripped value, or nil when the platform
      #   doesn't expose it, it can't be read, or it is empty
      def smbios_value(field)
        @smbios_values ||= {}
        return @smbios_values[field] if @smbios_values.key?(field)

        sources = SMBIOS_FIELDS.fetch(field)
        value = begin
                  read_smbios_value(sources)
                rescue => e
                  logger.trace("Mixin Smbios: unable to read #{field}: #{e.class}: #{e.message}")
                  nil
                end
        value = value.to_s.strip
        @smbios_values[field] = value.empty? ? nil : value
      end

      private

      def read_smbios_value(sources)
        case RUBY_PLATFORM
        when /mswin|mingw|windows/
          read_smbios_wmi(*sources[:wmi]) if sources[:wmi]
        when /freebsd|dragonfly/
          read_smbios_command("kenv -q #{sources[:kenv]}") if sources[:kenv]
        when /openbsd/
          read_smbios_command("sysctl -n #{sources[:openbsd]}") if sources[:openbsd]
        when /netbsd/
          read_smbios_command("sysctl -n #{sources[:netbsd]}") if sources[:netbsd]
        when /solaris/
          read_smbios_solaris(*sources[:solaris]) if sources[:solaris]
        else
          path = "/sys/class/dmi/id/#{sources[:linux]}"
          file_read(path) if sources[:linux] && file_exist?(path)
        end
      end

      def read_smbios_command(cmd)
        so = shell_out(cmd)
        so.stdout if so.exitstatus == 0
      end

      # smbios(8) prints each structure of a type as indented "Label: value"
      # lines. Several fields share a type, so each type is read only once.
      def read_smbios_solaris(type, label)
        @smbios_solaris_output ||= {}
        output = (@smbios_solaris_output[type] ||= read_smbios_command("smbios -t #{type}").to_s)
        output[/^\s+#{Regexp.escape(label)}: (.*)$/, 1]
      end

      def read_smbios_wmi(wmi_class, property)
        require "wmi-lite/wmi" unless defined?(WmiLite::Wmi)
        instance = WmiLite::Wmi.new.first_of(wmi_class)
        instance && instance[property]
      end
    end
  end
end
