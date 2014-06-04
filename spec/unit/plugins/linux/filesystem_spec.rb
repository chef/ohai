#
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "Linux filesystem plugin" do
  before(:each) do
    @plugin = get_plugin("linux/filesystem")
    @plugin.stub(:collect_os).and_return(:linux)

    @plugin.stub(:shell_out).with("df -P").and_return(mock_shell_out(0, "", ""))
    @plugin.stub(:shell_out).with("mount").and_return(mock_shell_out(0, "", ""))
    @plugin.stub(:shell_out).with("blkid -s TYPE").and_return(mock_shell_out(0, "", ""))
    @plugin.stub(:shell_out).with("blkid -s UUID").and_return(mock_shell_out(0, "", ""))
    @plugin.stub(:shell_out).with("blkid -s LABEL").and_return(mock_shell_out(0, "", ""))

    File.stub(:exists?).with("/proc/mounts").and_return(false)
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
      @plugin.stub(:shell_out).with("df -P").and_return(mock_shell_out(0, @stdout, ""))
    end

    it "should run df -P" do
      @plugin.should_receive(:shell_out).with("df -P").and_return(mock_shell_out(0, @stdout, ""))
      @plugin.run
    end

    it "should set kb_size to value from df -P" do
      @plugin.run
      @plugin[:filesystem]["/dev/mapper/sys.vg-special.lv"][:kb_size].should be == "97605057"
    end

    it "should set kb_used to value from df -P" do
      @plugin.run
      @plugin[:filesystem]["/dev/mapper/sys.vg-special.lv"][:kb_used].should be == "53563253"
    end

    it "should set kb_available to value from df -P" do
      @plugin.run
      @plugin[:filesystem]["/dev/mapper/sys.vg-special.lv"][:kb_available].should be == "44041805"
    end

    it "should set percent_used to value from df -P" do
      @plugin.run
      @plugin[:filesystem]["/dev/mapper/sys.vg-special.lv"][:percent_used].should be == "56%"
    end

    it "should set mount to value from df -P" do
      @plugin.run
      @plugin[:filesystem]["/dev/mapper/sys.vg-special.lv"][:mount].should be == "/special"
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
      @plugin.stub(:shell_out).with("mount").and_return(mock_shell_out(0, @stdout, ""))
    end

    it "should run mount" do
      @plugin.should_receive(:shell_out).with("mount").and_return(mock_shell_out(0, @stdout, ""))
      @plugin.run
    end

    it "should set mount to value from mount" do
      @plugin.run
      @plugin[:filesystem]["/dev/mapper/sys.vg-special.lv"][:mount].should be == "/special"
    end

    it "should set fs_type to value from mount" do
      @plugin.run
      @plugin[:filesystem]["/dev/mapper/sys.vg-special.lv"][:fs_type].should be == "xfs"
    end

    it "should set mount_options to an array of values from mount" do
      @plugin.run
      @plugin[:filesystem]["/dev/mapper/sys.vg-special.lv"][:mount_options].should be == [ "ro", "noatime" ]
    end
  end

  describe "when gathering filesystem type data from blkid" do
    before(:each) do
      @stdout = <<-BLKID_TYPE
dev/sdb1: TYPE=\"linux_raid_member\" 
/dev/sdb2: TYPE=\"linux_raid_member\" 
/dev/sda1: TYPE=\"linux_raid_member\" 
/dev/sda2: TYPE=\"linux_raid_member\" 
/dev/md0: TYPE=\"ext3\" 
/dev/md1: TYPE=\"LVM2_member\" 
/dev/mapper/sys.vg-root.lv: TYPE=\"ext4\" 
/dev/mapper/sys.vg-swap.lv: TYPE=\"swap\" 
/dev/mapper/sys.vg-tmp.lv: TYPE=\"ext4\" 
/dev/mapper/sys.vg-usr.lv: TYPE=\"ext4\" 
/dev/mapper/sys.vg-var.lv: TYPE=\"ext4\" 
/dev/mapper/sys.vg-home.lv: TYPE=\"xfs\" 
BLKID_TYPE
      @plugin.stub(:shell_out).with("blkid -s TYPE").and_return(mock_shell_out(0, @stdout, ""))
    end

    it "should run blkid -s TYPE" do
      @plugin.should_receive(:shell_out).with("blkid -s TYPE").and_return(mock_shell_out(0, @stdout, ""))
      @plugin.run
    end

    it "should set kb_size to value from blkid -s TYPE" do
      @plugin.run
      @plugin[:filesystem]["/dev/md1"][:fs_type].should be == "LVM2_member"
    end
  end

  describe "when gathering filesystem uuid data from blkid" do
    before(:each) do
      @stdout = <<-BLKID_UUID
/dev/sdb1: UUID=\"bd1197e0-6997-1f3a-e27e-7801388308b5\" 
/dev/sdb2: UUID=\"e36d933e-e5b9-cfe5-6845-1f84d0f7fbfa\" 
/dev/sda1: UUID=\"bd1197e0-6997-1f3a-e27e-7801388308b5\" 
/dev/sda2: UUID=\"e36d933e-e5b9-cfe5-6845-1f84d0f7fbfa\" 
/dev/md0: UUID=\"37b8de8e-0fe3-4b5a-b9b4-dde33e19bb32\" 
/dev/md1: UUID=\"YsIe0R-fj1y-LXTd-imla-opKo-OuIe-TBoxSK\" 
/dev/mapper/sys.vg-root.lv: UUID=\"7742d14b-80a3-4e97-9a32-478be9ea9aea\" 
/dev/mapper/sys.vg-swap.lv: UUID=\"9bc2e515-8ddc-41c3-9f63-4eaebde9ce96\" 
/dev/mapper/sys.vg-tmp.lv: UUID=\"74cf7eb9-428f-479e-9a4a-9943401e81e5\" 
/dev/mapper/sys.vg-usr.lv: UUID=\"26ec33c5-d00b-4f88-a550-492def013bbc\" 
/dev/mapper/sys.vg-var.lv: UUID=\"6b559c35-7847-4ae2-b512-c99012d3f5b3\" 
/dev/mapper/sys.vg-home.lv: UUID=\"d6efda02-1b73-453c-8c74-7d8dee78fa5e\" 
BLKID_UUID
      @plugin.stub(:shell_out).with("blkid -s UUID").and_return(mock_shell_out(0, @stdout, ""))
    end

    it "should run blkid -s UUID" do
      @plugin.should_receive(:shell_out).with("blkid -s UUID").and_return(mock_shell_out(0, @stdout, ""))
      @plugin.run
    end

    it "should set kb_size to value from blkid -s UUID" do
      @plugin.run
      @plugin[:filesystem]["/dev/sda2"][:uuid].should be == "e36d933e-e5b9-cfe5-6845-1f84d0f7fbfa"
    end
  end

  describe "when gathering filesystem label data from blkid" do
    before(:each) do
      @stdout = <<-BLKID_LABEL
/dev/sda1: LABEL=\"fuego:0\" 
/dev/sda2: LABEL=\"fuego:1\" 
/dev/sdb1: LABEL=\"fuego:0\" 
/dev/sdb2: LABEL=\"fuego:1\" 
/dev/md0: LABEL=\"/boot\" 
/dev/mapper/sys.vg-root.lv: LABEL=\"/\" 
/dev/mapper/sys.vg-tmp.lv: LABEL=\"/tmp\" 
/dev/mapper/sys.vg-usr.lv: LABEL=\"/usr\" 
/dev/mapper/sys.vg-var.lv: LABEL=\"/var\" 
/dev/mapper/sys.vg-home.lv: LABEL=\"/home\" 
BLKID_LABEL
      @plugin.stub(:shell_out).with("blkid -s LABEL").and_return(mock_shell_out(0, @stdout, ""))
    end

    it "should run blkid -s LABEL" do
      @plugin.should_receive(:shell_out).with("blkid -s LABEL").and_return(mock_shell_out(0, @stdout, ""))
      @plugin.run
    end

    it "should set kb_size to value from blkid -s LABEL" do
      @plugin.run
      @plugin[:filesystem]["/dev/md0"][:label].should be == "/boot"
    end
  end

  describe "when gathering data from /proc/mounts" do
    before(:each) do
      File.stub(:exists?).with("/proc/mounts").and_return(true)
      @double_file = double("/proc/mounts")
      @double_file.stub(:read_nonblock).and_return(@double_file)
      @double_file.stub(:each_line).
        and_yield("rootfs / rootfs rw 0 0").
        and_yield("none /sys sysfs rw,nosuid,nodev,noexec,relatime 0 0").
        and_yield("none /proc proc rw,nosuid,nodev,noexec,relatime 0 0").
        and_yield("none /dev devtmpfs rw,relatime,size=2025576k,nr_inodes=506394,mode=755 0 0").
        and_yield("none /dev/pts devpts rw,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=000 0 0").
        and_yield("/dev/mapper/sys.vg-root.lv / ext4 rw,noatime,errors=remount-ro,barrier=1,data=ordered 0 0").
        and_yield("tmpfs /lib/init/rw tmpfs rw,nosuid,relatime,mode=755 0 0").
        and_yield("tmpfs /dev/shm tmpfs rw,nosuid,nodev,relatime 0 0").
        and_yield("/dev/mapper/sys.vg-home.lv /home xfs rw,noatime,attr2,noquota 0 0").
        and_yield("/dev/mapper/sys.vg-special.lv /special xfs ro,noatime,attr2,noquota 0 0").
        and_yield("/dev/mapper/sys.vg-tmp.lv /tmp ext4 rw,noatime,barrier=1,data=ordered 0 0").
        and_yield("/dev/mapper/sys.vg-usr.lv /usr ext4 rw,noatime,barrier=1,data=ordered 0 0").
        and_yield("/dev/mapper/sys.vg-var.lv /var ext4 rw,noatime,barrier=1,data=ordered 0 0").
        and_yield("/dev/md0 /boot ext3 rw,noatime,errors=remount-ro,data=ordered 0 0").
        and_yield("fusectl /sys/fs/fuse/connections fusectl rw,relatime 0 0").
        and_yield("binfmt_misc /proc/sys/fs/binfmt_misc binfmt_misc rw,nosuid,nodev,noexec,relatime 0 0")
      File.stub(:open).with("/proc/mounts").and_return(@double_file)
    end

    it "should set mount to value from /proc/mounts" do
      @plugin.run
      @plugin[:filesystem]["/dev/mapper/sys.vg-special.lv"][:mount].should be == "/special"
    end
  
    it "should set fs_type to value from /proc/mounts" do
      @plugin.run
      @plugin[:filesystem]["/dev/mapper/sys.vg-special.lv"][:fs_type].should be == "xfs"
    end
  
    it "should set mount_options to an array of values from /proc/mounts" do
      @plugin.run
      @plugin[:filesystem]["/dev/mapper/sys.vg-special.lv"][:mount_options].should be == [ "ro", "noatime", "attr2", "noquota" ]
    end
  end

end
