#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

provides "filesystem"

require 'timeout'

fs = Mash.new

# Grab filesystem data from df
begin
  timeout(30){
    popen4("df -P") do |pid, stdin, stdout, stderr|
          stdin.close
          stdout.each do |line|
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
        end
      }
    rescue "Timeout::Error"
      puts "Timed out executing df -P"
end


# Grab mount information from /bin/mount
popen4("mount -l") do |pid, stdin, stdout, stderr|
  stdin.close
  stdout.each do |line|
    if line =~ /^(.+?) on (.+?) type (.+?) \((.+?)\)$/
      filesystem = $1
      fs[filesystem] = Mash.new unless fs.has_key?(filesystem)
      fs[filesystem][:mount] = $2
      fs[filesystem][:fs_type] = $3
      fs[filesystem][:mount_options] = $4.split(",")
    end
  end
end

# Grab UUID from /dev/disk/by-uuid/*
popen4("ls -l /dev/disk/by-uuid/* | awk '{print $11, $9}'") do |pid, stdin, stdout, stderr|
  stdin.close
  stdout.each do |line|
    if line =~ /^[.\/]+\/([a-z]+\d) \/.\/(.)$/
      filesystem = "/dev/" + $1
      fs[filesystem] = Mash.new unless fs.has_key?(filesystem)
      fs[filesystem][:uuid] = $2
    end
  end
end

# Grab any missing mount information from /proc/mounts
File.open('/proc/mounts').read_nonblock(4096).each do |line|
  if line =~ /^(\S+) (\S+) (\S+) (\S+) \S+ \S+$/
    filesystem = $1
    next if fs.has_key?(filesystem)
    fs[filesystem] = Mash.new
    fs[filesystem][:mount] = $2
    fs[filesystem][:fs_type] = $3
    fs[filesystem][:mount_options] = $4.split(",")
  end
end

# Set the filesystem data
filesystem fs
