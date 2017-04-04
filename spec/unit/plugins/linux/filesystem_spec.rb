#
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Copyright:: Copyright (c) 2011-2016 Chef Software, Inc.
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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "Linux filesystem plugin" do
  let (:plugin) { get_plugin("linux/filesystem") }
  before(:each) do
    allow(plugin).to receive(:collect_os).and_return(:linux)

    allow(plugin).to receive(:shell_out).with("df -P").and_return(mock_shell_out(0, "", ""))
    allow(plugin).to receive(:shell_out).with("df -iP").and_return(mock_shell_out(0, "", ""))
    allow(plugin).to receive(:shell_out).with("mount").and_return(mock_shell_out(0, "", ""))
    allow(File).to receive(:exist?).with("/bin/lsblk").and_return(false)
    allow(plugin).to receive(:shell_out).with("blkid").and_return(mock_shell_out(0, "", ""))

    allow(plugin).to receive(:shell_out).
      with("lsblk -n -P -o NAME,UUID,LABEL,FSTYPE").
      and_return(mock_shell_out(0, "", ""))

    allow(File).to receive(:exist?).with("/proc/mounts").and_return(false)

    %w{sdb1 sdb2 sda1 sda2 md0 md1 md2}.each do |name|
      allow(File).to receive(:exist?).with("/dev/#{name}").and_return(true)
    end
    %w{
       sys.vg-root.lv
       sys.vg-swap.lv
       sys.vg-tmp.lv
       sys.vg-usr.lv
       sys.vg-var.lv
       sys.vg-home.lv
       debian--7-root
    }.each do |name|
      allow(File).to receive(:exist?).with("/dev/#{name}").and_return(false)
      allow(File).to receive(:exist?).with("/dev/mapper/#{name}").and_return(true)
    end
  end

  it "sets both filesystem and filesystem2 attributes" do
    plugin.run
    expect(plugin[:filesystem]).to eq(plugin[:filesystem2])
  end

  describe "when gathering filesystem usage data from df" do
    before(:each) do
      @stdout = <<-DF
Filesystem         1024-blocks      Used Available Capacity Mounted on
/dev/mapper/sys.vg-root.lv   4805760    378716   4182924       9% /
tmpfs                  2030944         0   2030944       0% /lib/init/rw
udev                   2025576       228   2025348       1% /dev
tmpfs                  2030944      2960   2027984       1% /dev/shm
/dev/mapper/sys.vg-home.lv  97605056  53563252  44041804      55% /home
/dev/mapper/sys.vg-special.lv  97605057  53563253  44041805      56% /special
/dev/mapper/sys.vg-tmp.lv   1919048     46588   1774976       3% /tmp
/dev/mapper/sys.vg-usr.lv  19223252   5479072  12767696      31% /usr
/dev/mapper/sys.vg-var.lv  19223252   3436556  14810212      19% /var
/dev/md0                960492     36388    875312       4% /boot
DF
      allow(plugin).to receive(:shell_out).with("df -P").and_return(mock_shell_out(0, @stdout, ""))

      @inode_stdout = <<-DFi
Filesystem      Inodes  IUsed   IFree IUse% Mounted on
/dev/xvda1     1310720 107407 1203313    9% /
/dev/mapper/sys.vg-special.lv            124865    380  124485    1% /special
tmpfs           126922    273  126649    1% /run
none            126922      1  126921    1% /run/lock
none            126922      1  126921    1% /run/shm
DFi
      allow(plugin).to receive(:shell_out).with("df -iP").and_return(mock_shell_out(0, @inode_stdout, ""))
    end

    it "should run df -P and df -iP" do
      expect(plugin).to receive(:shell_out).ordered.with("df -P").and_return(mock_shell_out(0, @stdout, ""))
      expect(plugin).to receive(:shell_out).ordered.with("df -iP").and_return(mock_shell_out(0, @inode_stdout, ""))
      plugin.run
    end

    it "should set kb_size to value from df -P" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/sys.vg-special.lv,/special"][:kb_size]).to eq("97605057")
    end

    it "should set kb_used to value from df -P" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/sys.vg-special.lv,/special"][:kb_used]).to eq("53563253")
    end

    it "should set kb_available to value from df -P" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/sys.vg-special.lv,/special"][:kb_available]).to eq("44041805")
    end

    it "should set percent_used to value from df -P" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/sys.vg-special.lv,/special"][:percent_used]).to eq("56%")
    end

    it "should set mount to value from df -P" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/sys.vg-special.lv,/special"][:mount]).to eq("/special")
    end

    it "should set total_inodes to value from df -iP" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/sys.vg-special.lv,/special"][:total_inodes]).to eq("124865")
    end

    it "should set inodes_used to value from df -iP" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/sys.vg-special.lv,/special"][:inodes_used]).to eq("380")
    end

    it "should set inodes_available to value from df -iP" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/sys.vg-special.lv,/special"][:inodes_available]).to eq("124485")
    end
  end

  describe "when gathering mounted filesystem data from mount" do
    before(:each) do
      @stdout = <<-MOUNT
/dev/mapper/sys.vg-root.lv on / type ext4 (rw,noatime,errors=remount-ro)
tmpfs on /lib/init/rw type tmpfs (rw,nosuid,mode=0755)
proc on /proc type proc (rw,noexec,nosuid,nodev)
sysfs on /sys type sysfs (rw,noexec,nosuid,nodev)
udev on /dev type tmpfs (rw,mode=0755)
tmpfs on /dev/shm type tmpfs (rw,nosuid,nodev)
devpts on /dev/pts type devpts (rw,noexec,nosuid,gid=5,mode=620)
/dev/mapper/sys.vg-home.lv on /home type xfs (rw,noatime)
/dev/mapper/sys.vg-special.lv on /special type xfs (ro,noatime)
/dev/mapper/sys.vg-tmp.lv on /tmp type ext4 (rw,noatime)
/dev/mapper/sys.vg-usr.lv on /usr type ext4 (rw,noatime)
/dev/mapper/sys.vg-var.lv on /var type ext4 (rw,noatime)
/dev/md0 on /boot type ext3 (rw,noatime,errors=remount-ro)
fusectl on /sys/fs/fuse/connections type fusectl (rw)
binfmt_misc on /proc/sys/fs/binfmt_misc type binfmt_misc (rw,noexec,nosuid,nodev)
MOUNT
      allow(plugin).to receive(:shell_out).with("mount").and_return(mock_shell_out(0, @stdout, ""))
    end

    it "should run mount" do
      expect(plugin).to receive(:shell_out).with("mount").and_return(mock_shell_out(0, @stdout, ""))
      plugin.run
    end

    it "should set mount to value from mount" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/sys.vg-special.lv,/special"][:mount]).to eq("/special")
    end

    it "should set fs_type to value from mount" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/sys.vg-special.lv,/special"][:fs_type]).to eq("xfs")
    end

    it "should set mount_options to an array of values from mount" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/sys.vg-special.lv,/special"][:mount_options]).to eq(%w{ro noatime})
    end
  end

  describe "when gathering filesystem type data from blkid" do
    before(:each) do
      # blkid and lsblk output are coorelated with df/mount output, so the
      # most full test of them actually requires we have both
      @dfstdout = <<-DF
Filesystem         1024-blocks      Used Available Capacity Mounted on
/dev/mapper/sys.vg-root.lv   4805760    378716   4182924       9% /
tmpfs                  2030944         0   2030944       0% /lib/init/rw
udev                   2025576       228   2025348       1% /dev
tmpfs                  2030944      2960   2027984       1% /dev/shm
/dev/mapper/sys.vg-home.lv  97605056  53563252  44041804      55% /home
/dev/mapper/sys.vg-special.lv  97605057  53563253  44041805      56% /special
/dev/mapper/sys.vg-tmp.lv   1919048     46588   1774976       3% /tmp
/dev/mapper/sys.vg-usr.lv  19223252   5479072  12767696      31% /usr
/dev/mapper/sys.vg-var.lv  19223252   3436556  14810212      19% /var
/dev/md0                960492     36388    875312       4% /boot
DF
      allow(plugin).to receive(:shell_out).with("df -P").and_return(mock_shell_out(0, @dfstdout, ""))

      @inode_stdout = <<-DFi
Filesystem      Inodes  IUsed   IFree IUse% Mounted on
/dev/xvda1     1310720 107407 1203313    9% /
/dev/mapper/sys.vg-special.lv            124865    380  124485    1% /special
tmpfs           126922    273  126649    1% /run
none            126922      1  126921    1% /run/lock
none            126922      1  126921    1% /run/shm
DFi
      allow(plugin).to receive(:shell_out).with("df -iP").and_return(mock_shell_out(0, @inode_stdout, ""))

      @stdout = <<-BLKID_TYPE
/dev/sdb1: LABEL=\"fuego:0\" UUID=\"bd1197e0-6997-1f3a-e27e-7801388308b5\" TYPE=\"linux_raid_member\"
/dev/sdb2: LABEL=\"fuego:1\" UUID=\"e36d933e-e5b9-cfe5-6845-1f84d0f7fbfa\" TYPE=\"linux_raid_member\"
/dev/sda1: LABEL=\"fuego:0\" UUID=\"bd1197e0-6997-1f3a-e27e-7801388308b5\" TYPE=\"linux_raid_member\"
/dev/sda2: LABEL=\"fuego:1\" UUID=\"e36d933e-e5b9-cfe5-6845-1f84d0f7fbfa\" TYPE=\"linux_raid_member\"
/dev/md0: LABEL=\"/boot\" UUID=\"37b8de8e-0fe3-4b5a-b9b4-dde33e19bb32\" TYPE=\"ext3\"
/dev/md1: UUID=\"YsIe0R-fj1y-LXTd-imla-opKo-OuIe-TBoxSK\" TYPE=\"LVM2_member\"
/dev/mapper/sys.vg-root.lv: LABEL=\"/\" UUID=\"7742d14b-80a3-4e97-9a32-478be9ea9aea\" TYPE=\"ext4\"
/dev/mapper/sys.vg-swap.lv: UUID=\"9bc2e515-8ddc-41c3-9f63-4eaebde9ce96\"  TYPE=\"swap\"
/dev/mapper/sys.vg-tmp.lv: LABEL=\"/tmp\" UUID=\"74cf7eb9-428f-479e-9a4a-9943401e81e5\" TYPE=\"ext4\"
/dev/mapper/sys.vg-usr.lv: LABEL=\"/usr\" UUID=\"26ec33c5-d00b-4f88-a550-492def013bbc\" TYPE=\"ext4\"
/dev/mapper/sys.vg-var.lv: LABEL=\"/var\" UUID=\"6b559c35-7847-4ae2-b512-c99012d3f5b3\" TYPE=\"ext4\"
/dev/mapper/sys.vg-home.lv: LABEL=\"/home\" UUID=\"d6efda02-1b73-453c-8c74-7d8dee78fa5e\" TYPE=\"xfs\"
BLKID_TYPE
      allow(plugin).to receive(:shell_out).with("blkid").and_return(mock_shell_out(0, @stdout, ""))
    end

    it "should run blkid" do
      plugin.run
    end

    it "should set kb_size to value from blkid" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/md1,"][:fs_type]).to eq("LVM2_member")
      expect(plugin[:filesystem]["by_pair"]["/dev/sda2,"][:uuid]).to eq("e36d933e-e5b9-cfe5-6845-1f84d0f7fbfa")
      expect(plugin[:filesystem]["by_pair"]["/dev/md0,/boot"][:label]).to eq("/boot")
    end
  end

  describe "when gathering filesystem type data from lsblk" do
    before(:each) do
      @dfstdout = <<-DF
Filesystem         1024-blocks      Used Available Capacity Mounted on
/dev/mapper/sys.vg-root.lv   4805760    378716   4182924       9% /
tmpfs                  2030944         0   2030944       0% /lib/init/rw
udev                   2025576       228   2025348       1% /dev
tmpfs                  2030944      2960   2027984       1% /dev/shm
/dev/mapper/sys.vg-home.lv  97605056  53563252  44041804      55% /home
/dev/mapper/sys.vg-special.lv  97605057  53563253  44041805      56% /special
/dev/mapper/sys.vg-tmp.lv   1919048     46588   1774976       3% /tmp
/dev/mapper/sys.vg-usr.lv  19223252   5479072  12767696      31% /usr
/dev/mapper/sys.vg-var.lv  19223252   3436556  14810212      19% /var
/dev/md0                960492     36388    875312       4% /boot
DF
      allow(plugin).to receive(:shell_out).with("df -P").and_return(mock_shell_out(0, @dfstdout, ""))

      @inode_stdout = <<-DFi
Filesystem      Inodes  IUsed   IFree IUse% Mounted on
/dev/xvda1     1310720 107407 1203313    9% /
/dev/mapper/sys.vg-special.lv            124865    380  124485    1% /special
tmpfs           126922    273  126649    1% /run
none            126922      1  126921    1% /run/lock
none            126922      1  126921    1% /run/shm
DFi
      allow(plugin).to receive(:shell_out).with("df -iP").and_return(mock_shell_out(0, @inode_stdout, ""))

      allow(File).to receive(:exist?).with("/bin/lsblk").and_return(true)
      @stdout = <<-BLKID_TYPE
NAME=\"sdb1\" UUID=\"bd1197e0-6997-1f3a-e27e-7801388308b5\" LABEL=\"fuego:0\" FSTYPE=\"LVM2_member\"
NAME=\"sdb2\" UUID=\"e36d933e-e5b9-cfe5-6845-1f84d0f7fbfa\" LABEL=\"fuego:1\" FSTYPE=\"LVM2_member\"
NAME=\"sda1\" UUID=\"bd1197e0-6997-1f3a-e27e-7801388308b5\" LABEL=\"fuego:0\" FSTYPE=\"LVM2_member\"
NAME=\"sda2\" UUID=\"e36d933e-e5b9-cfe5-6845-1f84d0f7fbfa\" LABEL=\"fuego:1\" FSTYPE=\"LVM2_member\"
NAME=\"md0\" UUID=\"37b8de8e-0fe3-4b5a-b9b4-dde33e19bb32\" LABEL=\"/boot\" FSTYPE=\"ext3\"
NAME=\"md1\" UUID=\"YsIe0R-fj1y-LXTd-imla-opKo-OuIe-TBoxSK\" LABEL=\"\" FSTYPE=\"LVM2_member\"
NAME=\"sys.vg-root.lv\" UUID=\"7742d14b-80a3-4e97-9a32-478be9ea9aea\" LABEL=\"/\" FSTYPE=\"ext4\"
NAME=\"sys.vg-swap.lv\" UUID=\"9bc2e515-8ddc-41c3-9f63-4eaebde9ce96\" LABEL=\"\" FSTYPE=\"swap\"
NAME=\"sys.vg-tmp.lv\" UUID=\"74cf7eb9-428f-479e-9a4a-9943401e81e5\" LABEL=\"/tmp\" FSTYPE=\"ext4\"
NAME=\"sys.vg-usr.lv\" UUID=\"26ec33c5-d00b-4f88-a550-492def013bbc\" LABEL=\"/usr\" FSTYPE=\"ext4\"
NAME=\"sys.vg-var.lv\" UUID=\"6b559c35-7847-4ae2-b512-c99012d3f5b3\" LABEL=\"/var\" FSTYPE=\"ext4\"
NAME=\"sys.vg-home.lv\" UUID=\"d6efda02-1b73-453c-8c74-7d8dee78fa5e\" LABEL=\"/home\" FSTYPE=\"xfs\"
NAME=\"debian--7-root (dm-0)\" UUID=\"09187faa-3512-4505-81af-7e86d2ccb99a\" LABEL=\"root\" FSTYPE=\"ext4\"
BLKID_TYPE
      allow(plugin).to receive(:shell_out).
        with("lsblk -n -P -o NAME,UUID,LABEL,FSTYPE").
        and_return(mock_shell_out(0, @stdout, ""))
    end

    it "should run lsblk -n -P -o NAME,UUID,LABEL,FSTYPE" do
      plugin.run
    end

    it "should set kb_size to value from lsblk -n -P -o NAME,UUID,LABEL,FSTYPE" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/md1,"][:fs_type]).to eq("LVM2_member")
      expect(plugin[:filesystem]["by_pair"]["/dev/sda2,"][:uuid]).to eq("e36d933e-e5b9-cfe5-6845-1f84d0f7fbfa")
      expect(plugin[:filesystem]["by_pair"]["/dev/md0,/boot"][:label]).to eq("/boot")
    end

    it "should ignore extra info in name and set label to value from lsblk  -n -P -o NAME,UUID,LABEL,FSTYPE" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/debian--7-root,"][:label]).to eq("root")
    end

  end

  describe "when gathering data from /proc/mounts" do
    before(:each) do
      allow(File).to receive(:exist?).with("/proc/mounts").and_return(true)
      @double_file = double("/proc/mounts")
      @mounts = <<-MOUNTS
rootfs / rootfs rw 0 0
none /sys sysfs rw,nosuid,nodev,noexec,relatime 0 0
none /proc proc rw,nosuid,nodev,noexec,relatime 0 0
none /dev devtmpfs rw,relatime,size=2025576k,nr_inodes=506394,mode=755 0 0
none /dev/pts devpts rw,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=000 0 0
/dev/mapper/sys.vg-root.lv / ext4 rw,noatime,errors=remount-ro,barrier=1,data=ordered 0 0
tmpfs /lib/init/rw tmpfs rw,nosuid,relatime,mode=755 0 0
tmpfs /dev/shm tmpfs rw,nosuid,nodev,relatime 0 0
/dev/mapper/sys.vg-home.lv /home xfs rw,noatime,attr2,noquota 0 0
/dev/mapper/sys.vg-special.lv /special xfs ro,noatime,attr2,noquota 0 0
/dev/mapper/sys.vg-tmp.lv /tmp ext4 rw,noatime,barrier=1,data=ordered 0 0
/dev/mapper/sys.vg-usr.lv /usr ext4 rw,noatime,barrier=1,data=ordered 0 0
/dev/mapper/sys.vg-var.lv /var ext4 rw,noatime,barrier=1,data=ordered 0 0
/dev/md0 /boot ext3 rw,noatime,errors=remount-ro,data=ordered 0 0
fusectl /sys/fs/fuse/connections fusectl rw,relatime 0 0
binfmt_misc /proc/sys/fs/binfmt_misc binfmt_misc rw,nosuid,nodev,noexec,relatime 0 0
MOUNTS
      @counter = 0
      allow(@double_file).to receive(:read_nonblock) do
        @counter += 1
        raise EOFError if @counter == 2
        @mounts
      end
      allow(@double_file).to receive(:close)
      allow(File).to receive(:open).with("/proc/mounts").and_return(@double_file)
    end

    it "should set mount to value from /proc/mounts" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/sys.vg-special.lv,/special"][:mount]).to eq("/special")
    end

    it "should set fs_type to value from /proc/mounts" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/sys.vg-special.lv,/special"][:fs_type]).to eq("xfs")
    end

    it "should set mount_options to an array of values from /proc/mounts" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/mapper/sys.vg-special.lv,/special"][:mount_options]).to eq(%w{ro noatime attr2 noquota})
    end
  end

  describe "when gathering filesystem data with devices mounted more than once" do
    before(:each) do
      # there's a few different examples one can run into in this output:
      # 1. A device physically mounted in more than one place: /home and /home2
      # 2. A bind-mounted directory, which shows up as the same device in a
      # subdir: / and /var/chroot
      # 3. tmpfs in multiple places.
      @dfstdout = <<-DF
Filesystem         1024-blocks      Used Available Capacity Mounted on
/dev/mapper/sys.vg-root.lv   4805760    378716   4182924       9% /
tmpfs                  2030944         0   2030944       0% /lib/init/rw
udev                   2025576       228   2025348       1% /dev
tmpfs                  2030944      2960   2027984       1% /dev/shm
/dev/mapper/sys.vg-home.lv  97605056  53563252  44041804      55% /home
/dev/mapper/sys.vg-home.lv  97605056  53563252  44041804      55% /home2
/dev/mapper/sys.vg-root.lv  4805760    378716   4182924       9% /var/chroot
DF
      allow(plugin).to receive(:shell_out).with("df -P").and_return(mock_shell_out(0, @dfstdout, ""))

      @inode_stdout = <<-DFi
Filesystem      Inodes  IUsed   IFree IUse% Mounted on
/dev/mapper/sys.vg-root.lv     1310720 107407 1203313    9% /
tmpfs           126922    273  126649    1% /lib/init/rw
none            126922      1  126921    1% /dev/shm
udev            126922      1  126921    1% /dev
/dev/mapper/sys.vg-home.lv  60891136  4696030 56195106      8% /home
/dev/mapper/sys.vg-home.lv  60891136  4696030 56195106      8% /home2
/dev/mapper/sys.vg-root.lv  1310720 107407 1203313       9% /var/chroot
DFi
      allow(plugin).to receive(:shell_out).with("df -iP").and_return(mock_shell_out(0, @inode_stdout, ""))

      allow(File).to receive(:exist?).with("/bin/lsblk").and_return(true)
      @stdout = <<-BLKID_TYPE
NAME=\"/dev/mapper/sys.vg-root.lv\" UUID=\"7742d14b-80a3-4e97-9a32-478be9ea9aea\" LABEL=\"/\" FSTYPE=\"ext4\"
NAME=\"/dev/mapper/sys.vg-home.lv\" UUID=\"d6efda02-1b73-453c-8c74-7d8dee78fa5e\" LABEL=\"/home\" FSTYPE=\"xfs\"
BLKID_TYPE
      allow(plugin).to receive(:shell_out).
        with("lsblk -n -P -o NAME,UUID,LABEL,FSTYPE").
        and_return(mock_shell_out(0, @stdout, ""))
    end

    it "should provide a devices view with all mountpoints" do
      plugin.run
      expect(plugin[:filesystem]["by_device"]["/dev/mapper/sys.vg-root.lv"][:mounts]).to eq(["/", "/var/chroot"])
      expect(plugin[:filesystem]["by_device"]["/dev/mapper/sys.vg-home.lv"][:mounts]).to eq(["/home", "/home2"])
      expect(plugin[:filesystem]["by_device"]["tmpfs"][:mounts]).to eq(["/lib/init/rw", "/dev/shm"])
    end
  end

  describe "when gathering filesystem data with double-mounts" do
    before(:each) do
      @dfstdout = <<-DF
Filesystem         1024-blocks      Used Available Capacity Mounted on
/dev/mapper/sys.vg-root.lv   4805760    378716   4182924       9% /
tmpfs                  2030944         0   2030944       0% /lib/init/rw
udev                   2025576       228   2025348       1% /dev
tmpfs                  2030944      2960   2027984       1% /dev/shm
/dev/mapper/sys.vg-home.lv  97605056  53563252  44041804      55% /home
/dev/sdb1              97605056  53563252  44041804      55% /mnt
/dev/sdc1              4805760    378716   4182924       9% /mnt
DF
      allow(plugin).to receive(:shell_out).with("df -P").and_return(mock_shell_out(0, @dfstdout, ""))

      @inode_stdout = <<-DFi
Filesystem      Inodes  IUsed   IFree IUse% Mounted on
/dev/mapper/sys.vg-root.lv     1310720 107407 1203313    9% /
tmpfs           126922    273  126649    1% /lib/init/rw
none            126922      1  126921    1% /dev/shm
udev            126922      1  126921    1% /dev
/dev/mapper/sys.vg-home.lv  60891136  4696030 56195106      8% /home
/dev/sdb1       60891136  4696030 56195106      8% /mnt
/dev/sdc1       1310720 107407 1203313          9% /mnt
DFi
      allow(plugin).to receive(:shell_out).with("df -iP").and_return(mock_shell_out(0, @inode_stdout, ""))

      allow(File).to receive(:exist?).with("/bin/lsblk").and_return(true)
      @stdout = <<-BLKID_TYPE
NAME=\"/dev/mapper/sys.vg-root.lv\" UUID=\"7742d14b-80a3-4e97-9a32-478be9ea9aea\" LABEL=\"/\" FSTYPE=\"ext4\"
NAME=\"/dev/sdb1\" UUID=\"6b559c35-7847-4ae2-b512-c99012d3f5b3\" LABEL=\"/mnt\" FSTYPE=\"ext4\"
NAME=\"/dev/sdc1\" UUID=\"7f1e51bf-3608-4351-b7cd-379e39cff36a\" LABEL=\"/mnt\" FSTYPE=\"ext4\"
NAME=\"/dev/mapper/sys.vg-home.lv\" UUID=\"d6efda02-1b73-453c-8c74-7d8dee78fa5e\" LABEL=\"/home\" FSTYPE=\"xfs\"
BLKID_TYPE
      allow(plugin).to receive(:shell_out).
        with("lsblk -n -P -o NAME,UUID,LABEL,FSTYPE").
        and_return(mock_shell_out(0, @stdout, ""))
    end

    it "should provide a mounts view with all devices" do
      plugin.run
      expect(plugin[:filesystem]["by_mountpoint"]["/mnt"][:devices]).to eq(["/dev/sdb1", "/dev/sdc1"])
    end
  end
end
