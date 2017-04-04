#
# Author:: Phil Dibowitz (<phil@ipom.com>)
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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "darwin filesystem plugin" do
  let (:plugin) { get_plugin("darwin/filesystem") }
  before(:each) do
    allow(plugin).to receive(:collect_os).and_return(:darwin)

    allow(plugin).to receive(:shell_out).with("df -i").and_return(mock_shell_out(0, "", ""))
    allow(plugin).to receive(:shell_out).with("mount").and_return(mock_shell_out(0, "", ""))
  end

  it "sets both filesystem and filesystem2 attributes" do
    plugin.run
    expect(plugin[:filesystem]).to eq(plugin[:filesystem2])
  end

  describe "when gathering filesystem usage data from df" do
    before(:each) do
      @stdout = <<-DF
Filesystem           512-blocks      Used Available Capacity  iused    ifree %iused  Mounted on
/dev/disk0s2          488555536 313696448 174347088    65% 39276054 21793386   64%   /
devfs                       385       385         0   100%      666        0  100%   /dev
map /etc/auto.direct          0         0         0   100%        0        0  100%   /mnt/vol
map -hosts                    0         0         0   100%        0        0  100%   /net
map -static                   0         0         0   100%        0        0  100%   /mobile_symbol
deweyfs@osxfuse0              0         0         0   100%        0        0  100%   /mnt/dewey
DF
      allow(plugin).to receive(:shell_out).with("df -i").and_return(mock_shell_out(0, @stdout, ""))
    end

    it "should run df -i" do
      expect(plugin).to receive(:shell_out).ordered.with("df -i").and_return(mock_shell_out(0, @stdout, ""))
      plugin.run
    end

    it "should set size to value from df -i" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/disk0s2,/"][:kb_size]).to eq("244277768")
      expect(plugin[:filesystem]["by_pair"]["/dev/disk0s2,/"][:kb_used]).to eq("156848224")
      expect(plugin[:filesystem]["by_pair"]["/dev/disk0s2,/"][:kb_available]).to eq("87173544")
      expect(plugin[:filesystem]["by_pair"]["/dev/disk0s2,/"][:percent_used]).to eq("65%")
    end

    it "should set device and mount to value from df -i" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/disk0s2,/"][:mount]).to eq("/")
      expect(plugin[:filesystem]["by_pair"]["/dev/disk0s2,/"][:device]).to eq("/dev/disk0s2")
    end

    it "should set inode info to value from df -i" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/disk0s2,/"][:total_inodes]).to eq("61069440")
      expect(plugin[:filesystem]["by_pair"]["/dev/disk0s2,/"][:inodes_used]).to eq("39276054")
      expect(plugin[:filesystem]["by_pair"]["/dev/disk0s2,/"][:inodes_available]).to eq("21793386")
    end
  end

  describe "when gathering mounted filesystem data from mount" do
    before(:each) do
      @stdout = <<-MOUNT
/dev/disk0s2 on / (hfs, local, journaled)
devfs on /dev (devfs, local, nobrowse)
map /etc/auto.direct on /mnt/vol (autofs, automounted, nobrowse)
map -hosts on /net (autofs, nosuid, automounted, nobrowse)
map -static on /mobile_symbol (autofs, automounted, nobrowse)
deweyfs@osxfuse0 on /mnt/dewey (osxfusefs, synchronous, nobrowse)
MOUNT
      allow(plugin).to receive(:shell_out).with("mount").and_return(mock_shell_out(0, @stdout, ""))
    end

    it "should run mount" do
      expect(plugin).to receive(:shell_out).with("mount").and_return(mock_shell_out(0, @stdout, ""))
      plugin.run
    end

    it "should set values from mount" do
      plugin.run
      expect(plugin[:filesystem]["by_pair"]["/dev/disk0s2,/"][:mount]).to eq("/")
      expect(plugin[:filesystem]["by_pair"]["/dev/disk0s2,/"][:fs_type]).to eq("hfs")
      expect(plugin[:filesystem]["by_pair"]["/dev/disk0s2,/"][:mount_options]).to eq(%w{local journaled})
    end
  end

  describe "when gathering filesystem data with devices mounted more than once" do
    before(:each) do
      @dfstdout = <<-DF
Filesystem           512-blocks      Used Available Capacity  iused    ifree %iused  Mounted on
/dev/disk0s2          488555536 313696448 174347088    65% 39276054 21793386   64%   /
devfs                       385       385         0   100%      666        0  100%   /dev
map /etc/auto.direct          0         0         0   100%        0        0  100%   /mnt/vol
map -hosts                    0         0         0   100%        0        0  100%   /net
map -static                   0         0         0   100%        0        0  100%   /mobile_symbol
deweyfs@osxfuse0              0         0         0   100%        0        0  100%   /mnt/dewey
/dev/disk0s2          488555536 313696448 174347088    65% 39276054 21793386 64%   /another/mountpoint
DF
      allow(plugin).to receive(:shell_out).with("df -i").and_return(mock_shell_out(0, @dfstdout, ""))
    end

    it "should provide a devices view with all mountpoints" do
      plugin.run
      expect(plugin[:filesystem]["by_device"]["/dev/disk0s2"][:mounts]).to eq(["/", "/another/mountpoint"])
    end
  end

  describe "when gathering filesystem data with double-mounts" do
    before(:each) do
      @dfstdout = <<-DF
Filesystem           512-blocks      Used Available Capacity  iused    ifree %iused  Mounted on
/dev/disk0s2          488555536 313696448 174347088    65% 39276054 21793386   64%   /
devfs                       385       385         0   100%      666        0  100%   /dev
map /etc/auto.direct          0         0         0   100%        0        0  100%   /mnt/vol
map -hosts                    0         0         0   100%        0        0  100%   /net
map -static                   0         0         0   100%        0        0  100%   /mobile_symbol
deweyfs@osxfuse0              0         0         0   100%        0        0  100%   /mnt/dewey
/dev/disk0s3          488555536 313696448 174347088    65% 39276054 21793386 64% /mnt
/dev/disk0s4          488555536 313696448 174347088    65% 39276054 21793386 64% /mnt
DF
      allow(plugin).to receive(:shell_out).with("df -i").and_return(mock_shell_out(0, @dfstdout, ""))
    end

    it "should provide a mounts view with all devices" do
      plugin.run
      expect(plugin[:filesystem]["by_mountpoint"]["/mnt"][:devices]).to eq(["/dev/disk0s3", "/dev/disk0s4"])
    end
  end
end
