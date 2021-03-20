#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

shared_examples "Common cpu info" do |total_cpu, real_cpu, ls_cpu|
  describe "cpu" do
    it "has cpu[:total] equals to #{total_cpu}" do
      plugin.run
      expect(plugin[:cpu][:total]).to eq(total_cpu)
    end

    if ls_cpu
      it "has cpu[:real] equals to #{real_cpu}" do
        plugin.run
        expect(plugin[:cpu][:real]).to eq(real_cpu)
      end
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

shared_examples "ppc64le processor info" do |cpu_no, model_name, model, mhz|
  describe "ppc64le processor" do
    it "has model_name for cpu #{cpu_no}" do
      plugin.run
      expect(plugin[:cpu][cpu_no.to_s]).to have_key("model_name")
      expect(plugin[:cpu][cpu_no.to_s]["model_name"]).to eql(model_name)
    end

    it "has model for cpu #{cpu_no}" do
      plugin.run
      expect(plugin[:cpu][cpu_no.to_s]).to have_key("model")
      expect(plugin[:cpu][cpu_no.to_s]["model"]).to eql(model)
    end

    it "has mhz for cpu #{cpu_no}" do
      plugin.run
      expect(plugin[:cpu][cpu_no.to_s]).to have_key("mhz")
      expect(plugin[:cpu][cpu_no.to_s]["mhz"]).to eql(mhz)
    end
  end
end

describe Ohai::System, "General Linux cpu plugin" do
  let(:plugin) { get_plugin("cpu") }
  let(:cpuinfo_contents) { "" }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(File).to receive(:open).with("/proc/cpuinfo").and_return(cpuinfo_contents)
    allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(1, "", ""))
    allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(1, "", ""))
  end

  context "with old kernel that doesn't include cores in /proc/cpuinfo and no lscpu" do
    let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-no-cores.output")) }

    it_behaves_like "Common cpu info", 1, 1, false

    it "doesn't get total cores" do
      plugin.run
      expect(plugin[:cpu]).not_to have_key("cores")
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

  context "standard x86 host cpu with lscpu" do
    let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-no-cores.output")) }
    let(:lscpu) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-x86-host.output")) }
    let(:lscpu_cores) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-x86-host-cores.output")) }

    before do
      allow(File).to receive(:open).with("/proc/cpuinfo").and_return(cpuinfo_contents)
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(0, lscpu, ""))
      allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(0, lscpu_cores, ""))
    end

    it_behaves_like "Common cpu info", 24, 2, true

    it "has architecture" do
      plugin.run
      expect(plugin[:cpu]).to have_key("architecture")
      expect(plugin[:cpu]["architecture"]).to eq("x86_64")
    end

    it "has cpu_opmodes" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cpu_opmodes")
      expect(plugin[:cpu]["cpu_opmodes"]).to eq(%w{32-bit 64-bit})
    end

    it "has byte_order" do
      plugin.run
      expect(plugin[:cpu]).to have_key("byte_order")
      expect(plugin[:cpu]["byte_order"]).to eq("little endian")
    end

    it "has cpus" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cpus")
      expect(plugin[:cpu]["cpus"]).to eq(24)
    end

    it "has cpus_online" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cpus_online")
      expect(plugin[:cpu]["cpus_online"]).to eq(24)
    end

    it "has threads_per_core" do
      plugin.run
      expect(plugin[:cpu]).to have_key("threads_per_core")
      expect(plugin[:cpu]["threads_per_core"]).to eq(2)
    end

    it "has cores_per_socket" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cores_per_socket")
      expect(plugin[:cpu]["cores_per_socket"]).to eq(6)
    end

    it "has sockets" do
      plugin.run
      expect(plugin[:cpu]).to have_key("sockets")
      expect(plugin[:cpu]["sockets"]).to eq(2)
    end

    it "has numa_nodes" do
      plugin.run
      expect(plugin[:cpu]).to have_key("numa_nodes")
      expect(plugin[:cpu]["numa_nodes"]).to eq(1)
    end

    it "has vendor_id" do
      plugin.run
      expect(plugin[:cpu]).to have_key("vendor_id")
      expect(plugin[:cpu]["vendor_id"]).to eq("GenuineIntel")
    end

    it "has family" do
      plugin.run
      expect(plugin[:cpu]).to have_key("family")
      expect(plugin[:cpu]["family"]).to eq("6")
    end

    it "has model" do
      plugin.run
      expect(plugin[:cpu]).to have_key("model")
      expect(plugin[:cpu]["model"]).to eq("44")
    end

    it "has model_name" do
      plugin.run
      expect(plugin[:cpu]).to have_key("model_name")
      expect(plugin[:cpu]["model_name"]).to eq("Intel(R) Xeon(R) CPU           X5670  @ 2.93GHz")
    end

    it "has stepping" do
      plugin.run
      expect(plugin[:cpu]).to have_key("stepping")
      expect(plugin[:cpu]["stepping"]).to eq("2")
    end

    it "has mhz" do
      plugin.run
      expect(plugin[:cpu]).to have_key("mhz")
      expect(plugin[:cpu]["mhz"]).to eq("2927.000")
    end

    it "has bogomips" do
      plugin.run
      expect(plugin[:cpu]).to have_key("bogomips")
      expect(plugin[:cpu]["bogomips"]).to eq("5851.68")
    end

    # it "has hypervisor_vendor" do
    #  plugin.run
    #  expect(plugin[:cpu]).to have_key("hypervisor_vendor")
    #  expect(plugin[:cpu]["hypervisor_vendor"]).to eq("Xen")
    # end

    # it "has virtualization_type" do
    #  plugin.run
    #  expect(plugin[:cpu]).to have_key("virtualization_type")
    #  expect(plugin[:cpu]["virtualization_type"]).to eq("full")
    # end

    it "has l1d_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l1d_cache")
      expect(plugin[:cpu]["l1d_cache"]).to eq("32K")
    end

    it "has l1i_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l1i_cache")
      expect(plugin[:cpu]["l1i_cache"]).to eq("32K")
    end

    it "has l2_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l2_cache")
      expect(plugin[:cpu]["l2_cache"]).to eq("256K")
    end

    it "has l3_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l3_cache")
      expect(plugin[:cpu]["l3_cache"]).to eq("12288K")
    end

    it "has flags" do
      plugin.run
      expect(plugin[:cpu]).to have_key("flags")
      expect(plugin[:cpu]["flags"]).to eq(%w{acpi aes aperfmperf apic arat arch_perfmon bts clflush cmov constant_tsc cx16 cx8 dca de ds_cpl dtes64 dtherm dts eagerfpu epb ept est flexpriority flush_l1d fpu fxsr ht ibpb ibrs ida intel_stibp lahf_lm lm mca mce mmx monitor msr mtrr nonstop_tsc nopl nx pae pat pbe pcid pclmulqdq pdcm pdpe1gb pebs pge pni popcnt pse pse36 rdtscp rep_good sep smx spec_ctrl ss ssbd sse sse2 sse4_1 sse4_2 ssse3 stibp syscall tm tm2 tpr_shadow tsc vme vmx vnmi vpid xtopology xtpr})
    end

    it "has numa_node_cpus" do
      plugin.run
      expect(plugin[:cpu]).to have_key("numa_node_cpus")
      expect(plugin[:cpu]["numa_node_cpus"]).to eq({ "0" => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23] })
    end
  end

  context "with a dual-core hyperthreaded /proc/cpuinfo" do
    let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-dual-core-hyperthreaded.output")) }

    before do
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(1, "", ""))
      allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(1, "", ""))
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
  let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-s390x.output")) }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(File).to receive(:open).with("/proc/cpuinfo").and_return(cpuinfo_contents)
    allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(1, "", ""))
    allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(1, "", ""))
  end

  it_behaves_like "Common cpu info", 4, nil, false

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
    expect(plugin[:cpu]["bogomips_per_cpu"]).to eql("3241.00")
  end

  it "has features" do
    plugin.run
    expect(plugin[:cpu]).to have_key("features")
    expect(plugin[:cpu]["features"]).to eq(%w{esan3 zarch stfle msa ldisp eimm dfp edat etf3eh highgprs te vx vxd vxe gs vxe2 vxp sort dflt})
  end

  it_behaves_like "S390 processor info", 0, "FF", "0618E8", "8561", false
  it_behaves_like "S390 processor info", 1, "FF", "0618E8", "8561", false

  context "with lscpu data" do
    let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-s390x.output")) }
    let(:lscpu) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-s390x-guest-kvm.output")) }
    let(:lscpu_cores) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-s390x-guest-kvm-cores.output")) }

    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(0, lscpu, ""))
      allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(0, lscpu_cores, ""))
    end

    it_behaves_like "Common cpu info", 4, 1, true

    it "has a cpu 1" do
      plugin.run
      expect(plugin[:cpu]).to have_key("1")
    end

    it "has a vendor_id" do
      plugin.run
      expect(plugin[:cpu]).to have_key("vendor_id")
      expect(plugin[:cpu]["vendor_id"]).to eql("IBM/S390")
    end

    it "does not have a bogomips per cpu" do
      plugin.run
      expect(plugin[:cpu]).to have_key("bogomips_per_cpu")
      expect(plugin[:cpu]["bogomips_per_cpu"]).to eql("3241.00")
    end

    it "has features" do
      plugin.run
      expect(plugin[:cpu]).to have_key("features")
      expect(plugin[:cpu]["features"]).to eq(%w{dflt dfp edat eimm esan3 etf3eh gs highgprs ldisp msa sort stfle te vx vxd vxe vxe2 vxp zarch})
    end

    it_behaves_like "S390 processor info", 0, "FF", "0618E8", "8561", false
    it_behaves_like "S390 processor info", 1, "FF", "0618E8", "8561", false

    it "has architecture" do
      plugin.run
      expect(plugin[:cpu]).to have_key("architecture")
      expect(plugin[:cpu]["architecture"]).to eq("s390x")
    end

    it "has cpu_opmodes" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cpu_opmodes")
      expect(plugin[:cpu]["cpu_opmodes"]).to eq(%w{32-bit 64-bit})
    end

    it "has byte_order" do
      plugin.run
      expect(plugin[:cpu]).to have_key("byte_order")
      expect(plugin[:cpu]["byte_order"]).to eq("big endian")
    end

    it "has cpus" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cpus")
      expect(plugin[:cpu]["cpus"]).to eq(4)
    end

    it "has cpus_online" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cpus_online")
      expect(plugin[:cpu]["cpus_online"]).to eq(4)
    end

    it "has threads_per_core" do
      plugin.run
      expect(plugin[:cpu]).to have_key("threads_per_core")
      expect(plugin[:cpu]["threads_per_core"]).to eq(1)
    end

    it "has cores_per_socket" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cores_per_socket")
      expect(plugin[:cpu]["cores_per_socket"]).to eq(1)
    end

    it "has sockets_per_book" do
      plugin.run
      expect(plugin[:cpu]).to have_key("sockets_per_book")
      expect(plugin[:cpu]["sockets_per_book"]).to eq(1)
    end

    it "has books_per_drawer" do
      plugin.run
      expect(plugin[:cpu]).to have_key("books_per_drawer")
      expect(plugin[:cpu]["books_per_drawer"]).to eq(1)
    end

    it "has drawers" do
      plugin.run
      expect(plugin[:cpu]).to have_key("drawers")
      expect(plugin[:cpu]["drawers"]).to eq(4)
    end

    it "has numa_nodes" do
      plugin.run
      expect(plugin[:cpu]).to have_key("numa_nodes")
      expect(plugin[:cpu]["numa_nodes"]).to eq(1)
    end

    it "has vendor_id" do
      plugin.run
      expect(plugin[:cpu]).to have_key("vendor_id")
      expect(plugin[:cpu]["vendor_id"]).to eq("IBM/S390")
    end

    it "has machine_type" do
      plugin.run
      expect(plugin[:cpu]).to have_key("machine_type")
      expect(plugin[:cpu]["machine_type"]).to eq("8561")
    end

    it "has mhz" do
      plugin.run
      expect(plugin[:cpu]).to have_key("mhz")
      expect(plugin[:cpu]["mhz"]).to eq("5200")
    end

    it "has mhz_dynamic" do
      plugin.run
      expect(plugin[:cpu]).to have_key("mhz_dynamic")
      expect(plugin[:cpu]["mhz_dynamic"]).to eq("5200")
    end

    it "has bogomips" do
      plugin.run
      expect(plugin[:cpu]).to have_key("bogomips")
      expect(plugin[:cpu]["bogomips"]).to eq("3241.00")
    end

    it "has hypervisor_vendor" do
      plugin.run
      expect(plugin[:cpu]).to have_key("hypervisor_vendor")
      expect(plugin[:cpu]["hypervisor_vendor"]).to eq("KVM")
    end

    it "has virtualization_type" do
      plugin.run
      expect(plugin[:cpu]).to have_key("virtualization_type")
      expect(plugin[:cpu]["virtualization_type"]).to eq("full")
    end

    it "has dispatching_mode" do
      plugin.run
      expect(plugin[:cpu]).to have_key("dispatching_mode")
      expect(plugin[:cpu]["dispatching_mode"]).to eq("horizontal")
    end

    it "has l1d_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l1d_cache")
      expect(plugin[:cpu]["l1d_cache"]).to eq("128K")
    end

    it "has l1i_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l1i_cache")
      expect(plugin[:cpu]["l1i_cache"]).to eq("128K")
    end

    it "has l2d_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l2d_cache")
      expect(plugin[:cpu]["l2d_cache"]).to eq("4096K")
    end

    it "has l2i_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l2i_cache")
      expect(plugin[:cpu]["l2i_cache"]).to eq("4096K")
    end

    it "has l3_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l3_cache")
      expect(plugin[:cpu]["l3_cache"]).to eq("262144K")
    end

    it "has flags" do
      plugin.run
      expect(plugin[:cpu]).to have_key("flags")
      expect(plugin[:cpu]["flags"]).to eq(%w{dflt dfp edat eimm esan3 etf3eh gs highgprs ldisp msa sort stfle te vx vxd vxe vxe2 vxp zarch})
    end

    it "has numa_node_cpus" do
      plugin.run
      expect(plugin[:cpu]).to have_key("numa_node_cpus")
      expect(plugin[:cpu]["numa_node_cpus"]).to eq({ "0" => [0, 1, 2, 3] })
    end
  end
end

describe Ohai::System, "arm64 linux cpu plugin" do
  let(:plugin) { get_plugin("cpu") }
  let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-aarch64.output")) }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(File).to receive(:open).with("/proc/cpuinfo").and_return(cpuinfo_contents)
    allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(1, "", ""))
    allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(1, "", ""))
  end

  it_behaves_like "Common cpu info", 2, nil, false

  it "has a cpu 1" do
    plugin.run
    expect(plugin[:cpu]).to have_key("1")
  end

  features = %w{fp asimd evtstrm aes pmull sha1 sha2 crc32 cpuid}
  it_behaves_like "arm64 processor info", 0, "80.00", features
  it_behaves_like "arm64 processor info", 1, "80.00", features

  context "with lscpu data" do
    let(:lscpu) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-aarch64-host.output")) }
    let(:lscpu_cores) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-aarch64-host-cores.output")) }

    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(0, lscpu, ""))
      allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(0, lscpu_cores, ""))
    end

    it_behaves_like "Common cpu info", 32, 1, true

    it "has a cpu 1" do
      plugin.run
      expect(plugin[:cpu]).to have_key("1")
    end

    features = %w{aes asimd cpuid crc32 evtstrm fp pmull sha1 sha2}
    it_behaves_like "arm64 processor info", 0, "80.00", features
    it_behaves_like "arm64 processor info", 1, "80.00", features

    it "has architecture" do
      plugin.run
      expect(plugin[:cpu]).to have_key("architecture")
      expect(plugin[:cpu]["architecture"]).to eq("aarch64")
    end

    it "has byte_order" do
      plugin.run
      expect(plugin[:cpu]).to have_key("byte_order")
      expect(plugin[:cpu]["byte_order"]).to eq("little endian")
    end

    it "has cpus" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cpus")
      expect(plugin[:cpu]["cpus"]).to eq(32)
    end

    it "has cpus_online" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cpus_online")
      expect(plugin[:cpu]["cpus_online"]).to eq(32)
    end

    it "has threads_per_core" do
      plugin.run
      expect(plugin[:cpu]).to have_key("threads_per_core")
      expect(plugin[:cpu]["threads_per_core"]).to eq(1)
    end

    it "has cores_per_socket" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cores_per_socket")
      expect(plugin[:cpu]["cores_per_socket"]).to eq(32)
    end

    it "has sockets" do
      plugin.run
      expect(plugin[:cpu]).to have_key("sockets")
      expect(plugin[:cpu]["sockets"]).to eq(1)
    end

    it "has numa_nodes" do
      plugin.run
      expect(plugin[:cpu]).to have_key("numa_nodes")
      expect(plugin[:cpu]["numa_nodes"]).to eq(1)
    end

    it "has mhz_max" do
      plugin.run
      expect(plugin[:cpu]).to have_key("mhz_max")
      expect(plugin[:cpu]["mhz_max"]).to eq("3300.0000")
    end

    it "has mhz_min" do
      plugin.run
      expect(plugin[:cpu]).to have_key("mhz_min")
      expect(plugin[:cpu]["mhz_min"]).to eq("363.9700")
    end

    it "has bogomips" do
      plugin.run
      expect(plugin[:cpu]).to have_key("bogomips")
      expect(plugin[:cpu]["bogomips"]).to eq("80.00")
    end

    it "has l1d_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l1d_cache")
      expect(plugin[:cpu]["l1d_cache"]).to eq("32K")
    end

    it "has l1i_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l1i_cache")
      expect(plugin[:cpu]["l1i_cache"]).to eq("32K")
    end

    it "has l2_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l2_cache")
      expect(plugin[:cpu]["l2_cache"]).to eq("256K")
    end

    it "has flags" do
      plugin.run
      expect(plugin[:cpu]).to have_key("flags")
      expect(plugin[:cpu]["flags"]).to eq(%w{aes asimd cpuid crc32 evtstrm fp pmull sha1 sha2})
    end

    it "has numa_node_cpus" do
      plugin.run
      expect(plugin[:cpu]).to have_key("numa_node_cpus")
      cpus = Range.new(0, 31).to_a
      expect(plugin[:cpu]["numa_node_cpus"]).to eq({ "0" => cpus })
    end
  end
end

describe Ohai::System, "ppc64le linux cpu plugin" do
  let(:plugin) { get_plugin("cpu") }
  let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-ppc64le.output")) }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(File).to receive(:open).with("/proc/cpuinfo").and_return(cpuinfo_contents)
    allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(1, "", ""))
    allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(1, "", ""))
  end

  it_behaves_like "Common cpu info", 2, nil, false

  it "has a cpu 0" do
    plugin.run
    expect(plugin[:cpu]).to have_key("0")
  end

  it "has a cpu 4" do
    plugin.run
    expect(plugin[:cpu]).to have_key("4")
  end

  context "with lscpu data" do
    let(:lscpu) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-ppc64le-p9-host.output")) }
    let(:lscpu_cores) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-ppc64le-p9-host-cores.output")) }

    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(0, lscpu, ""))
      allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(0, lscpu_cores, ""))
    end

    it_behaves_like "Common cpu info", 32, 2, true

    it "has a cpu 0" do
      plugin.run
      expect(plugin[:cpu]).to have_key("0")
    end

    it "has timebase" do
      plugin.run
      expect(plugin[:cpu]).to have_key("timebase")
      expect(plugin[:cpu]["timebase"]).to eq("512000000")
    end

    it "has platform" do
      plugin.run
      expect(plugin[:cpu]).to have_key("platform")
      expect(plugin[:cpu]["platform"]).to eq("PowerNV")
    end

    it "has model" do
      plugin.run
      expect(plugin[:cpu]).to have_key("model")
      expect(plugin[:cpu]["model"]).to eq("2.2 (pvr 004e 1202)")
    end

    it "has machine_model" do
      plugin.run
      expect(plugin[:cpu]).to have_key("machine_model")
      expect(plugin[:cpu]["machine_model"]).to eq("9006-12P")
    end

    it "has machine" do
      plugin.run
      expect(plugin[:cpu]).to have_key("machine")
      expect(plugin[:cpu]["machine"]).to eq("PowerNV 9006-12P")
    end

    it "has firmware" do
      plugin.run
      expect(plugin[:cpu]).to have_key("firmware")
      expect(plugin[:cpu]["firmware"]).to eq("OPAL")
    end

    it "has mmu" do
      plugin.run
      expect(plugin[:cpu]).to have_key("mmu")
      expect(plugin[:cpu]["mmu"]).to eq("Radix")
    end

    it_behaves_like "ppc64le processor info", 0, "POWER9, altivec supported", "2.2 (pvr 004e 1202)", "2166.000000MHz"

    it "has architecture" do
      plugin.run
      expect(plugin[:cpu]).to have_key("architecture")
      expect(plugin[:cpu]["architecture"]).to eq("ppc64le")
    end

    it "has byte_order" do
      plugin.run
      expect(plugin[:cpu]).to have_key("byte_order")
      expect(plugin[:cpu]["byte_order"]).to eq("little endian")
    end

    it "has cpus" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cpus")
      expect(plugin[:cpu]["cpus"]).to eq(128)
    end

    it "has cpus_online" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cpus_online")
      expect(plugin[:cpu]["cpus_online"]).to eq(32)
    end

    it "has cpus_offline" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cpus_offline")
      expect(plugin[:cpu]["cpus_offline"]).to eq(96)
    end

    it "has threads_per_core" do
      plugin.run
      expect(plugin[:cpu]).to have_key("threads_per_core")
      expect(plugin[:cpu]["threads_per_core"]).to eq(1)
    end

    it "has cores_per_socket" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cores_per_socket")
      expect(plugin[:cpu]["cores_per_socket"]).to eq(16)
    end

    it "has sockets" do
      plugin.run
      expect(plugin[:cpu]).to have_key("sockets")
      expect(plugin[:cpu]["sockets"]).to eq(2)
    end

    it "has numa_nodes" do
      plugin.run
      expect(plugin[:cpu]).to have_key("numa_nodes")
      expect(plugin[:cpu]["numa_nodes"]).to eq(2)
    end

    it "has model" do
      plugin.run
      expect(plugin[:cpu]).to have_key("model")
      expect(plugin[:cpu]["model"]).to eq("2.2 (pvr 004e 1202)")
    end

    it "has model_name" do
      plugin.run
      expect(plugin[:cpu]).to have_key("model_name")
      expect(plugin[:cpu]["model_name"]).to eq("POWER9, altivec supported")
    end

    it "has mhz_max" do
      plugin.run
      expect(plugin[:cpu]).to have_key("mhz_max")
      expect(plugin[:cpu]["mhz_max"]).to eq("3800.0000")
    end

    it "has mhz_min" do
      plugin.run
      expect(plugin[:cpu]).to have_key("mhz_min")
      expect(plugin[:cpu]["mhz_min"]).to eq("2166.0000")
    end

    it "has l1d_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l1d_cache")
      expect(plugin[:cpu]["l1d_cache"]).to eq("32K")
    end

    it "has l1i_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l1i_cache")
      expect(plugin[:cpu]["l1i_cache"]).to eq("32K")
    end

    it "has l2_cache" do
      plugin.run
      expect(plugin[:cpu]).to have_key("l2_cache")
      expect(plugin[:cpu]["l2_cache"]).to eq("512K")
    end

    it "has numa_node_cpus" do
      plugin.run
      expect(plugin[:cpu]).to have_key("numa_node_cpus")
      expect(plugin[:cpu]["numa_node_cpus"]).to \
        eq(
          {
            "0" => [0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60],
            "8" => [64, 68, 72, 76, 80, 84, 88, 92, 96, 100, 104, 108, 112, 116, 120, 124],
          }
        )
    end
  end
end
