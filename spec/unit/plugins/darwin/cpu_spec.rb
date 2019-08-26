#
# Author:: Nathan L Smith (<nlloyds@gmail.com>)
# Copyright:: Copyright (c) 2013-2018 Chef Software, Inc.
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

require "spec_helper"

describe Ohai::System, "Darwin cpu plugin" do
  before do
    @plugin = get_plugin("cpu")
    @stdout = <<~CTL
      hw.ncpu: 8
      hw.byteorder: 1234
      hw.memsize: 17179869184
      hw.activecpu: 8
      hw.packages: 1
      hw.tbfrequency: 1000000000
      hw.l3cachesize: 6291456
      hw.l2cachesize: 262144
      hw.l1dcachesize: 32768
      hw.l1icachesize: 32768
      hw.cachelinesize: 64
      hw.cpufrequency: 2800000000
      hw.busfrequency: 100000000
      hw.pagesize32: 4096
      hw.pagesize: 4096
      hw.cpufamily: 280134364
      hw.cpu64bit_capable: 1
      hw.cpusubtype: 8
      hw.cputype: 7
      hw.logicalcpu_max: 8
      hw.logicalcpu: 8
      hw.physicalcpu_max: 4
      hw.physicalcpu: 4
      hw.targettype: Mac
      hw.cputhreadtype: 1
      machdep.cpu.thread_count: 8
      machdep.cpu.core_count: 4
      machdep.cpu.address_bits.virtual: 48
      machdep.cpu.address_bits.physical: 39
      machdep.cpu.cache.size: 256
      machdep.cpu.cache.L2_associativity: 8
      machdep.cpu.cache.linesize: 64
      machdep.cpu.processor_flag: 5
      machdep.cpu.microcode_version: 15
      machdep.cpu.cores_per_package: 8
      machdep.cpu.logical_per_package: 16
      machdep.cpu.extfeatures: SYSCALL XD 1GBPAGE EM64T LAHF LZCNT RDTSCP TSCI
      machdep.cpu.leaf7_features: SMEP ERMS RDWRFSGS TSC_THREAD_OFFSET BMI1 HLE AVX2 BMI2 INVPCID RTM FPU_CSDS
      machdep.cpu.features: FPU VME DE PSE TSC MSR PAE MCE CX8 APIC SEP MTRR PGE MCA CMOV PAT PSE36 CLFSH DS ACPI MMX FXSR SSE SSE2 SS HTT TM PBE SSE3 PCLMULQDQ DTES64 MON DSCPL VMX SMX EST TM2 SSSE3 FMA CX16 TPR PDCM SSE4.1 SSE4.2 x2APIC MOVBE POPCNT AES PCID XSAVE OSXSAVE SEGLIM64 TSCTMR AVX1.0 RDRAND F16C
      machdep.cpu.brand: 0
      machdep.cpu.signature: 263777
      machdep.cpu.extfeature_bits: 142473169152
      machdep.cpu.leaf7_feature_bits: 12219
      machdep.cpu.feature_bits: 9221960262849657855
      machdep.cpu.stepping: 1
      machdep.cpu.extfamily: 0
      machdep.cpu.extmodel: 4
      machdep.cpu.model: 70
      machdep.cpu.family: 6
      machdep.cpu.brand_string: Intel(R) Core(TM) i7-4980HQ CPU @ 2.80GHz
      machdep.cpu.vendor: GenuineIntel
      machdep.cpu.max_ext: 2147483656
      machdep.cpu.max_basic: 13
    CTL

    allow(@plugin).to receive(:collect_os).and_return(:darwin)
    allow(@plugin).to receive(:shell_out).with("sysctl hw machdep").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
  end

  it "sets cpu[:cores] to 4" do
    expect(@plugin[:cpu][:cores]).to eq(4)
  end

  it "sets cpu[:total] to 8" do
    expect(@plugin[:cpu][:total]).to eq(8)
  end

  it "sets cpu[:real] to 1" do
    expect(@plugin[:cpu][:real]).to eq(1)
  end

  it "sets cpu[:mhz] to 2800" do
    expect(@plugin[:cpu][:mhz]).to eq(2800)
  end

  it "sets cpu[:vendor_id] to GenuineIntel" do
    expect(@plugin[:cpu][:vendor_id]).to eq("GenuineIntel")
  end

  it "sets cpu[:model_name] to Intel(R) Core(TM) i7-4980HQ CPU @ 2.80GHz" do
    expect(@plugin[:cpu][:model_name]).to eq("Intel(R) Core(TM) i7-4980HQ CPU @ 2.80GHz")
  end

  it "sets cpu[:model] to 70" do
    expect(@plugin[:cpu][:model]).to eq(70)
  end

  it "sets cpu[:family] to 6" do
    expect(@plugin[:cpu][:family]).to eq(6)
  end

  it "sets cpu[:stepping] to 1" do
    expect(@plugin[:cpu][:stepping]).to eq(1)
  end

  it "sets cpu[:flags] to array of flags" do
    expect(@plugin[:cpu][:flags]).to eq(["fpu", "vme", "de", "pse", "tsc", "msr", "pae", "mce", "cx8", "apic", "sep", "mtrr", "pge", "mca", "cmov", "pat", "pse36", "clfsh", "ds", "acpi", "mmx", "fxsr", "sse", "sse2", "ss", "htt", "tm", "pbe", "sse3", "pclmulqdq", "dtes64", "mon", "dscpl", "vmx", "smx", "est", "tm2", "ssse3", "fma", "cx16", "tpr", "pdcm", "sse4.1", "sse4.2", "x2apic", "movbe", "popcnt", "aes", "pcid", "xsave", "osxsave", "seglim64", "tsctmr", "avx1.0", "rdrand", "f16c"])
  end
end
