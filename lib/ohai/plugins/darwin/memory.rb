#
# Author:: Patrick Collins (<pat@burned.com>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

Ohai.plugin(:Memory) do
  provides "memory"

  collect_data(:darwin) do
    memory Mash.new

    installed_memory = shell_out("sysctl -n hw.memsize").stdout.to_i / 1024 / 1024.0
    memory[:total] = "#{installed_memory.to_i}MB"

    total_consumed = 0
    active = 0
    inactive = 0
    vm_stat = shell_out("vm_stat").stdout
    vm_stat_match = /page size of (\d+) bytes/.match(vm_stat)
    page_size = if vm_stat_match && vm_stat_match[1]
                  vm_stat_match[1].to_i
                else
                  4096
                end

    vm_stat.split("\n").each do |line|
      ["wired down", "active", "inactive"].each do |match|
        unless line.index("Pages #{match}:").nil?
          pages = line.split.last.to_i
          megabyte_val = (pages * page_size) / 1024 / 1024.0
          total_consumed += megabyte_val
          case match
          when "wired down"
            active += megabyte_val.to_i
          when "active"
            active += megabyte_val.to_i
          when "inactive"
            inactive += megabyte_val.to_i
          end
        end
      end
    end

    memory[:active] = "#{active}MB" if active > 0
    memory[:inactive] = "#{inactive}MB" if inactive > 0

    free_memory = installed_memory - total_consumed
    memory[:free] = "#{free_memory.to_i}MB" if total_consumed > 0
  end
end
