#
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Author:: Tim Smith (<tsmith@chef.io>)
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

describe Ohai::System, "BSD filesystem plugin" do
  let(:plugin) { get_plugin("bsd/filesystem") }
  before(:each) do
    allow(plugin).to receive(:collect_os).and_return(:freebsd)

    allow(plugin).to receive(:shell_out).with("df").and_return(mock_shell_out(0, "", ""))
    allow(plugin).to receive(:shell_out).with("df -iP").and_return(mock_shell_out(0, "", ""))
    allow(plugin).to receive(:shell_out).with("mount -l").and_return(mock_shell_out(0, "", ""))
  end

  describe "when gathering filesystem usage data from df" do
    before(:each) do
      @stdout = <<-DF
Filesystem  1K-blocks    Used   Avail Capacity  Mounted on
/dev/ada0p2   9637788 3313504 5553264    37%    /
devfs               1       1       0   100%    /dev
DF
      allow(plugin).to receive(:shell_out).with("df").and_return(mock_shell_out(0, @stdout, ""))

      @inode_stdout = <<-DFi
Filesystem  512-blocks    Used   Avail Capacity iused  ifree %iused  Mounted on
/dev/ada0p2   15411832 5109256 9069632    36%  252576 790750   24%   /
devfs                2       2       0   100%       0      0  100%   /dev
DFi
      allow(plugin).to receive(:shell_out).with("df -iP").and_return(mock_shell_out(0, @inode_stdout, ""))
    end

    it "should run df and df -iP" do
      expect(plugin).to receive(:shell_out).ordered.with("df").and_return(mock_shell_out(0, @stdout, ""))
      expect(plugin).to receive(:shell_out).ordered.with("df -iP").and_return(mock_shell_out(0, @inode_stdout, ""))
      plugin.run
    end

    it "should set kb_size to value from df" do
      plugin.run
      expect(plugin[:filesystem]["/dev/ada0p2"][:kb_size]).to eq("9637788")
    end

    it "should set kb_used to value from df" do
      plugin.run
      expect(plugin[:filesystem]["/dev/ada0p2"][:kb_used]).to eq("3313504")
    end

    it "should set kb_available to value from df" do
      plugin.run
      expect(plugin[:filesystem]["/dev/ada0p2"][:kb_available]).to eq("5553264")
    end

    it "should set percent_used to value from df" do
      plugin.run
      expect(plugin[:filesystem]["/dev/ada0p2"][:percent_used]).to eq("37%")
    end

    it "should set mount to value from df" do
      plugin.run
      expect(plugin[:filesystem]["/dev/ada0p2"][:mount]).to eq("/")
    end

    it "should set total_inodes to value from df -iP" do
      plugin.run
      expect(plugin[:filesystem]["/dev/ada0p2"][:total_inodes]).to eq("1043326")
    end

    it "should set inodes_used to value from df -iP" do
      plugin.run
      expect(plugin[:filesystem]["/dev/ada0p2"][:inodes_used]).to eq("252576")
    end

    it "should set inodes_available to value from df -iP" do
      plugin.run
      expect(plugin[:filesystem]["/dev/ada0p2"][:inodes_available]).to eq("790750")
    end
  end

  describe "when gathering mounted filesystem data from mount" do
    before(:each) do
      @stdout = <<-MOUNT
/dev/ada0p2 on / (ufs, local, journaled soft-updates)
devfs on /dev (devfs, local, multilabel)
MOUNT
      allow(plugin).to receive(:shell_out).with("mount -l").and_return(mock_shell_out(0, @stdout, ""))
    end

    it "should run mount" do
      expect(plugin).to receive(:shell_out).with("mount -l").and_return(mock_shell_out(0, @stdout, ""))
      plugin.run
    end

    it "should set mount to value from mount" do
      plugin.run
      expect(plugin[:filesystem]["/dev/ada0p2"][:mount]).to eq("/")
    end

    it "should set fs_type to value from mount" do
      plugin.run
      expect(plugin[:filesystem]["/dev/ada0p2"][:fs_type]).to eq("ufs")
    end

    it "should set mount_options to an array of values from mount" do
      plugin.run
      expect(plugin[:filesystem]["/dev/ada0p2"][:mount_options]).to eq(["local", "journaled soft-updates"])
    end
  end

end
