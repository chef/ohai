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

shared_examples "Common cpu info" do |total_cpu, real_cpu|
  describe "cpu" do
    it "has cpu[:total] equals to #{total_cpu}" do
      @plugin.run
      expect(@plugin[:cpu][:total]).to eq(total_cpu)
    end

    it "has cpu[:real] equals to #{real_cpu}" do
      @plugin.run
      expect(@plugin[:cpu][:real]).to eq(real_cpu)
    end

    it "has a cpu 0" do
      @plugin.run
      expect(@plugin[:cpu]).to have_key("0")
    end
  end
end

shared_examples "S390 processor info" do |cpu_no, version, identification, machine|
  describe "S390 processor" do
    it "has a version for cpu #{cpu_no}" do
      @plugin.run
      expect(@plugin[:cpu]["#{cpu_no}"]).to have_key("version")
      expect(@plugin[:cpu]["#{cpu_no}"]["version"]).to eql(version)
    end

    it "has a identification for cpu #{cpu_no}" do
      @plugin.run
      expect(@plugin[:cpu]["#{cpu_no}"]).to have_key("identification")
      expect(@plugin[:cpu]["#{cpu_no}"]["identification"]).to eql(identification)
    end

    it "has a machine for cpu #{cpu_no}" do
      @plugin.run
      expect(@plugin[:cpu]["#{cpu_no}"]).to have_key("machine")
      expect(@plugin[:cpu]["#{cpu_no}"]["machine"]).to eql(machine)
    end
  end
end 

describe Ohai::System, "General Linux cpu plugin" do
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
  
  it_behaves_like "Common cpu info", 1, 0

  it "doesn't have a cpu 1" do
    @plugin.run
    expect(@plugin[:cpu]).not_to have_key("1")
  end

  it "has a vendor_id for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("vendor_id")
    expect(@plugin[:cpu]["0"]["vendor_id"]).to eql("GenuineIntel")
  end

  it "has a family for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("family")
    expect(@plugin[:cpu]["0"]["family"]).to eql("6")
  end

  it "has a model for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("model")
    expect(@plugin[:cpu]["0"]["model"]).to eql("23")
  end

  it "has a stepping for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("stepping")
    expect(@plugin[:cpu]["0"]["stepping"]).to eql("6")
  end

  it "doesn't have a phyiscal_id for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).not_to have_key("physical_id")
  end

  it "doesn't have a core_id for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).not_to have_key("core_id")
  end

  it "doesn't have a cores for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).not_to have_key("cores")
  end

  it "has a model name for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("model_name")
    expect(@plugin[:cpu]["0"]["model_name"]).to eql("Intel(R) Core(TM)2 Duo CPU     T8300   @ 2.40GHz")
  end

  it "has a mhz for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("mhz")
    expect(@plugin[:cpu]["0"]["mhz"]).to eql("1968.770")
  end

  it "has a cache_size for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("cache_size")
    expect(@plugin[:cpu]["0"]["cache_size"]).to eql("64 KB")
  end

  it "has flags for cpu 0" do
    @plugin.run
    expect(@plugin[:cpu]["0"]).to have_key("flags")
    expect(@plugin[:cpu]["0"]["flags"]).to eq(%w{fpu pse tsc msr mce cx8 sep mtrr pge cmov})
  end
end

describe Ohai::System, "S390 linux cpu plugin" do
  before(:each) do
    @plugin = get_plugin("linux/cpu")
    allow(@plugin).to receive(:collect_os).and_return(:linux)
    @double_file = double("/proc/cpuinfo")
    allow(@double_file).to receive(:each).
      and_yield("vendor_id : IBM/S390").
      and_yield("# processors : 2").
      and_yield("bogomips per cpu: 9328.00").
      and_yield("features : esan3 zarch stfle msa ldisp eimm dfp etf3eh highgprs").
      and_yield("processor 0: version = EE, identification = 06E276, machine = 2717").
      and_yield("processor 1: version = FF, identification = 06E278, machine = 2818")
    allow(File).to receive(:open).with("/proc/cpuinfo").and_return(@double_file)
  end

  it_behaves_like "Common cpu info", 2, 0
 
  it "has a cpu 1" do
    @plugin.run
    expect(@plugin[:cpu]).to have_key("1")
  end

  it "has a vendor_id" do
    @plugin.run
    expect(@plugin[:cpu]).to have_key("vendor_id")
    expect(@plugin[:cpu]["vendor_id"]).to eql("IBM/S390")
  end

  it "has a bogomips per cpu" do
    @plugin.run
    expect(@plugin[:cpu]).to have_key("bogomips_per_cpu")
    expect(@plugin[:cpu]["bogomips_per_cpu"]).to eql("9328.00")
  end

  it "has features" do
    @plugin.run
    expect(@plugin[:cpu]).to have_key("features")
    expect(@plugin[:cpu]["features"]).to eq(%w{esan3 zarch stfle msa ldisp eimm dfp etf3eh highgprs})
  end

  it_behaves_like "S390 processor info", 0, "EE", "06E276", "2717"
  it_behaves_like "S390 processor info", 1, "FF", "06E278", "2818"
end
