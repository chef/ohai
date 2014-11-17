#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "AIX cpu plugin" do
  before(:each) do
    @lsdev_Cc_processor = <<-LSDEV_CC_PROCESSOR
proc0 Available 00-00 Processor
proc4 Defined   00-04 Processor
LSDEV_CC_PROCESSOR

    @lsattr_El_proc0 = <<-LSATTR_EL
frequency   1654344000     Processor Speed       False
smt_enabled true           Processor SMT enabled False
smt_threads 2              Processor SMT threads False
state       enable         Processor state       False
type        PowerPC_POWER5 Processor type        False
LSATTR_EL
    @plugin = get_plugin("aix/cpu")
    allow(@plugin).to receive(:collect_os).and_return(:aix)

    allow(@plugin).to receive(:shell_out).with("lsdev -Cc processor").and_return(mock_shell_out(0, @lsdev_Cc_processor, nil))
    allow(@plugin).to receive(:shell_out).with("lsattr -El proc0").and_return(mock_shell_out(0, @lsattr_El_proc0, nil))
    @plugin.run
  end


  it "sets the vendor id to IBM" do
    expect(@plugin[:cpu][:vendor_id]).to eq("IBM")
  end

  it "sets the available attribute" do
    expect(@plugin[:cpu][:available]).to eq(1)
  end

  it "sets the total number of devices" do
    expect(@plugin[:cpu][:total]).to eq(2)
  end

  it "detects the model" do
    expect(@plugin[:cpu][:model]).to eq("PowerPC_POWER5")
  end

  it "detects the mhz" do
    expect(@plugin[:cpu][:mhz]).to eq(1615570)
  end

  it "detects the status of the device" do
    expect(@plugin[:cpu][:proc0][:status]).to eq("Available")
  end

  it "detects the location of the device" do
    expect(@plugin[:cpu][:proc0][:location]).to eq("00-00")
  end

  context "lsattr -El device_name" do
    it "detects all the attributes of the device" do
      expect(@plugin[:cpu][:proc0][:frequency]).to eq("1654344000")
      expect(@plugin[:cpu][:proc0][:smt_enabled]).to eq("true")
      expect(@plugin[:cpu][:proc0][:smt_threads]).to eq("2")
      expect(@plugin[:cpu][:proc0][:state]).to eq("enable")
      expect(@plugin[:cpu][:proc0][:type]).to eq("PowerPC_POWER5")
    end
  end
end
