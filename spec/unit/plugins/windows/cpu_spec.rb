#
# Author:: Salim Alam (<salam@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Inc.
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

shared_examples "a cpu" do |cpu_no|
  describe "cpu #{cpu_no}" do
    it "should set physical_id to CPU#{cpu_no}" do
      expect(@plugin[:cpu]["#{cpu_no}"][:physical_id]).to eq("CPU#{cpu_no}")
    end

    it "should set mhz to 2793" do
      expect(@plugin[:cpu]["#{cpu_no}"][:mhz]).to eq("2793")
    end

    it "should set vendor_id to GenuineIntel" do
      expect(@plugin[:cpu]["#{cpu_no}"][:vendor_id]).to eq("GenuineIntel")
    end

    it "should set model_name to Intel(R) Core(TM) i7-4500U CPU @ 1.80GHz" do
      expect(@plugin[:cpu]["#{cpu_no}"][:model_name])
        .to eq("Intel(R) Core(TM) i7-4500U CPU @ 1.80GHz")
    end

    it "should set description to Intel64 Family 6 Model 70 Stepping 1" do
      expect(@plugin[:cpu]["#{cpu_no}"][:description])
        .to eq("Intel64 Family 6 Model 70 Stepping 1")
    end

    it "should set model to 17921" do
      expect(@plugin[:cpu]["#{cpu_no}"][:model]).to eq("17921")
    end

    it "should set family to 2" do
      expect(@plugin[:cpu]["#{cpu_no}"][:family]).to eq("2")
    end

    it "should set stepping to 9" do
      expect(@plugin[:cpu]["#{cpu_no}"][:stepping]).to eq(9)
    end

    it "should set cache_size to 64 KB" do
      expect(@plugin[:cpu]["#{cpu_no}"][:cache_size]).to eq("64 KB")
    end
  end
end

describe Ohai::System, "Windows cpu plugin" do
  before(:each) do
    @plugin = get_plugin("windows/cpu")
    allow(@plugin).to receive(:collect_os).and_return(:windows)

    @double_wmi = double(WmiLite::Wmi)
    @double_wmi_instance = instance_double(WmiLite::Wmi)

    @processors = [{ "description" => "Intel64 Family 6 Model 70 Stepping 1",
                     "name" => "Intel(R) Core(TM) i7-4500U CPU @ 1.80GHz",
                     "deviceid" => "CPU0",
                     "family" => 2,
                     "manufacturer" => "GenuineIntel",
                     "maxclockspeed" => 2793,
                     "numberofcores" => 1,
                     "numberoflogicalprocessors" => 2,
                     "revision" => 17_921,
                     "stepping" => 9,
                     "l2cachesize" => 64 },

                   { "description" => "Intel64 Family 6 Model 70 Stepping 1",
                     "name" => "Intel(R) Core(TM) i7-4500U CPU @ 1.80GHz",
                     "deviceid" => "CPU1",
                     "family" => 2,
                     "manufacturer" => "GenuineIntel",
                     "maxclockspeed" => 2793,
                     "numberofcores" => 1,
                     "numberoflogicalprocessors" => 2,
                     "revision" => 17_921,
                     "stepping" => 9,
                     "l2cachesize" => 64 }]

    allow(WmiLite::Wmi).to receive(:new).and_return(@double_wmi_instance)

    allow(@double_wmi_instance).to receive(:instances_of)
      .with("Win32_Processor")
      .and_return(@processors)

    @plugin.run
  end

  it "should set total cpu to 2" do
    expect(@plugin[:cpu][:total]).to eq(4)
  end

  it "should set real cpu to 2" do
    expect(@plugin[:cpu][:real]).to eq(2)
  end

  it "should set 2 distinct cpus numbered 0 and 1" do
    expect(@plugin[:cpu]).to have_key("0")
    expect(@plugin[:cpu]).to have_key("1")
  end

  it_behaves_like "a cpu", 0
  it_behaves_like "a cpu", 1
end
