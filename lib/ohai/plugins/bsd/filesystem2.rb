#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Author:: Phil Dibowitz (<phil@ipom.com>)
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

Ohai.plugin(:Filesystem2) do
  provides "filesystem2"

  def generate_device_view(fs)
    view = {}
    fs.each_value do |entry|
      view[entry[:device]] = Mash.new unless view[entry[:device]]
      entry.each do |key, val|
        next if %w{device mount}.include?(key)
        view[entry[:device]][key] = val
      end
      view[entry[:device]][:mounts] ||= []
      if entry[:mount]
        view[entry[:device]][:mounts] << entry[:mount]
      end
    end
    view
  end

  def generate_mountpoint_view(fs)
    view = {}
    fs.each_value do |entry|
      next unless entry[:mount]
      view[entry[:mount]] = Mash.new unless view[entry[:mount]]
      entry.each do |key, val|
        next if %w{mount device}.include?(key)
        view[entry[:mount]][key] = val
      end
      view[entry[:mount]][:devices] ||= []
      if entry[:device]
        view[entry[:mount]][:devices] << entry[:device]
      end
    end
    view
  end

  collect_data(:freebsd, :openbsd, :netbsd, :dragonflybsd) do
    fs = Mash.new

    # Grab filesystem data from df
    so = shell_out("df")
    so.stdout.lines do |line|
      case line
      when /^Filesystem/
        next
      when /^(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+\%)\s+(\S+)$/
        key = "#{$1},#{$6}"
        fs[key] = Mash.new
        fs[key][:device] = $1
        fs[key][:kb_size] = $2
        fs[key][:kb_used] = $3
        fs[key][:kb_available] = $4
        fs[key][:percent_used] = $5
        fs[key][:mount] = $6
      end
    end

    # inode parsing from 'df -iP'
    so = shell_out("df -iP")
    so.stdout.lines do |line|
      case line
      when /^Filesystem/ # skip the header
        next
      when /^(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\%\s+(\d+)\s+(\d+)\s+(\d+)%\s+(\S+)$/
        key = "#{$1},#{$9}"
        fs[key] ||= Mash.new
        fs[key][:device] = $1
        fs[key][:inodes_used] = $6
        fs[key][:inodes_available] = $7
        fs[key][:total_inodes] = ($6.to_i + $7.to_i).to_s
        fs[key][:inodes_percent_used] = $8
        fs[key][:mount] = $9
      end
    end

    # Grab mount information from mount
    so = shell_out("mount -l")
    so.stdout.lines do |line|
      if line =~ /^(.+?) on (.+?) \((.+?), (.+?)\)$/
        key = "#{$1},#{$2}"
        fs[key] ||= Mash.new
        fs[key][:device] = $1
        fs[key][:mount] = $2
        fs[key][:fs_type] = $3
        fs[key][:mount_options] = $4.split(/,\s*/)
      end
    end

    # create views
    by_pair = fs
    by_device = generate_device_view(fs)
    by_mountpoint = generate_mountpoint_view(fs)

    fs_data = Mash.new
    fs_data["by_device"] = by_device
    fs_data["by_mountpoint"] = by_mountpoint
    fs_data["by_pair"] = by_pair

    filesystem2 fs_data
  end
end
