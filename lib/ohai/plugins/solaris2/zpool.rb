#
# Author:: Jason J. W. Williams (williamsjj@digitar.com)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

provides "zpool"

pool = Mash.new

# Grab ZFS zpool information from 'zpool'
popen4("zpool list -H -o name,size,alloc,free,cap,dedup,health,version") do |pid, stdin, stdout, stderr|
  stdin.close
  stdout.each do |line|
    case line
    when /^([-_0-9A-Za-z]*)\s+([.0-9]+[MGTPE])\s+([.0-9]+[MGTPE])\s+([.0-9]+[MGTPE])\s+(\d+%)\s+([.0-9]+x)\s+([-_0-9A-Za-z]+)\s+(\d+)$/
      pool[$1] = Mash.new
      pool[$1][:pool_size] = $2
      pool[$1][:pool_allocated] = $3
      pool[$1][:pool_free] = $4
      pool[$1][:capacity_used] = $5
      pool[$1][:dedup_factor] = $6
      pool[$1][:health] = $7
      pool[$1][:zpool_version] = $8
    end
  end
end

# Set the zpool data
zpool pool