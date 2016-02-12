#
# Author:: Joshua Timberman <joshua@chef.io>
# Author:: Isa Farnik (<isa@chef.io>)
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

  collect_data(:aix) do
    memory Mash.new
    memory[:swap] = Mash.new

    meminfo = shell_out("svmon -G -O unit=MB,summary=longreal | grep '[0-9]'").stdout
    total_in_mb, u, free_in_mb = meminfo.split
    memory[:total] = "#{total_in_mb.to_i * 1024}kB"
    memory[:free] = "#{free_in_mb.to_i * 1024}kB"

    swapinfo = shell_out("swap -s").stdout.split #returns swap info in 4K blocks
    memory[:swap]["total"] = "#{(swapinfo[2].to_i) * 4}kB"
    memory[:swap]["free"] = "#{(swapinfo[10].to_i) * 4}kB"
  end
end
