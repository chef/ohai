#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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

require "tempfile"
require "spec_helper"

shared_examples "Common cpu info" do |total_cpu, real_cpu|
  describe "cpu" do
    it "has cpu[:total] equals to #{total_cpu}" do
      plugin.run
      expect(plugin[:cpu][:total]).to eq(total_cpu)
    end

    it "has cpu[:real] equals to #{real_cpu}" do
      plugin.run
      expect(plugin[:cpu][:real]).to eq(real_cpu)
    end

    it "has a cpu 0" do
      plugin.run
      expect(plugin[:cpu]).to have_key("0")
    end
  end
end

shared_examples "S390 processor info" do |cpu_no, version, identification, machine|
  describe "S390 processor" do
    it "has a version for cpu #{cpu_no}" do
      plugin.run
      expect(plugin[:cpu][cpu_no.to_s]).to have_key("version")
      expect(plugin[:cpu][cpu_no.to_s]["version"]).to eql(version)
    end

    it "has a identification for cpu #{cpu_no}" do
      plugin.run
      expect(plugin[:cpu][cpu_no.to_s]).to have_key("identification")
      expect(plugin[:cpu][cpu_no.to_s]["identification"]).to eql(identification)
    end

    it "has a machine for cpu #{cpu_no}" do
      plugin.run
      expect(plugin[:cpu][cpu_no.to_s]).to have_key("machine")
      expect(plugin[:cpu][cpu_no.to_s]["machine"]).to eql(machine)
    end
  end
end

shared_examples "arm64 processor info" do |cpu_no, bogomips, features|
  describe "arm64 processor" do
    it "has bogomips for cpu #{cpu_no}" do
      plugin.run
      expect(plugin[:cpu][cpu_no.to_s]).to have_key("bogomips")
      expect(plugin[:cpu][cpu_no.to_s]["bogomips"]).to eql(bogomips)
    end

    it "has features for cpu #{cpu_no}" do
      plugin.run
      expect(plugin[:cpu][cpu_no.to_s]).to have_key("features")
      expect(plugin[:cpu][cpu_no.to_s]["features"]).to eql(features)
    end
  end
end

describe Ohai::System, "General Linux cpu plugin" do
  let(:plugin) { get_plugin("cpu") }

  let(:tempfile_handle) do
    tempfile = Tempfile.new("ohai-rspec-proc-cpuinfo")
    tempfile.write cpuinfo_contents
    tempfile.rewind
    tempfile
  end

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(File).to receive(:open).with("/proc/cpuinfo").and_return(tempfile_handle)
  end

  after do

    tempfile.close
    tempfile.unlink
  rescue
      # really do not care

  end

  context "with old kernel that doesn't include cores in /proc/cpuinfo" do
    let(:cpuinfo_contents) do
      <<-EOF
  processor     : 0
  vendor_id     : GenuineIntel
  cpu family    : 6
  model         : 23
  model name    : Intel(R) Core(TM)2 Duo CPU     T8300   @ 2.40GHz
  stepping      : 6
  cpu MHz       : 1968.770
  cache size    : 64 KB
  fdiv_bug      : no
  hlt_bug       : no
  f00f_bug      : no
  coma_bug      : no
  fpu           : yes
  fpu_exception : yes
  cpuid level   : 10
  wp            : yes
  flags         : fpu pse tsc msr mce cx8 sep mtrr pge cmov
  bogomips      : 2575.86
  clflush size  : 32
      EOF
    end

    let(:lscpu) do
      <<~EOF
        Architecture:          x86_64
        CPU op-mode(s):        32-bit, 64-bit
        Byte Order:            Little Endian
        CPU(s):                1
        On-line CPU(s) list:   0
        Thread(s) per core:    1
        Core(s) per socket:    1
        Socket(s):             1
        NUMA node(s):          1
        Vendor ID:             GenuineIntel
        CPU family:            6
        Model:                 23
        Model name:            Intel(R) Core(TM)2 Duo CPU     T8300   @ 2.40GHz
        Stepping:              2
        CPU MHz:               1968.770
        BogoMIPS:              2575.86
        Hypervisor vendor:     Xen
        Virtualization type:   full
        L1d cache:             32K
        L1i cache:             32K
        L2 cache:              256K
        L3 cache:              30720K
        NUMA node0 CPU(s):     0
        Flags:                 fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm fsgsbase bmi1 avx2 smep bmi2 erms invpcid xsaveopt
      EOF
    end

    before do
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(0, lscpu, ""))
    end

    it_behaves_like "Common cpu info", 1, 1

    it "gets total cores" do
      plugin.run
      expect(plugin[:cpu][:cores]).to be(1)
    end

    it "doesn't have a cpu 1" do
      plugin.run
      expect(plugin[:cpu]).not_to have_key("1")
    end

    it "has a vendor_id for cpu 0" do
      plugin.run
      expect(plugin[:cpu]["0"]).to have_key("vendor_id")
      expect(plugin[:cpu]["0"]["vendor_id"]).to eql("GenuineIntel")
    end

    it "has a family for cpu 0" do
      plugin.run
      expect(plugin[:cpu]["0"]).to have_key("family")
      expect(plugin[:cpu]["0"]["family"]).to eql("6")
    end

    it "has a model for cpu 0" do
      plugin.run
      expect(plugin[:cpu]["0"]).to have_key("model")
      expect(plugin[:cpu]["0"]["model"]).to eql("23")
    end

    it "has a stepping for cpu 0" do
      plugin.run
      expect(plugin[:cpu]["0"]).to have_key("stepping")
      expect(plugin[:cpu]["0"]["stepping"]).to eql("6")
    end

    it "doesn't have a phyiscal_id for cpu 0" do
      plugin.run
      expect(plugin[:cpu]["0"]).not_to have_key("physical_id")
    end

    it "doesn't have a core_id for cpu 0" do
      plugin.run
      expect(plugin[:cpu]["0"]).not_to have_key("core_id")
    end

    it "doesn't have a cores for cpu 0" do
      plugin.run
      expect(plugin[:cpu]["0"]).not_to have_key("cores")
    end

    it "has a model name for cpu 0" do
      plugin.run
      expect(plugin[:cpu]["0"]).to have_key("model_name")
      expect(plugin[:cpu]["0"]["model_name"]).to eql("Intel(R) Core(TM)2 Duo CPU     T8300   @ 2.40GHz")
    end

    it "has a mhz for cpu 0" do
      plugin.run
      expect(plugin[:cpu]["0"]).to have_key("mhz")
      expect(plugin[:cpu]["0"]["mhz"]).to eql("1968.770")
    end

    it "has a cache_size for cpu 0" do
      plugin.run
      expect(plugin[:cpu]["0"]).to have_key("cache_size")
      expect(plugin[:cpu]["0"]["cache_size"]).to eql("64 KB")
    end

    it "has flags for cpu 0" do
      plugin.run
      expect(plugin[:cpu]["0"]).to have_key("flags")
      expect(plugin[:cpu]["0"]["flags"]).to eq(%w{fpu pse tsc msr mce cx8 sep mtrr pge cmov})
    end
  end

  context "with a dual-core hyperthreaded /proc/cpuinfo" do
    let(:cpuinfo_contents) do
      <<~EOF
        processor   : 0
        vendor_id   : GenuineIntel
        cpu family  : 6
        model       : 69
        model name  : Intel(R) Core(TM) i7-4500U CPU @ 1.80GHz
        stepping    : 1
        microcode   : 0x17
        cpu MHz     : 774.000
        cache size  : 4096 KB
        physical id : 0
        siblings    : 4
        core id     : 0
        cpu cores   : 2
        apicid      : 0
        initial apicid  : 0
        fpu     : yes
        fpu_exception   : yes
        cpuid level : 13
        wp      : yes
        flags       : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 fma cx16 xtpr pdcm pcid sse4_1 sse4_2 movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm ida arat epb xsaveopt pln pts dtherm tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid
        bogomips    : 3591.40
        clflush size    : 64
        cache_alignment : 64
        address sizes   : 39 bits physical, 48 bits virtual
        power management:

        processor   : 1
        vendor_id   : GenuineIntel
        cpu family  : 6
        model       : 69
        model name  : Intel(R) Core(TM) i7-4500U CPU @ 1.80GHz
        stepping    : 1
        microcode   : 0x17
        cpu MHz     : 1600.000
        cache size  : 4096 KB
        physical id : 0
        siblings    : 4
        core id     : 0
        cpu cores   : 2
        apicid      : 1
        initial apicid  : 1
        fpu     : yes
        fpu_exception   : yes
        cpuid level : 13
        wp      : yes
        flags       : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 fma cx16 xtpr pdcm pcid sse4_1 sse4_2 movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm ida arat epb xsaveopt pln pts dtherm tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid
        bogomips    : 3591.40
        clflush size    : 64
        cache_alignment : 64
        address sizes   : 39 bits physical, 48 bits virtual
        power management:

        processor   : 2
        vendor_id   : GenuineIntel
        cpu family  : 6
        model       : 69
        model name  : Intel(R) Core(TM) i7-4500U CPU @ 1.80GHz
        stepping    : 1
        microcode   : 0x17
        cpu MHz     : 800.000
        cache size  : 4096 KB
        physical id : 0
        siblings    : 4
        core id     : 1
        cpu cores   : 2
        apicid      : 2
        initial apicid  : 2
        fpu     : yes
        fpu_exception   : yes
        cpuid level : 13
        wp      : yes
        flags       : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 fma cx16 xtpr pdcm pcid sse4_1 sse4_2 movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm ida arat epb xsaveopt pln pts dtherm tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid
        bogomips    : 3591.40
        clflush size    : 64
        cache_alignment : 64
        address sizes   : 39 bits physical, 48 bits virtual
        power management:

        processor   : 3
        vendor_id   : GenuineIntel
        cpu family  : 6
        model       : 69
        model name  : Intel(R) Core(TM) i7-4500U CPU @ 1.80GHz
        stepping    : 1
        microcode   : 0x17
        cpu MHz     : 774.000
        cache size  : 4096 KB
        physical id : 0
        siblings    : 4
        core id     : 1
        cpu cores   : 2
        apicid      : 3
        initial apicid  : 3
        fpu     : yes
        fpu_exception   : yes
        cpuid level : 13
        wp      : yes
        flags       : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf eagerfpu pni pclmulqdq dtes64 monitor ds_cpl vmx est tm2 ssse3 fma cx16 xtpr pdcm pcid sse4_1 sse4_2 movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand lahf_lm abm ida arat epb xsaveopt pln pts dtherm tpr_shadow vnmi flexpriority ept vpid fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid
        bogomips    : 3591.40
        clflush size    : 64
        cache_alignment : 64
        address sizes   : 39 bits physical, 48 bits virtual
        power management:

      EOF
    end

    it "has 1 physical socket" do
      plugin.run
      expect(plugin[:cpu][:real]).to eq(1)
    end

    it "has 2 physical cores" do
      plugin.run
      expect(plugin[:cpu][:cores]).to eq(2)
    end

    it "has 4 logical, hyper-threaded cores" do
      plugin.run
      expect(plugin[:cpu][:total]).to eq(4)
    end
  end
end

describe Ohai::System, "S390 linux cpu plugin" do
  let(:plugin) { get_plugin("cpu") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(1, "", ""))

    @double_file = double("/proc/cpuinfo")
    allow(@double_file).to receive(:each)
      .and_yield("vendor_id : IBM/S390")
      .and_yield("# processors : 2")
      .and_yield("bogomips per cpu: 9328.00")
      .and_yield("features : esan3 zarch stfle msa ldisp eimm dfp etf3eh highgprs")
      .and_yield("processor 0: version = EE, identification = 06E276, machine = 2717")
      .and_yield("processor 1: version = FF, identification = 06E278, machine = 2818")
    allow(File).to receive(:open).with("/proc/cpuinfo").and_return(@double_file)
  end

  it_behaves_like "Common cpu info", 2, nil

  it "has a cpu 1" do
    plugin.run
    expect(plugin[:cpu]).to have_key("1")
  end

  it "has a vendor_id" do
    plugin.run
    expect(plugin[:cpu]).to have_key("vendor_id")
    expect(plugin[:cpu]["vendor_id"]).to eql("IBM/S390")
  end

  it "has a bogomips per cpu" do
    plugin.run
    expect(plugin[:cpu]).to have_key("bogomips_per_cpu")
    expect(plugin[:cpu]["bogomips_per_cpu"]).to eql("9328.00")
  end

  it "has features" do
    plugin.run
    expect(plugin[:cpu]).to have_key("features")
    expect(plugin[:cpu]["features"]).to eq(%w{esan3 zarch stfle msa ldisp eimm dfp etf3eh highgprs})
  end

  it_behaves_like "S390 processor info", 0, "EE", "06E276", "2717"
  it_behaves_like "S390 processor info", 1, "FF", "06E278", "2818"
end

describe Ohai::System, "arm64 linux cpu plugin" do
  let(:plugin) { get_plugin("cpu") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(1, "", ""))

    @double_file = double("/proc/cpuinfo")
    allow(@double_file).to receive(:each)
      .and_yield("processor	: 0")
      .and_yield("BogoMIPS	: 40.00")
      .and_yield("Features	: fp asimd evtstrm aes pmull sha1 sha2 crc32")
      .and_yield("")
      .and_yield("processor      : 1")
      .and_yield("BogoMIPS       : 40.00")
      .and_yield("Features       : fp asimd evtstrm aes pmull sha1 sha2 crc32")
      .and_yield("")
    allow(File).to receive(:open).with("/proc/cpuinfo").and_return(@double_file)
  end

  it_behaves_like "Common cpu info", 2, nil

  it "has a cpu 1" do
    plugin.run
    expect(plugin[:cpu]).to have_key("1")
  end

  features = %w{fp asimd evtstrm aes pmull sha1 sha2 crc32}
  it_behaves_like "arm64 processor info", 0, "40.00", features
  it_behaves_like "arm64 processor info", 1, "40.00", features
end
