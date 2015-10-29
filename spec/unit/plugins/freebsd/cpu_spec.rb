#
# Author:: Tim Smith <tsmith@limelight.com>
# Copyright:: Copyright (c) 2014 Limelight Networks, Inc.
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

describe Ohai::System, "FreeBSD cpu plugin on FreeBSD >=10.2" do
  before(:each) do
    @plugin = get_plugin("freebsd/cpu")
    allow(@plugin).to receive(:collect_os).and_return(:freebsd)
    allow(@plugin).to receive(:shell_out).with("sysctl -n hw.ncpu").and_return(mock_shell_out(0, "2", ""))
    @double_file = double("/var/run/dmesg.boot")
    allow(@double_file).to receive(:each).
      and_yield('CPU: Intel(R) Core(TM) i7-4980HQ CPU @ 2.80GHz (2793.59-MHz K8-class CPU)').
      and_yield('  Origin="GenuineIntel"  Id=0x40661  Family=0x6  Model=0x46  Stepping=1').
      and_yield('  Features=0x783fbff<FPU,VME,DE,PSE,TSC,MSR,PAE,MCE,CX8,APIC,SEP,MTRR,PGE,MCA,CMOV,PAT,PSE36,MMX,FXSR,SSE,SSE2>').
      and_yield('  Features2=0x5ed8220b<SSE3,PCLMULQDQ,MON,SSSE3,CX16,SSE4.1,SSE4.2,MOVBE,POPCNT,AESNI,XSAVE,OSXSAVE,AVX,RDRAND>').
      and_yield('  AMD Features=0x28100800<SYSCALL,NX,RDTSCP,LM>').
      and_yield('  AMD Features2=0x21<LAHF,ABM>').
      and_yield('  Structured Extended Features=0x2000<NFPUSG>').
      and_yield('  TSC: P-state invariant')
    allow(File).to receive(:open).with("/var/run/dmesg.boot").and_return(@double_file)
  end

  it "detects all CPU flags" do
    @plugin.run
    expect(@plugin[:cpu][:flags]).to eq(%w{fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 mmx fxsr sse sse2 sse3 pclmulqdq mon ssse3 cx16 sse4.1 sse4.2 movbe popcnt aesni xsave osxsave avx rdrand syscall nx rdtscp lm lahf abm nfpusg})
  end

  it "detects CPU model_name" do
    @plugin.run
    expect(@plugin[:cpu][:model_name]).to eq("Intel(R) Core(TM) i7-4980HQ CPU @ 2.80GHz")
  end

  it "detects CPU mhz" do
    @plugin.run
    expect(@plugin[:cpu][:mhz]).to eq("2793.59")
  end

  it "detects CPU vendor_id" do
    @plugin.run
    expect(@plugin[:cpu][:vendor_id]).to eq("GenuineIntel")
  end

  it "detects CPU family" do
    @plugin.run
    expect(@plugin[:cpu][:family]).to eq("6")
  end

  it "detects CPU model" do
    @plugin.run
    expect(@plugin[:cpu][:model]).to eq("46")
  end

  it "detects CPU stepping" do
    @plugin.run
    expect(@plugin[:cpu][:stepping]).to eq("1")
  end

  it "detects CPU total" do
    @plugin.run
    expect(@plugin[:cpu][:total]).to eq(2)
  end

end

describe Ohai::System, "FreeBSD cpu plugin on FreeBSD <=10.1" do
  before(:each) do
    @plugin = get_plugin("freebsd/cpu")
    allow(@plugin).to receive(:collect_os).and_return(:freebsd)
    allow(@plugin).to receive(:shell_out).with("sysctl -n hw.ncpu").and_return(mock_shell_out(0, "2", ""))
    @double_file = double("/var/run/dmesg.boot")
    allow(@double_file).to receive(:each).
      and_yield('CPU: Intel(R) Atom(TM) CPU N270   @ 1.60GHz (1596.03-MHz 686-class CPU)').
      and_yield('  Origin = "GenuineIntel"  Id = 0x106c2  Family = 0x6  Model = 0x1c  Stepping = 2')
    allow(File).to receive(:open).with("/var/run/dmesg.boot").and_return(@double_file)
  end

  it "detects CPU vendor_id" do
    @plugin.run
    expect(@plugin[:cpu][:vendor_id]).to eq("GenuineIntel")
  end

  it "detects CPU family" do
    @plugin.run
    expect(@plugin[:cpu][:family]).to eq("6")
  end

  it "detects CPU model" do
    @plugin.run
    expect(@plugin[:cpu][:model]).to eq("1c")
  end

  it "detects CPU stepping" do
    @plugin.run
    expect(@plugin[:cpu][:stepping]).to eq("2")
  end

end
