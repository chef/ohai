#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "AIX cpu plugin" do
  before(:each) do
    @lsdev_cc_processor = <<-LSDEV_CC_PROCESSOR
proc0 Available 00-00 Processor
proc4 Defined   00-04 Processor
LSDEV_CC_PROCESSOR

    @lsattr_el_proc0 = <<-LSATTR_EL
frequency   1654344000     Processor Speed       False
smt_enabled true           Processor SMT enabled False
smt_threads 2              Processor SMT threads False
state       enable         Processor state       False
type        PowerPC_POWER5 Processor type        False
LSATTR_EL

    @pmcycles_m = <<-PMCYCLES_M
CPU 0 runs at 1654 MHz
CPU 1 runs at 1654 MHz
CPU 2 runs at 1654 MHz
CPU 3 runs at 1654 MHz
PMCYCLES_M

    @plugin = get_plugin("aix/cpu")
    allow(@plugin).to receive(:collect_os).and_return(:aix)

    allow(@plugin).to receive(:shell_out).with("lsdev -Cc processor").and_return(mock_shell_out(0, @lsdev_cc_processor, nil))
    allow(@plugin).to receive(:shell_out).with("lsattr -El proc0").and_return(mock_shell_out(0, @lsattr_el_proc0, nil))
    allow(@plugin).to receive(:shell_out).with("pmcycles -m").and_return(mock_shell_out(0, @pmcycles_m, nil))
  end

  context "when run on an LPAR" do
    before do
      allow(@plugin).to receive(:shell_out).with("uname -W").and_return(mock_shell_out(0, "0", nil))
      @plugin.run
    end

    it "sets the vendor id to IBM" do
      expect(@plugin[:cpu]["0"][:vendor_id]).to eq("IBM")
    end

    it "sets the available attribute" do
      expect(@plugin[:cpu][:available]).to eq(1)
    end

    it "sets the total number of processors" do
      expect(@plugin[:cpu][:total]).to eq(4)
    end

    it "sets the real number of processors" do
      expect(@plugin[:cpu][:real]).to eq(2)
    end

    it "sets the number of cores" do
      #from http://www-01.ibm.com/software/passportadvantage/pvu_terminology_for_customers.html
      #on AIX number of cores and processors are considered same
      expect(@plugin[:cpu][:cores]).to eq(@plugin[:cpu][:real])
    end

    it "detects the model" do
      expect(@plugin[:cpu]["0"][:model_name]).to eq("PowerPC_POWER5")
    end

    it "detects the mhz" do
      expect(@plugin[:cpu]["0"][:mhz]).to eq(1654)
    end

    it "detects the status of the device" do
      expect(@plugin[:cpu]["0"][:status]).to eq("Available")
    end

    it "detects the location of the device" do
      expect(@plugin[:cpu]["0"][:location]).to eq("00-00")
    end

    context "lsattr -El device_name" do
      it "detects all the attributes of the device" do
        expect(@plugin[:cpu]["0"][:mhz]).to eq(1654)
        expect(@plugin[:cpu]["0"][:smt_enabled]).to eq("true")
        expect(@plugin[:cpu]["0"][:smt_threads]).to eq("2")
        expect(@plugin[:cpu]["0"][:state]).to eq("enable")
        expect(@plugin[:cpu]["0"][:model_name]).to eq("PowerPC_POWER5")
      end
    end
  end

  context "when run on a WPAR" do
    before do
      allow(@plugin).to receive(:shell_out).with("uname -W").and_return(mock_shell_out(0, "120", nil))
      @plugin.run
    end

    it "sets the total number of processors" do
      expect(@plugin[:cpu][:total]).to eq(4)
    end

    it "doesn't set the real number of CPUs" do
      expect(@plugin[:cpu][:real]).to be_nil
    end

    it "doesn't set mhz of a processor it can't see" do
      # I'm so sorry
      expect do
        expect(@plugin[:cpu]["0"][:mhz]).to eq(1654)
      end.to raise_error(NoMethodError)
    end
  end
end
