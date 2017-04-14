#
#  Author:: Tim Smith <tsmith@limelight.com>
#  Copyright:: Copyright (c) 2014 Limelight Networks, Inc.
#  License:: Apache License, Version 2.0
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require_relative "../../../spec_helper.rb"

describe Ohai::System, "Linux Mdadm Plugin" do
  before(:each) do
    @md0 = <<-MD
/dev/md0:
        Version : 1.2
  Creation Time : Thu Jan 30 03:11:40 2014
     Raid Level : raid10
     Array Size : 2929893888 (2794.16 GiB 3000.21 GB)
  Used Dev Size : 976631296 (931.39 GiB 1000.07 GB)
   Raid Devices : 6
  Total Devices : 6
    Persistence : Superblock is persistent

    Update Time : Tue May  6 23:30:32 2014
          State : clean
 Active Devices : 6
Working Devices : 6
 Failed Devices : 0
  Spare Devices : 0

         Layout : near=2
     Chunk Size : 256K

           Name : host.therealtimsmith.com:3  (local to host host.therealtimsmith.com)
           UUID : 5ed74d5b:70bfe21d:8cd57792:c1e13d65
         Events : 155

    Number   Major   Minor   RaidDevice State
       0       8       32        0      active sync   /dev/sdc
       1       8       48        1      active sync   /dev/sdd
       2       8       64        2      active sync   /dev/sde
       3       8       80        3      active sync   /dev/sdf
       4       8       96        4      active sync   /dev/sdg
       5       8      112        5      active sync   /dev/sdh
MD
    @plugin = get_plugin("linux/mdadm")
    allow(@plugin).to receive(:collect_os).and_return(:linux)
    @double_file = double("/proc/mdstat")
    allow(@double_file).to receive(:each).
      and_yield("Personalities : [raid1] [raid6] [raid5] [raid4] [linear] [multipath] [raid0] [raid10]").
      and_yield("md0 : active raid10 sdh[5] sdg[4] sdf[3] sde[2] sdd[1] sdc[0]").
      and_yield("      2929893888 blocks super 1.2 256K chunks 2 near-copies [6/6] [UUUUUU]")
    allow(File).to receive(:open).with("/proc/mdstat").and_return(@double_file)
    allow(File).to receive(:exist?).with("/proc/mdstat").and_return(true)
    allow(@plugin).to receive(:shell_out).with("mdadm --detail /dev/md0").and_return(mock_shell_out(0, @md0, ""))
  end

  describe "gathering Mdadm information via /proc/mdstat and mdadm" do

    it "should not raise an error" do
      expect { @plugin.run }.not_to raise_error
    end

    it "should detect raid level" do
      @plugin.run
      expect(@plugin[:mdadm][:md0][:level]).to eq(10)
    end

    it "should detect raid state" do
      @plugin.run
      expect(@plugin[:mdadm][:md0][:state]).to eq("clean")
    end

    it "should detect raid size" do
      @plugin.run
      expect(@plugin[:mdadm][:md0][:size]).to eq(2794.16)
    end

    it "should detect raid metadata level" do
      @plugin.run
      expect(@plugin[:mdadm][:md0][:version]).to eq(1.2)
    end

    device_counts = { :raid => 6, :total => 6, :active => 6, :working => 6, :failed => 0, :spare => 0 }
    device_counts.each_pair do |item, expected_value|
      it "should detect device count of \"#{item}\"" do
        @plugin.run
        expect(@plugin[:mdadm][:md0][:device_counts][item]).to eq(expected_value)
      end
    end

    it "should detect member devies" do
      @plugin.run
      expect(@plugin[:mdadm][:md0][:members].sort).to eq(
        %w{sdc sdd sde sdf sdg sdh}
      )
    end
  end

end
