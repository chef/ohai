#
# Author:: Nathan L Smith (<nlloyds@gmail.com>)
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
#


require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "Darwin cpu plugin" do
  before(:each) do
    @plugin = get_plugin("darwin/cpu")
    @plugin.stub(:collect_os).and_return(:darwin)
    @plugin.stub(:shell_out).with("sysctl -n hw.physicalcpu").and_return(mock_shell_out(0, "4", ""))
    @plugin.stub(:shell_out).with("sysctl -n hw.logicalcpu").and_return(mock_shell_out(0, "8", ""))
    @plugin.stub(:shell_out).with("sysctl -n hw.cpufrequency").and_return(mock_shell_out(0, "2300000000", ""))
    @plugin.stub(:shell_out).with("sysctl -n machdep.cpu.vendor").and_return(mock_shell_out(0, "GenuineIntel", ""))
    @plugin.stub(:shell_out).with("sysctl -n machdep.cpu.brand_string").and_return(mock_shell_out(0, "Intel(R) Core(TM) i7-3615QM CPU @ 2.30GHz", ""))
    @plugin.stub(:shell_out).with("sysctl -n machdep.cpu.model").and_return(mock_shell_out(0, "58", ""))
    @plugin.stub(:shell_out).with("sysctl -n machdep.cpu.family").and_return(mock_shell_out(0, "6", ""))
    @plugin.stub(:shell_out).with("sysctl -n machdep.cpu.stepping").and_return(mock_shell_out(0, "9", ""))
    @plugin.stub(:shell_out).with("sysctl -n machdep.cpu.features").and_return(mock_shell_out(0, "FPU VME DE PSE TSC MSR PAE MCE CX8 APIC SEP MTRR PGE MCA CMOV PAT PSE36 CLFSH DS ACPI MMX FXSR SSE SSE2 SS HTT TM PBE SSE3 PCLMULQDQ DTES64 MON DSCPL VMX EST TM2 SSSE3 CX16 TPR PDCM SSE4.1 SSE4.2 x2APIC POPCNT AES PCID XSAVE OSXSAVE TSCTMR AVX1.0 RDRAND F16C", ""))
    @plugin.run
  end

  it "should set cpu[:total] to 8" do
    @plugin[:cpu][:total].should == 8
  end

  it "should set cpu[:real] to 4" do
    @plugin[:cpu][:real].should == 4
  end

  it "should set cpu[:mhz] to 2300" do
    @plugin[:cpu][:mhz].should == 2300
  end

  it "should set cpu[:vendor_id] to GenuineIntel" do
    @plugin[:cpu][:vendor_id].should == "GenuineIntel"
  end

  it "should set cpu[:model_name] to Intel(R) Core(TM) i7-3615QM CPU @ 2.30GHz" do
    @plugin[:cpu][:model_name].should == "Intel(R) Core(TM) i7-3615QM CPU @ 2.30GHz"
  end

  it "should set cpu[:model] to 58" do
    @plugin[:cpu][:model].should == 58
  end

  it "should set cpu[:family] to 6" do
    @plugin[:cpu][:family].should == 6
  end

  it "should set cpu[:stepping] to 9" do
    @plugin[:cpu][:stepping].should == 9
  end

  it "should set cpu[:flags] to array of flags" do
    @plugin[:cpu][:flags].should == ["fpu", "vme", "de", "pse", "tsc", "msr", "pae", "mce", "cx8", "apic", "sep", "mtrr", "pge", "mca", "cmov", "pat", "pse36", "clfsh", "ds", "acpi", "mmx", "fxsr", "sse", "sse2", "ss", "htt", "tm", "pbe", "sse3", "pclmulqdq", "dtes64", "mon", "dscpl", "vmx", "est", "tm2", "ssse3", "cx16", "tpr", "pdcm", "sse4.1", "sse4.2", "x2apic", "popcnt", "aes", "pcid", "xsave", "osxsave", "tsctmr", "avx1.0", "rdrand", "f16c"]
  end
end
