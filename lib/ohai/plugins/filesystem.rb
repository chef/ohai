#
# Author:: Phil Dibowitz <phil@ipom.com>
# Author:: Adam Jacob <adam@chef.io>
# Author:: Kurt Yoder (ktyopscode@yoderhome.com)
# Author:: Deepali Jagtap (<deepali.jagtap@clogeny.com>)
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Author:: Isa Farnik (<isa@chef.io>)
# Author:: James Gartrell (<jgartrel@gmail.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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
  provides "filesystem".freeze

  def find_device(name)
    %w{/dev /dev/mapper}.each do |dir|
      path = File.join(dir, name)
      return path if file_exist?(path)
    end
    name
  end

  def parse_line(line, cmdtype)
    case cmdtype
    when "lsblk"
      regex = /NAME="(\S+).*?" UUID="(\S*)" LABEL="(\S*)" FSTYPE="(\S*)"/
      if line =~ regex
        dev = $1
        dev = find_device(dev) unless dev.start_with?("/")
        uuid = $2
        label = $3
        fs_type = $4
        return { dev: dev, uuid: uuid, label: label, fs_type: fs_type }
      end
    when "blkid"
      bits = line.split
      dev = bits.shift.split(":")[0]
      f = { dev: dev }
      bits.each do |keyval|
        if keyval =~ /(\S+)="(\S+)"/
          key = $1.downcase.to_sym
          key = :fs_type if key == :type
          f[key] = $2
        end
      end
      return f
    end
    nil
  end

  def generate_device_view(fs)
    view = {}
    fs.each_value do |entry|
      view[entry[:device]] ||= Mash.new
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

      view[entry[:mount]] ||= Mash.new
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

  def parse_common_df(out)
    fs = {}
    out.each_line do |line|
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
    fs
  end

  def run_with_check(bin, &block)
    yield
  rescue Ohai::Exceptions::Exec => e
    unless Ohai.config[:plugin][:filesystem][:allow_partial_data]
      raise e
    end

    logger.warn("Plugin Filesystem: #{bin} binary is not available. Some data will not be available.")
  end

  ### Windows specific methods BEGINS
  # Drive types
  DRIVE_TYPE ||= %w{unknown no_root_dir removable local network cd ram}.freeze

  # Volume encryption or decryption status
  #
  # @see https://docs.microsoft.com/en-us/windows/desktop/SecProv/getconversionstatus-win32-encryptablevolume#parameters
  #
  CONVERSION_STATUS ||= %w{
    FullyDecrypted FullyEncrypted EncryptionInProgress
    DecryptionInProgress EncryptionPaused DecryptionPaused
  }.freeze

  # Returns a Mash loaded with logical details
  #
  # Uses Win32_LogicalDisk and logical_properties to return general details of volumes.
  #
  # Returns an empty Mash in case of any WMI exception.
  #
  # @see https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-logicaldisk
  #
  # @return [Mash]
  #
  def logical_info
    wmi = WmiLite::Wmi.new("Root\\CIMV2")

    # TODO: We should really be parsing Win32_Volume and Win32_MountPoint.
    disks = wmi.instances_of("Win32_LogicalDisk")
    logical_properties(disks)
  rescue WmiLite::WmiException
    Ohai::Log.debug("Unable to access Win32_LogicalDisk. Skipping logical details")
    Mash.new
  end

  # Returns a Mash loaded with encryption details
  #
  # Uses Win32_EncryptableVolume and encryption_properties to return encryption details of volumes.
  #
  # Returns an empty Mash in case of any WMI exception.
  #
  # @note We are fetching Encryption Status only as of now
  #
  # @see https://msdn.microsoft.com/en-us/library/windows/desktop/aa376483(v=vs.85).aspx
  #
  # @return [Mash]
  #
  def encryptable_info
    wmi = WmiLite::Wmi.new("Root\\CIMV2\\Security\\MicrosoftVolumeEncryption")
    disks = wmi.instances_of("Win32_EncryptableVolume")
    encryption_properties(disks)
  rescue WmiLite::WmiException
    Ohai::Log.debug("Unable to access Win32_EncryptableVolume. Skipping encryptable details")
    Mash.new
  end

  # Refines and calculates logical properties out of given instances.
  #
  # Note that :device here is the same as Volume name and there for compatibility with other OSes.
  #
  # @param [WmiLite::Wmi::Instance] disks
  #
  # @return [Mash] Each drive containing following properties:
  #
  #  * :kb_size (Integer)
  #  * :kb_available (Integer)
  #  * :kb_used (Integer)
  #  * :percent_used (Integer)
  #  * :mount (String)
  #  * :fs_type (String)
  #  * :volume_name (String)
  #  * :device (String)
  #
  def logical_properties(disks)
    properties = Mash.new
    disks.each do |disk|
      property = Mash.new
      # In windows the closest thing we have to a device is the volume name
      # and the "mountpoint" is the drive letter...
      device = disk["volumename"].to_s.downcase
      mount = disk["deviceid"]
      property[:kb_size] = disk["size"] ? disk["size"].to_i / 1000 : 0
      property[:kb_available] = disk["freespace"].to_i / 1000
      property[:kb_used] = property[:kb_size] - property[:kb_available]
      property[:percent_used] = (property[:kb_size] == 0 ? 0 : (property[:kb_used] * 100 / property[:kb_size]))
      property[:mount] = mount
      property[:fs_type] = disk["filesystem"].to_s.downcase
      property[:drive_type] = disk["drivetype"].to_i
      property[:drive_type_string] = DRIVE_TYPE[disk["drivetype"].to_i]
      property[:drive_type_human] = disk["description"].to_s
      property[:volume_name] = disk["volumename"].to_s
      property[:device] = device

      key = "#{device},#{mount}"
      properties[key] = property
    end
    properties
  end

  # Refines and calculates encryption properties out of given instances
  #
  # @param [WmiLite::Wmi::Instance] disks
  #
  # @return [Mash] Each drive containing following properties:
  #
  #  * :encryption_status (String)
  #
  def encryption_properties(disks)
    properties = Mash.new
    disks.each do |disk|
      property = Mash.new
      property[:encryption_status] = disk["conversionstatus"] ? CONVERSION_STATUS[disk["conversionstatus"]] : ""
      key = disk["driveletter"]
      properties[key] = property
    end
    properties
  end

  # Merges all the various properties of filesystems
  #
  # @param [Array<Mash>] disks_info
  #   Array of the Mashes containing disk properties
  #
  # @return [Mash]
  #
  def merge_info(logical_info, encryption_info)
    fs = Mash.new

    encryption_keys_used = Set.new
    logical_info.each do |key, info|
      if encryption_info[info["mount"]]
        encryption_keys_used.add(info["mount"])
        fs[key] = info.merge(encryption_info[info["mount"]])
      else
        fs[key] = info.dup
      end
    end
    left_enc = encryption_info.reject { |x| encryption_keys_used.include?(x) }
    left_enc.each do |key, info|
      fs[",#{key}"] = info
    end
    fs
  end

  def collect_btrfs_data(entry)
    btrfs = Mash.new
    if entry[:fs_type] == "btrfs" && entry["uuid"]
      uuid = entry["uuid"]
      alloc = "/sys/fs/btrfs/#{uuid}/allocation"
      %w{data metadata system}.each do |bg_type|
        dir = "#{alloc}/#{bg_type}"
        %w{single dup}.each do |raid|
          if file_exist?("#{dir}/#{raid}")
            btrfs["raid"] = raid
          end
        end
        logger.trace("Plugin Filesystem: reading btrfs allocation files at #{dir}")
        btrfs["allocation"] ||= Mash.new
        btrfs["allocation"][bg_type] ||= Mash.new
        %w{total_bytes bytes_used}.each do |field|
          bytes = file_read("#{dir}/#{field}").chomp.to_i
          btrfs["allocation"][bg_type][field] = "#{bytes}"
        end
      end
    end
    btrfs
  end

  collect_data(:linux) do
    fs = Mash.new

    # Grab filesystem data from df
    run_with_check("df") do
      fs.merge!(parse_common_df(shell_out("df -P").stdout))

      # Grab filesystem inode data from df
      shell_out("df -iP").stdout.each_line do |line|
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
    end

    # Grab mount information from /bin/mount
    run_with_check("mount") do
      shell_out("mount").stdout.each_line do |line|
        if line =~ /^(.+?) on (.+?) type (.+?) \((.+?)\)$/
          key = "#{$1},#{$2}"
          fs[key] ||= Mash.new
          fs[key][:device] = $1
          fs[key][:mount] = $2
          fs[key][:fs_type] = $3
          fs[key][:mount_options] = $4.split(",")
        end
      end
    end

    # We used to try to decide if we wanted to run lsblk or blkid
    # but they each have a variety of cases were they fail to report
    # data. For example, there are a variety of cases where lsblk won't
    # report unmounted filesystems, but blkid will. And vise-versa. Sweet.
    # So for reliability, we'll run both, if we have them.

    lsblk = which("lsblk")
    blkid = which("blkid")
    cmds = []
    # These should be in order of preference... first writer wins.
    if lsblk
      cmds << "#{lsblk} -n -P -o NAME,UUID,LABEL,FSTYPE"
    end
    if blkid
      cmds << blkid
    end

    cmds.each do |cmd|
      cmdtype = File.basename(cmd.split.first)
      # setting the timeout here for `lsblk` and `blkid` commands to 60
      # this is to allow machines with large amounts of attached LUNs
      # to respond back to the command successfully
      run_with_check(cmdtype) do
        shell_out(cmd, timeout: 60).stdout.each_line do |line|
          parsed = parse_line(line, cmdtype)
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

          keys_to_update.each do |k|
            %i{fs_type uuid label}.each do |subkey|
              if parsed[subkey] && !parsed[subkey].empty?
                fs[k][subkey] = parsed[subkey]
              end
            end
          end
        end
      end
    end

    # Grab any missing mount information from /proc/mounts
    if file_exist?("/proc/mounts")
      mounts = ""
      # Due to https://tickets.opscode.com/browse/OHAI-196
      # we have to non-block read dev files. Ew.
      f = file_open("/proc/mounts")
      loop do
        data = f.read_nonblock(4096)
        mounts << data
      # We should just catch EOFError, but the kernel had a period of
      # bugginess with reading virtual files, so we're being extra
      # cautious here, catching all exceptions, and then we'll read
      # whatever data we might have
      rescue Exception
        break
      end
      f.close

      mounts.each_line do |line|
        if line =~ /^(\S+) (\S+) (\S+) (\S+) \S+ \S+$/
          key = "#{$1},#{$2}"
          next if fs.key?(key)

          fs[key] = Mash.new
          fs[key][:device] = $1
          fs[key][:mount] = $2
          fs[key][:fs_type] = $3
          fs[key][:mount_options] = $4.split(",")
        end
      end
    end

    fs.each do |key, entry|
      if entry[:fs_type] == "btrfs"
        fs[key][:btrfs] = collect_btrfs_data(entry)
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
  end

  collect_data(:freebsd, :openbsd, :netbsd, :dragonflybsd) do
    fs = Mash.new

    # Grab filesystem data from df
    run_with_check("df") do
      so = shell_out("df")
      fs.merge!(parse_common_df(so.stdout))

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
    end

    # Grab mount information from mount
    run_with_check("mount") do
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
    end

    # create views
    by_pair = fs
    by_device = generate_device_view(fs)
    by_mountpoint = generate_mountpoint_view(fs)

    fs_data = Mash.new
    fs_data["by_device"] = by_device
    fs_data["by_mountpoint"] = by_mountpoint
    fs_data["by_pair"] = by_pair

    filesystem fs_data
  end

  collect_data(:darwin) do
    fs = Mash.new
    block_size = 0
    # on new versions of OSX, -i is default, on old versions it's not, so
    # specifying it gets consistent output
    run_with_check("df") do
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
    end

    run_with_check("mount") do
      so = shell_out("mount")
      so.stdout.lines do |line|
        if line =~ /^(.+?) on (.+?) \((.+?), (.+?)\)$/
          key = "#{$1},#{$2}"
          fs[key] ||= Mash.new
          fs[key][:mount] = $2
          fs[key][:fs_type] = $3
          fs[key][:mount_options] = $4.split(/,\s*/)
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

    filesystem fs_data
  end

  collect_data(:solaris2) do
    fs = Mash.new

    # Grab filesystem data from df
    run_with_check("df") do
      so = shell_out("df -Pka")
      fs.merge!(parse_common_df(so.stdout))

      # Grab file system type from df (must be done separately)
      so = shell_out("df -na")
      so.stdout.lines do |line|
        next unless line =~ /^(.+?)\s*: (\S+)\s*$/

        mount = $1
        fs.each do |key, fs_attributes|
          next unless fs_attributes[:mount] == mount

          fs[key][:fs_type] = $2
        end
      end
    end

    # Grab mount information from /bin/mount
    run_with_check("mount") do
      so = shell_out("mount")
      so.stdout.lines do |line|
        next unless line =~ /^(.+?) on (.+?) (.+?) on (.+?)$/

        key = "#{$2},#{$1}"
        fs[key] ||= Mash.new
        fs[key][:mount] = $1
        fs[key][:mount_time] = $4 # $4 must come before "split", else it becomes nil
        fs[key][:mount_options] = $3.split("/")
      end
    end

    # Grab any zfs data from "zfs get"
    zfs = Mash.new
    zfs_get = "zfs get -p -H all"
    run_with_check("zfs") do
      so = shell_out(zfs_get)
      so.stdout.lines do |line|
        next unless line =~ /^([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)$/

        filesystem = $1
        property = $2
        value = $3
        source = $4.chomp
        zfs[filesystem] ||= Mash.new
        # if this fs doesn't exist, put in the bare minimum
        zfs[filesystem][property] = {
          value: value,
          source: source,
        }
      end
    end

    zfs.each do |fs_name, attributes|
      mountpoint = attributes[:mountpoint][:value] if attributes[:mountpoint]
      key = "#{fs_name},#{mountpoint}"
      fs[key] ||= Mash.new
      fs[key][:fs_type] = "zfs"
      fs[key][:mount] = mountpoint if mountpoint
      fs[key][:device] = fs_name
      fs[key][:zfs_properties] = attributes
      # find all zfs parents
      parents = fs_name.split("/")
      zfs_parents = []
      (0..parents.length - 1).to_a.each do |parent_index|
        next_parent = parents[0..parent_index].join("/")
        zfs_parents.push(next_parent)
      end
      zfs_parents.pop
      fs[key][:zfs_parents] = zfs_parents
      fs[key][:zfs_zpool] = (zfs_parents.length == 0)
    end

    # create views
    by_pair = fs
    by_device = generate_device_view(fs)
    by_mountpoint = generate_mountpoint_view(fs)

    fs_data = Mash.new
    fs_data["by_device"] = by_device
    fs_data["by_mountpoint"] = by_mountpoint
    fs_data["by_pair"] = by_pair

    filesystem fs_data
  end

  collect_data(:aix) do
    def parse_df_or_mount(shell_out)
      oldie = Mash.new

      shell_out.lines.each do |line|
        fields = line.split
        case line
        # headers and horizontal rules to skip
        when /^\s*(node|---|^Filesystem\s+1024-blocks)/
          next
        # strictly a df entry
        when /^(.+?)\s+([0-9-]+)\s+([0-9-]+)\s+([0-9-]+)\s+([0-9-]+\%*)\s+(.+)$/
          if $1 == "Global"
            dev = "#{$1}:#{$6}"
          else
            dev = $1
          end
          mountpoint = $6
          key = "#{dev},#{mountpoint}"
          oldie[key] ||= Mash.new
          oldie[key][:kb_size] = $2
          oldie[key][:kb_used] = $3
          oldie[key][:kb_available] = $4
          oldie[key][:percent_used] = $5
          oldie[key][:mount] = mountpoint
          oldie[key][:device] = dev
        # an entry starting with 'G' or / (E.G. /tmp or /var)
        when %r{^\s*(G.*?|/\w)}
          if fields[0] == "Global"
            dev = fields[0] + ":" + fields[1]
          else
            dev = fields[0]
          end
          mountpoint = fields[1]
          key = "#{dev},#{mountpoint}"
          oldie[key] ||= Mash.new
          oldie[key][:mount] = mountpoint
          oldie[key][:fs_type] = fields[2]
          oldie[key][:mount_options] = fields[6].split(",")
          oldie[key][:device] = dev
        # entries occupying the 'Node' column parsed here
        else
          dev = fields[0] + ":" + fields[1]
          mountpoint = fields[2]
          key = "#{dev},#{mountpoint}"
          oldie[key] ||= Mash.new
          oldie[key][:mount] = mountpoint
          oldie[key][:device] = dev
          oldie[key][:fs_type] = fields[3]
          oldie[key][:mount_options] = fields[7].split(",")
        end
      end
      oldie
    end

    def collect_old_version(shell_outs)
      mount_hash = parse_df_or_mount shell_outs[:mount]
      df_hash    = parse_df_or_mount shell_outs[:df_Pk]

      mount_hash.each do |key, hash|
        df_hash[key].merge!(hash) if df_hash.key?(key)
      end

      mount_hash.merge(df_hash)
    end

    # Cache the command output
    shell_outs = Mash.new

    run_with_check("mount") do
      shell_outs[:mount] = shell_out("mount").stdout
    end

    run_with_check("df") do
      shell_outs[:df_Pk] = shell_out("df -Pk").stdout
    end

    fs = collect_old_version(shell_outs)
    by_pair = fs
    by_device = generate_device_view(fs)
    by_mountpoint = generate_mountpoint_view(fs)

    fs_data = Mash.new
    fs_data["by_device"] = by_device
    fs_data["by_mountpoint"] = by_mountpoint
    fs_data["by_pair"] = by_pair

    filesystem fs_data
  end

  collect_data(:windows) do
    require "set" unless defined?(Set)
    require "wmi-lite/wmi" unless defined?(WmiLite::Wmi)
    require_relative "../mash"

    fs = merge_info(logical_info, encryptable_info)

    by_pair = fs
    by_device = generate_device_view(fs)
    by_mountpoint = generate_mountpoint_view(fs)

    fs_data = Mash.new
    fs_data["by_device"] = by_device
    fs_data["by_mountpoint"] = by_mountpoint
    fs_data["by_pair"] = by_pair

    # Chef 16 added 'filesystem2'
    # In Chef 17 we made 'filesystem' and 'filesystem2' match (both new-style)
    # In Chef 18 we will drop 'filesystem2'
    filesystem fs_data
    filesystem2 fs_data
  end
end
