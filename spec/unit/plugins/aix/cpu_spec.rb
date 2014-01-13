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
    @plugin.stub(:collect_os).and_return(:aix)

    @plugin.stub(:shell_out).with("lsdev -Cc processor").and_return(mock_shell_out(0, @lsdev_Cc_processor, nil))
    @plugin.stub(:shell_out).with("lsattr -El proc0").and_return(mock_shell_out(0, @lsattr_El_proc0, nil))
    @plugin.run
  end


  it "sets the vendor id to IBM" do
    @plugin[:cpu][:vendor_id].should == "IBM"
  end

  it "sets the available attribute" do
    @plugin[:cpu][:available].should == 1
  end

  it "sets the total number of devices" do
    @plugin[:cpu][:total].should == 2
  end

  it "detects the model" do
    @plugin[:cpu][:model].should == "PowerPC_POWER5"
  end

  it "detects the mhz" do
    @plugin[:cpu][:mhz].should == 1615570
  end

  it "detects the status of the device" do
    @plugin[:cpu][:proc0][:status].should == "Available"
  end

  it "detects the location of the device" do
    @plugin[:cpu][:proc0][:location].should == "00-00"
  end

  context "lsattr -El device_name" do
    it "detects all the attributes of the device" do
      @plugin[:cpu][:proc0][:frequency].should == "1654344000"
      @plugin[:cpu][:proc0][:smt_enabled].should == "true"
      @plugin[:cpu][:proc0][:smt_threads].should == "2"
      @plugin[:cpu][:proc0][:state].should == "enable"
      @plugin[:cpu][:proc0][:type].should == "PowerPC_POWER5"
    end
  end
end
