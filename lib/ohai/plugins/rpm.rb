# frozen_string_literal: true

#
# Author:: Davide Cavalca <dcavalca@fb.com>
# Copyright:: Copyright (c) 2021 Meta Platforms, Inc. and affiliates.
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

Ohai.plugin(:Rpm) do
  provides "rpm"
  optional "true"

  MACROS_MARKER = /========================/.freeze

  DO_NOT_SPLIT = %w{
    build_arch
    build_os
    install_arch
    install_os
    archcolor
    optflags
  }.freeze

  collect_data(:aix, :darwin, :dragonflybsd, :freebsd, :linux, :netbsd, :openbsd, :solaris2) do
    rpm_path = which("rpm")
    if rpm_path
      rpm_version_out = shell_out("#{rpm_path} --version")
      rpm_showrc_out = shell_out("#{rpm_path} --showrc")

      rpm Mash.new unless rpm
      rpm[:macros] ||= Mash.new

      m = rpm_version_out.stdout.match(/\w+ (\d.*)/)
      if m
        rpm[:version] = m[1]
      end

      lines = rpm_showrc_out.stdout.split("\n")
      # there's a marker to separate the beginning and end of the macros list
      macros_start_idx = lines.index { |x| x.match(MACROS_MARKER) }
      macros_end_idx = lines.rindex { |x| x.match(MACROS_MARKER) }
      section = nil
      lines[0..macros_start_idx - 1].each do |line|
        if line.start_with?("ARCHITECTURE AND OS")
          section = :arch_os
          rpm[section] ||= Mash.new
        elsif line.start_with?("RPMRC VALUES")
          section = :rpmrc
          rpm[section] ||= Mash.new
        elsif line.start_with?("Features supported by rpmlib")
          section = :features
          rpm[section] ||= Mash.new
        elsif line.start_with?("Macro path")
          fields = line.split(":", 2)
          if fields
            rpm[:macro_path] = fields[1].strip.split(":")
          end
          section = nil
        elsif %i{arch_os rpmrc}.include?(section)
          fields = line.split(":")
          if fields && fields[0] && fields[1]
            key = fields[0].strip.sub("'s", "es").tr(" ", "_")
            if DO_NOT_SPLIT.include?(key)
              values = fields[1].strip
            else
              values = fields[1].strip.split(" ")
            end
            rpm[section][key] = values
          end
        elsif section == :features
          fields = line.split("=")
          if fields && fields[0] && fields[1]
            rpm[section][fields[0].strip] = fields[1].strip
          end
        end
      end

      name = nil
      value = ""
      lines[macros_start_idx + 1..macros_end_idx - 1].each do |line|
        if line.start_with?("-")
          if name
            rpm[:macros][name] = value
            name = nil
            value = ""
          else
            _prefix, name, value = line.split(" ", 3)
          end
        else
          value += "\n#{line}"
        end
      end
    else
      logger.trace("Plugin RPM: Could not find rpm. Skipping plugin.")
    end
  end
end
