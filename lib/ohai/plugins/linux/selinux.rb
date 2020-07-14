# frozen_string_literal: true
#
# Author:: Davide Cavalca <dcavalca@fb.com>
# Copyright:: Copyright (c) 2020 Facebook
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

Ohai.plugin(:Selinux) do
  provides "selinux/status", "selinux/policy_booleans", "selinux/process_contexts", "selinux/file_contexts"
  optional true

  collect_data(:linux) do
    sestatus_path = which("sestatus")
    if sestatus_path
      sestatus = shell_out("#{sestatus_path} -v -b")

      selinux Mash.new unless selinux
      selinux[:status] ||= Mash.new
      selinux[:policy_booleans] ||= Mash.new
      selinux[:process_contexts] ||= Mash.new
      selinux[:file_contexts] ||= Mash.new
      section = nil

      sestatus.stdout.split("\n").each do |line|
        line.chomp!

        case line
        when "Policy booleans:"
          section = :policy_booleans
          next
        when "Process contexts:"
          section = :process_contexts
          next
        when "File contexts:"
          section = :file_contexts
          next
        else
          if section.nil?
            section = :status
          end
        end

        key, val = line.split(/:?\s\s+/, 2)
        next if key.nil?

        unless key.start_with?("/")
          key.downcase!
          key.tr!(" ", "_")
        end

        selinux[section][key] = val
      end
    else
      logger.debug("Plugin Selinux: Could not find sestatus. Skipping plugin.")
    end
  end
end
