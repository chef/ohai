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

describe Ohai::System, "FreeBSD cpu plugin" do
  before(:each) do
    @plugin = get_plugin("freebsd/cpu")
    allow(@plugin).to receive(:collect_os).and_return(:freebsd)
    allow(@plugin).to receive(:shell_out).with("sysctl -n hw.ncpu").and_return(mock_shell_out(0, "2", ""))
    @double_file = double("/var/run/dmesg.boot")
    allow(@double_file).to receive(:each).
      and_yield('CPU: Intel(R) Core(TM) i7-3615QM CPU @ 2.30GHz (3516.61-MHz K8-class CPU)').
      and_yield('  Origin = "GenuineIntel"  Id = 0x306a9  Family = 6  Model = 3a  Stepping = 9').
      and_yield('  Features=0x783fbff<FPU,VME,DE,PSE,TSC,MSR,PAE,MCE,CX8,APIC,SEP,MTRR,PGE,MCA,CMOV,PAT,PSE36,MMX,FXSR,SSE,SSE2>').
      and_yield('  Features2=0x209<SSE3,MON,SSSE3>').
      and_yield('  AMD Features=0x28100800<SYSCALL,NX,RDTSCP,LM>').
      and_yield('  AMD Features2=0x1<LAHF>').
      and_yield('  TSC: P-state invariant')
    allow(File).to receive(:open).with("/var/run/dmesg.boot").and_return(@double_file)
  end

  it "detects all CPU flags" do
    @plugin.run
    expect(@plugin[:cpu][:flags]).to eq(%w{fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 mmx fxsr sse sse2 sse3 mon ssse3 syscall nx rdtscp lm lahf})
  end

  it "detects all CPU model_name" do
    @plugin.run
    expect(@plugin[:cpu][:model_name]).to eq("Intel(R) Core(TM) i7-3615QM CPU @ 2.30GHz")
  end

  it "detects all CPU mhz" do
    @plugin.run
    expect(@plugin[:cpu][:mhz]).to eq("3516.61")
  end

  it "detects all CPU vendor_id" do
    @plugin.run
    expect(@plugin[:cpu][:vendor_id]).to eq("GenuineIntel")
  end

  it "detects all CPU stepping" do
    @plugin.run
    expect(@plugin[:cpu][:stepping]).to eq("9")
  end

  it "detects all CPU total" do
    @plugin.run
    expect(@plugin[:cpu][:total]).to eq(2)
  end

end
