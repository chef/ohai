#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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

Ohai.plugin(:Filesystem) do
  provides "filesystem"

  collect_data(:freebsd, :openbsd, :netbsd, :dragonflybsd) do
    fs = Mash.new

    # Grab filesystem data from df
    so = shell_out("df")
    so.stdout.lines do |line|
      case line
      when /^Filesystem/
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

    # inode parsing from 'df -iP'
    so = shell_out("df -iP")
    so.stdout.lines do |line|
      case line
      when /^Filesystem/ # skip the header
        next
      when /^(.+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\%\s+(\d+)\s+(\d+)\s+(\d+)%(.+)$/
        filesystem = $1.strip
        fs[filesystem] ||= Mash.new
        fs[filesystem][:inodes_used] = $6
        fs[filesystem][:inodes_available] = $7
        fs[filesystem][:total_inodes] = ($6.to_i + $7.to_i).to_s
        fs[filesystem][:inodes_percent_used] = $8
        fs[filesystem][:mount] = $9.strip
      end
    end

    # Grab mount information from mount
    so = shell_out("mount -l")
    so.stdout.lines do |line|
      if line =~ /^(.+?) on (.+?) \((.+?), (.+?)\)$/
        filesystem = $1
        fs[filesystem] = Mash.new unless fs.has_key?(filesystem)
        fs[filesystem][:mount] = $2
        fs[filesystem][:fs_type] = $3
        fs[filesystem][:mount_options] = $4.split(/,\s*/)
      end
    end

    # Set the filesystem data
    filesystem fs
  end
end
