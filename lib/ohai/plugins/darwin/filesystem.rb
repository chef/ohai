#
# Author:: Phil Dibowitz (<phil@ipom.com>)
# Author:: Benjamin Black (<bb@chef.io>)
# Copyright:: Copyright (c) 2009-2016 Chef Software, Inc.
# Copyright:: Copyright (c) 2015 Facebook, Inc.
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
  provides "filesystem2"

  def generate_device_view(fs)
    view = {}
    fs.each_value do |entry|
      view[entry[:device]] = Mash.new unless view[entry[:device]]
      entry.each do |key, val|
        next if %w{device mount}.include?(key)
        view[entry[:device]][key] = val
      end
      if entry[:mount]
        view[entry[:device]][:mounts] = [] unless view[entry[:device]][:mounts]
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
      if entry[:device]
        view[entry[:mount]][:devices] = [] unless view[entry[:mount]][:devices]
        view[entry[:mount]][:devices] << entry[:device]
      end
    end
    view
  end

  collect_data(:darwin) do
    fs = Mash.new
    block_size = 0
    # on new versions of OSX, -i is default, on old versions it's not, so
    # specifying it gets consistent output
    so = shell_out("df -i")
    so.stdout.each_line do |line|
      case line
      when /^Filesystem\s+(\d+)-/
        block_size = $1.to_i
        next
      when /^(.+?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+\%)\s+(\d+)\s+(\d+)\s+(\d+%)\s+(.+)$/
        key = "#{$1},#{$9}"
        fs[key] = Mash.new
        fs[key][:block_size] = block_size
        fs[key][:device] = $1
        fs[key][:kb_size] = ($2.to_i / (1024 / block_size)).to_s
        fs[key][:kb_used] = ($3.to_i / (1024 / block_size)).to_s
        fs[key][:kb_available] = ($4.to_i / (1024 / block_size)).to_s
        fs[key][:percent_used] = $5
        fs[key][:inodes_used] = $6
        fs[key][:inodes_available] = $7
        fs[key][:total_inodes] = ($6.to_i + $7.to_i).to_s
        fs[key][:inodes_percent_used] = $8
        fs[key][:mount] = $9
      end
    end

    so = shell_out("mount")
    so.stdout.lines do |line|
      if line =~ /^(.+?) on (.+?) \((.+?), (.+?)\)$/
        key = "#{$1},#{$2}"
        fs[key] = Mash.new unless fs.has_key?(key)
        fs[key][:mount] = $2
        fs[key][:fs_type] = $3
        fs[key][:mount_options] = $4.split(/,\s*/)
      end
    end

    by_pair = fs
    by_device = generate_device_view(fs)
    by_mountpoint = generate_mountpoint_view(fs)

    fs_data = Mash.new
    fs_data["by_device"] = by_device
    fs_data["by_mountpoint"] = by_mountpoint
    fs_data["by_pair"] = by_pair

    filesystem fs_data
    filesystem2 fs_data
  end
end
