#
# Author:: Phil Dibowitz <phil@ipom.com>
# Author:: Adam Jacob <adam@chef.io>
# Copyright:: Copyright (c) 2008-2017 Chef Software, Inc.
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

  def find_device(name)
    %w{/dev /dev/mapper}.each do |dir|
      path = File.join(dir, name)
      return path if File.exist?(path)
    end
    name
  end

  def parse_line(line, have_lsblk)
    if have_lsblk
      regex = /NAME="(\S+).*?" UUID="(\S*)" LABEL="(\S*)" FSTYPE="(\S*)"/
      if line =~ regex
        dev = $1
        dev = find_device(dev) unless dev.start_with?("/")
        uuid = $2
        label = $3
        fs_type = $4
        return { :dev => dev, :uuid => uuid, :label => label, :fs_type => fs_type }
      end
    else
      bits = line.split
      dev = bits.shift.split(":")[0]
      f = { :dev => dev }
      bits.each do |keyval|
        if keyval =~ /(\S+)="(\S+)"/
          key = $1.downcase.to_sym
          key = :fs_type if key == :type
          f[key] = $2
        end
      end
      return f
    end
    return nil
  end

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

  collect_data(:linux) do
    fs = Mash.new

    # Grab filesystem data from df
    so = shell_out("df -P")
    so.stdout.each_line do |line|
      case line
      when /^Filesystem\s+1024-blocks/
        next
      when /^(.+?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+\%)\s+(.+)$/
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

    # Grab filesystem inode data from df
    so = shell_out("df -iP")
    so.stdout.each_line do |line|
      case line
      when /^Filesystem\s+Inodes/
        next
      when /^(.+?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+\%)\s+(.+)$/
        key = "#{$1},#{$6}"
        fs[key] ||= Mash.new
        fs[key][:device] = $1
        fs[key][:total_inodes] = $2
        fs[key][:inodes_used] = $3
        fs[key][:inodes_available] = $4
        fs[key][:inodes_percent_used] = $5
        fs[key][:mount] = $6
      end
    end

    # Grab mount information from /bin/mount
    so = shell_out("mount")
    so.stdout.each_line do |line|
      if line =~ /^(.+?) on (.+?) type (.+?) \((.+?)\)$/
        key = "#{$1},#{$2}"
        fs[key] = Mash.new unless fs.has_key?(key)
        fs[key][:device] = $1
        fs[key][:mount] = $2
        fs[key][:fs_type] = $3
        fs[key][:mount_options] = $4.split(",")
      end
    end

    have_lsblk = File.exist?("/bin/lsblk")
    if have_lsblk
      cmd = "lsblk -n -P -o NAME,UUID,LABEL,FSTYPE"
    else
      # CentOS5 and other platforms don't have lsblk
      cmd = "blkid"
    end

    so = shell_out(cmd)
    so.stdout.each_line do |line|
      parsed = parse_line(line, have_lsblk)
      next if parsed.nil?
      # lsblk lists each device once, so we need to update all entries
      # in the hash that are related to this device
      keys_to_update = []
      fs.each_key do |key|
        keys_to_update << key if key.start_with?("#{parsed[:dev]},")
      end

      if keys_to_update.empty?
        key = "#{parsed[:dev]},"
        fs[key] = Mash.new
        fs[key][:device] = parsed[:dev]
        keys_to_update << key
      end

      keys_to_update.each do |key|
        [:fs_type, :uuid, :label].each do |subkey|
          if parsed[subkey] && !parsed[subkey].empty?
            fs[key][subkey] = parsed[subkey]
          end
        end
      end
    end

    # Grab any missing mount information from /proc/mounts
    if File.exist?("/proc/mounts")
      mounts = ""
      # Due to https://tickets.opscode.com/browse/OHAI-196
      # we have to non-block read dev files. Ew.
      f = File.open("/proc/mounts")
      loop do
        begin
          data = f.read_nonblock(4096)
          mounts << data
        # We should just catch EOFError, but the kernel had a period of
        # bugginess with reading virtual files, so we're being extra
        # cautious here, catching all exceptions, and then we'll read
        # whatever data we might have
        rescue Exception
          break
        end
      end
      f.close
      mounts.each_line do |line|
        if line =~ /^(\S+) (\S+) (\S+) (\S+) \S+ \S+$/
          key = "#{$1},#{$2}"
          next if fs.has_key?(key)
          fs[key] = Mash.new
          fs[key][:device] = $1
          fs[key][:mount] = $2
          fs[key][:fs_type] = $3
          fs[key][:mount_options] = $4.split(",")
        end
      end
    end

    by_pair = fs
    by_device = generate_device_view(fs)
    by_mountpoint = generate_mountpoint_view(fs)

    fs_data = Mash.new
    fs_data["by_device"] = by_device
    fs_data["by_mountpoint"] = by_mountpoint
    fs_data["by_pair"] = by_pair

    # Set the filesystem data
    filesystem fs_data
    filesystem2 fs_data
  end
end
