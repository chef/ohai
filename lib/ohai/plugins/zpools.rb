#
# Author:: Jason J. W. Williams (williamsjj@digitar.com)
# Copyright:: Copyright (c) 2011-2017 Chef Software, Inc.
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

Ohai.plugin(:Zpools) do
  provides "zpools"
  depends "platform_family"

  # If zpool status doesn't know about a field it returns '-'.
  # We don't want to fill a field with that
  def sanitize_value(value)
    value == "-" ? nil : value
  end

  def gather_pool_info
    pools = Mash.new
    begin
      # Grab ZFS zpools overall health and attributes
      so = shell_out("zpool list -H -o name,size,alloc,free,cap,dedup,health,version")
      so.stdout.lines do |line|
        case line
        when /^([-_0-9A-Za-z]*)\s+([.0-9]+[MGTPE])\s+([.0-9]+[MGTPE])\s+([.0-9]+[MGTPE])\s+(\d+%)\s+([.0-9]+x)\s+([-_0-9A-Za-z]+)\s+(\d+|-)$/
          Ohai::Log.debug("Plugin Zpools: Parsing zpool list line: #{line.chomp}")
          pools[$1] = Mash.new
          pools[$1][:pool_size] = sanitize_value($2)
          pools[$1][:pool_allocated] = sanitize_value($3)
          pools[$1][:pool_free] = sanitize_value($4)
          pools[$1][:capacity_used] = sanitize_value($5)
          pools[$1][:dedup_factor] = sanitize_value($6)
          pools[$1][:health] = sanitize_value($7)
          pools[$1][:zpool_version] = sanitize_value($8)
        end
      end

    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Plugin Zpools: Could not shell_out "zpool list -H -o name,size,alloc,free,cap,dedup,health,version". Skipping plugin.')
    end
    pools
  end

  collect_data(:solaris2, :linux, :freebsd, :openbsd, :netbsd, :dragonflybsd) do
    pools = gather_pool_info

    # Grab individual health for devices in the zpools
    pools.each_key do |pool|
      pools[pool][:devices] = Mash.new

      # Run "zpool status" as non-root user (adm) so that
      # the command won't try to open() each device which can
      # hang the command if any of the disks are bad.
      if platform_family == "solaris2"
        command = "su adm -c \"zpool status #{pool}\""
      else
        command = "zpool status #{pool}"
      end

      so = shell_out(command)
      so.stdout.lines do |line|
        case line
        # linux: http://rubular.com/r/J3wQC6E2lH
        # solaris: http://rubular.com/r/FqOBzUQQ4p
        # freebsd: http://rubular.com/r/RYkMNlytXl
        when /^\s+((sd|c|ad|da)[-_a-zA-Z0-9]+)\s+([-_a-zA-Z0-9]+)\s+(\d+)\s+(\d+)\s+(\d+)$/
          logger.trace("Plugin Zpools: Parsing zpool status line: #{line.chomp}")
          pools[pool][:devices][$1] = Mash.new
          pools[pool][:devices][$1][:state] = $3
          pools[pool][:devices][$1][:errors] = Mash.new
          pools[pool][:devices][$1][:errors][:read] = $4
          pools[pool][:devices][$1][:errors][:write] = $5
          pools[pool][:devices][$1][:errors][:checksum] = $6
        end
      end
    end

    # Set the zpools data
    zpools pools unless pools.empty?
  end
end
