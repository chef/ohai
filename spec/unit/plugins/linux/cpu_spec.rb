#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Ohai::System, "Linux cpu plugin" do
  before(:each) do
    @plugin = get_plugin("linux/cpu")
    allow(@plugin).to receive(:collect_os).and_return(:linux)
    @double_file = double("/proc/cpuinfo")
    allow(@double_file).to receive(:each).
      and_yield("processor     : 0").
      and_yield("vendor_id     : GenuineIntel").
      and_yield("cpu family    : 6").
      and_yield("model         : 23").
      and_yield("model name    : Intel(R) Core(TM)2 Duo CPU     T8300   @ 2.40GHz").
      and_yield("stepping      : 6").
      and_yield("cpu MHz       : 1968.770").
      and_yield("cache size    : 64 KB").
      and_yield("fdiv_bug      : no").
      and_yield("hlt_bug       : no").
      and_yield("f00f_bug      : no").
      and_yield("coma_bug      : no").
      and_yield("fpu           : yes").
      and_yield("fpu_exception : yes").
      and_yield("cpuid level   : 10").
      and_yield("wp            : yes").
      and_yield("flags         : fpu pse tsc msr mce cx8 sep mtrr pge cmov").
      and_yield("bogomips      : 2575.86").
      and_yield("clflush size  : 32")
    allow(File).to receive(:open).with("/proc/cpuinfo").and_return(@double_file)
  end
  
  it "should set cpu[:total] to 1" do
    @plugin.run
    expect(@plugin[:cpu][:total]).to eq(1)
  end
  
  it "should set cpu[:real] to 0" do
    @plugin.run
    expect(@plugin[:cpu][:real]).to eq(0)
  end
  
  it "should have a cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]).to have_key("0")
  end
  
  it "should have a vendor_id for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("vendor_id")
    expect(@plugin[:cpu]["0"]["vendor_id"]).to eql("GenuineIntel")
  end
  
  it "should have a family for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("family")
    expect(@plugin[:cpu]["0"]["family"]).to eql("6")
  end
  
  it "should have a model for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("model")
    expect(@plugin[:cpu]["0"]["model"]).to eql("23")
  end
  
  it "should have a stepping for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("stepping")
    expect(@plugin[:cpu]["0"]["stepping"]).to eql("6")
  end
  
  it "should not have a phyiscal_id for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).not_to have_key("physical_id")
  end
  
  it "should not have a core_id for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).not_to have_key("core_id")
  end
  
  it "should not have a cores for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).not_to have_key("cores")
  end
  
  it "should have a model name for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("model_name")
    expect(@plugin[:cpu]["0"]["model_name"]).to eql("Intel(R) Core(TM)2 Duo CPU     T8300   @ 2.40GHz")
  end
  
  it "should have a mhz for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("mhz")
    expect(@plugin[:cpu]["0"]["mhz"]).to eql("1968.770")
  end
  
  it "should have a cache_size for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("cache_size")
    expect(@plugin[:cpu]["0"]["cache_size"]).to eql("64 KB")
  end
  
  it "should have flags for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("flags")
    expect(@plugin[:cpu]["0"]["flags"]).to eq(%w{fpu pse tsc msr mce cx8 sep mtrr pge cmov})
  end
end
