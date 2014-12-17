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

Ohai.plugin(:Filesystem) do
  provides "filesystem"

  def get_blk_cmd(attr, have_lsblk)
    if have_lsblk
      attr = 'FSTYPE' if attr == 'TYPE'
      "lsblk -r -n -o NAME,#{attr}"
    else
      "blkid -s #{attr}"
    end
  end

  def get_blk_regex(attr, have_lsblk)
    have_lsblk ? /^(\S+) (\S+)/ : /^(\S+): #{attr}="(\S+)"/
  end

  def find_device(name)
    %w{/dev /dev/mapper}.each do |dir|
      path = File.join(dir, name)
      return path if File.exist?(path)
    end
    name
  end

  collect_data(:linux) do
    fs = Mash.new
    have_lsblk = File.executable?('/bin/lsblk')

    # Grab filesystem data from df
    so = shell_out("df -P")
    so.stdout.lines do |line|
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
    
    # Grab filesystem inode data from df
    so = shell_out("df -iP")
    so.stdout.lines do |line|
      case line
      when /^Filesystem\s+Inodes/
        next
      when /^(.+?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+\%)\s+(.+)$/
        filesystem = $1
        fs[filesystem] ||= Mash.new
        fs[filesystem][:total_inodes] = $2
        fs[filesystem][:inodes_used] = $3
        fs[filesystem][:inodes_available] = $4
        fs[filesystem][:inodes_percent_used] = $5
        fs[filesystem][:mount] = $6
      end
    end

    # Grab mount information from /bin/mount
    so = shell_out("mount")
    so.stdout.lines do |line|
      if line =~ /^(.+?) on (.+?) type (.+?) \((.+?)\)$/
        filesystem = $1
        fs[filesystem] = Mash.new unless fs.has_key?(filesystem)
        fs[filesystem][:mount] = $2
        fs[filesystem][:fs_type] = $3
        fs[filesystem][:mount_options] = $4.split(",")
      end
    end

    have_lsblk = File.exist?('/bin/lsblk')

    # Gather more filesystem types via libuuid, even devices that's aren't mounted
    cmd = get_blk_cmd('TYPE', have_lsblk)
    regex = get_blk_regex('TYPE', have_lsblk)
    so = shell_out(cmd)
    so.stdout.lines do |line|
      if line =~ regex
        filesystem = $1
        type = $2
        filesystem = find_device(filesystem) unless filesystem.start_with?('/')
        fs[filesystem] = Mash.new unless fs.has_key?(filesystem)
        fs[filesystem][:fs_type] = type
      end
    end

    # Gather device UUIDs via libuuid
    cmd = get_blk_cmd('UUID', have_lsblk)
    regex = get_blk_regex('UUID', have_lsblk)
    so = shell_out(cmd)
    so.stdout.lines do |line|
      if line =~ regex
        filesystem = $1
        uuid = $2
        filesystem = find_device(filesystem) unless filesystem.start_with?('/')
        fs[filesystem] = Mash.new unless fs.has_key?(filesystem)
        fs[filesystem][:uuid] = uuid
      end
    end

    # Gather device labels via libuuid
    cmd = get_blk_cmd('LABEL', have_lsblk)
    regex = get_blk_regex('LABEL', have_lsblk)
    so = shell_out(cmd)
    so.stdout.lines do |line|
      if line =~ regex
        filesystem = $1
        label = $2
        filesystem = find_device(filesystem) unless filesystem.start_with?('/')
        fs[filesystem] = Mash.new unless fs.has_key?(filesystem)
        fs[filesystem][:label] = label
      end
    end

    # Grab any missing mount information from /proc/mounts
    if File.exist?('/proc/mounts')
      mounts = ''
      # Due to https://tickets.opscode.com/browse/OHAI-196
      # we have to non-block read dev files. Ew.
      f = File.open('/proc/mounts')
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
          filesystem = $1
          next if fs.has_key?(filesystem)
          fs[filesystem] = Mash.new
          fs[filesystem][:mount] = $2
          fs[filesystem][:fs_type] = $3
          fs[filesystem][:mount_options] = $4.split(",")
        end
      end
    end

    # Set the filesystem data
    filesystem fs
  end
end
