#
# Author:: Deepali Jagtap (<deepali.jagtap@clogeny.com>)
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Ohai.plugin(:Filesystem) do
  provides "filesystem"

  collect_data(:aix) do
    fs = Mash.new

    # Grab filesystem data from df
    so = shell_out("df -P")
    so.stdout.lines.each do |line|
      case line
      when /^Filesystem\s+1024-blocks/
        next
      when /^(.+?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+\%)\s+(.+)$/
        filesystem = $1
        fs[filesystem] = Mash.new
        fs[filesystem][:kb_size] = $2
        fs[filesystem][:kb_used] = $3
        fs[filesystem][:kb_available] = $4
        fs[filesystem][:percent_used] = $5
        fs[filesystem][:mount] = $6
      end
    end

    # Grab mount information from /bin/mount
    so = shell_out("mount")
    so.stdout.lines.each do |line|
      case line
      when /^\s*node/
        next
      when /^\s*---/
        next
      when /^\s*\/\w/
        fields = line.split
        filesystem = fields[0]
        fs[filesystem] = Mash.new unless fs.has_key?(filesystem)
        fs[filesystem][:mount] = fields[1]
        fs[filesystem][:fs_type] = fields[2]
        fs[filesystem][:mount_options] = fields[6]
      else
        fields = line.split
        filesystem = fields[0] + ":" + fields[1]
        fs[filesystem] = Mash.new unless fs.has_key?(filesystem)
        fs[filesystem][:mount] = fields[2]
        fs[filesystem][:fs_type] = fields[3]
        fs[filesystem][:mount_options] = fields[7]
      end
    end

    # Set the filesystem data
    filesystem fs
  end
end
