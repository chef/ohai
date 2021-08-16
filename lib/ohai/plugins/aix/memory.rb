# frozen_string_literal: true
#
# Author:: Joshua Timberman <joshua@chef.io>
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

  collect_data(:aix) do
    memory Mash.new
    memory[:swap] = Mash.new

    meminfo = shell_out("svmon -G -O unit=KB,summary=longreal | grep '[0-9]'").stdout
    total_in_mb, _u, free_in_mb = meminfo.split
    memory[:total] = "#{total_in_mb.to_i}kB"
    memory[:free] = "#{free_in_mb.to_i}kB"

    swap_info = shell_out("swap -s").stdout.split # returns swap info in 4K blocks
    memory[:swap]["total"] = "#{swap_info[2].to_i * 4}kB"
    memory[:swap]["free"] = "#{swap_info[10].to_i * 4}kB"
  end
end
