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

shared_examples "Common cpu info" do |total_cpu, real_cpu, ls_cpu, architecture, cpu_opmodes, byte_order, cpus,
  cpus_online, threads_per_core, cores_per_socket, sockets, numa_nodes, vendor_id, model, model_name, bogomips,
  l1d_cache, l1i_cache, l2_cache, l3_cache, flags, numa_node_cpus|
  describe "cpu" do
    it "has cpu[:total] equals to #{total_cpu}" do
      plugin.run
      expect(plugin[:cpu][:total]).to eq(total_cpu)
    end

    it "has a cpu 0" do
      plugin.run
      expect(plugin[:cpu]).to have_key("0")
    end

    if ls_cpu
      it "has cpu[:real] equals to #{real_cpu}" do
        plugin.run
        expect(plugin[:cpu][:real]).to eq(real_cpu)
      end

      it "has architecture equal to #{architecture}" do
        plugin.run
        expect(plugin[:cpu]).to have_key("architecture")
        expect(plugin[:cpu]["architecture"]).to eq(architecture)
      end

      it "has cpu_opmodes equal to #{cpu_opmodes}" do
        plugin.run
        if cpu_opmodes
          expect(plugin[:cpu]).to have_key("cpu_opmodes")
          expect(plugin[:cpu]["cpu_opmodes"]).to eq(cpu_opmodes)
        else
          expect(plugin[:cpu]).to_not have_key("cpu_opmodes")
        end
      end

      it "has byte_order equal to #{byte_order}" do
        plugin.run
        expect(plugin[:cpu]).to have_key("byte_order")
        expect(plugin[:cpu]["byte_order"]).to eq(byte_order)
      end

      it "has cpus equal to #{cpus}" do
        plugin.run
        expect(plugin[:cpu]).to have_key("cpus")
        expect(plugin[:cpu]["cpus"]).to eq(cpus)
      end

      it "has cpus_online equal to #{cpus_online}" do
        plugin.run
        expect(plugin[:cpu]).to have_key("cpus_online")
        expect(plugin[:cpu]["cpus_online"]).to eq(cpus_online)
      end

      it "has threads_per_core equal to #{threads_per_core}" do
        plugin.run
        expect(plugin[:cpu]).to have_key("threads_per_core")
        expect(plugin[:cpu]["threads_per_core"]).to eq(threads_per_core)
      end

      it "has cores_per_socket equal to #{cores_per_socket}" do
        plugin.run
        expect(plugin[:cpu]).to have_key("cores_per_socket")
        expect(plugin[:cpu]["cores_per_socket"]).to eq(cores_per_socket)
      end

      # s390x shows this differently
      it "has sockets equal to #{sockets}" do
        plugin.run
        if sockets
          expect(plugin[:cpu]).to have_key("sockets")
          expect(plugin[:cpu]["sockets"]).to eq(sockets)
        else
          expect(plugin[:cpu]).to_not have_key("sockets")
        end
      end

      it "has numa_nodes equal to #{numa_nodes}" do
        plugin.run
        expect(plugin[:cpu]).to have_key("numa_nodes")
        expect(plugin[:cpu]["numa_nodes"]).to eq(numa_nodes)
      end

      it "has vendor_id equal to #{vendor_id}" do
        plugin.run
        if vendor_id
          expect(plugin[:cpu]).to have_key("vendor_id")
          expect(plugin[:cpu]["vendor_id"]).to eq(vendor_id)
        else
          expect(plugin[:cpu]).to_not have_key("vendor_id")
        end
      end

      it "has model equal to #{model}" do
        plugin.run
        if model
          expect(plugin[:cpu]).to have_key("model")
          expect(plugin[:cpu]["model"]).to eq(model)
        else
          expect(plugin[:cpu]).to_not have_key("model")
        end
      end

      it "has model_name equal to #{model_name}" do
        plugin.run
        if model_name
          expect(plugin[:cpu]).to have_key("model_name")
          expect(plugin[:cpu]["model_name"]).to eq(model_name)
        else
          expect(plugin[:cpu]).to_not have_key("model_name")
        end
      end

      it "has bogomips equal to #{bogomips}" do
        plugin.run
        if bogomips
          expect(plugin[:cpu]).to have_key("bogomips")
          expect(plugin[:cpu]["bogomips"]).to eq(bogomips)
        else
          expect(plugin[:cpu]).to_not have_key("bogomips")
        end
      end

      it "has l1d_cache equal to #{l1d_cache}" do
        plugin.run
        if l1d_cache
          expect(plugin[:cpu]).to have_key("l1d_cache")
          expect(plugin[:cpu]["l1d_cache"]).to eq(l1d_cache)
        else
          expect(plugin[:cpu]).to_not have_key("l1d_cache")
        end
      end

      it "has l1i_cache equal to #{l1i_cache}" do
        plugin.run
        if l1i_cache
          expect(plugin[:cpu]).to have_key("l1i_cache")
          expect(plugin[:cpu]["l1i_cache"]).to eq(l1i_cache)
        else
          expect(plugin[:cpu]).to_not have_key("l1i_cache")
        end
      end

      it "has l2_cache equal to #{l2_cache}" do
        plugin.run
        if l2_cache
          expect(plugin[:cpu]).to have_key("l2_cache")
          expect(plugin[:cpu]["l2_cache"]).to eq(l2_cache)
        else
          expect(plugin[:cpu]).to_not have_key("l2_cache")
        end
      end

      it "has l3_cache equal to #{l3_cache}" do
        plugin.run
        if l3_cache
          expect(plugin[:cpu]).to have_key("l3_cache")
          expect(plugin[:cpu]["l3_cache"]).to eq(l3_cache)
        else
          expect(plugin[:cpu]).to_not have_key("l3_cache")
        end
      end

      it "has flags" do
        plugin.run
        if flags
          expect(plugin[:cpu]).to have_key("flags")
          expect(plugin[:cpu]["flags"]).to eq(flags)
        else
          expect(plugin[:cpu]).to_not have_key("flags")
        end
      end
      it "has numa_node_cpus" do
        plugin.run
        expect(plugin[:cpu]).to have_key("numa_node_cpus")
        expect(plugin[:cpu]["numa_node_cpus"]).to eq(numa_node_cpus)
      end
    end
  end
end

shared_examples "virtualization info" do |virtualization_type, hypervisor_vendor|
  describe "virtualization" do
    it "has virtualization_type equal to #{virtualization_type}" do
      plugin.run
      expect(plugin[:cpu]).to have_key("virtualization_type")
      expect(plugin[:cpu]["virtualization_type"]).to eq(virtualization_type)
    end

    it "has hypervisor_vendor equal to #{hypervisor_vendor}" do
      plugin.run
      expect(plugin[:cpu]).to have_key("hypervisor_vendor")
      expect(plugin[:cpu]["hypervisor_vendor"]).to eq(hypervisor_vendor)
    end
  end
end

shared_examples "x86 processor info" do |family, stepping, mhz|
  describe "x86 processor" do
    it "has family equal to #{family}" do
      plugin.run
      expect(plugin[:cpu]).to have_key("family")
      expect(plugin[:cpu]["family"]).to eq(family)
    end

    it "has stepping equal to #{stepping}" do
      plugin.run
      expect(plugin[:cpu]).to have_key("stepping")
      expect(plugin[:cpu]["stepping"]).to eq(stepping)
    end

    it "has mhz equal to #{mhz}" do
      plugin.run
      expect(plugin[:cpu]).to have_key("mhz")
      expect(plugin[:cpu]["mhz"]).to eq(mhz)
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

shared_examples "ppc64le processor info" do |cpu_no, model_name, model, mhz, timebase, platform, machine_model,
  machine, firmware, mmu|
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

    it "has timebase equal to #{timebase}" do
      plugin.run
      expect(plugin[:cpu]).to have_key("timebase")
      expect(plugin[:cpu]["timebase"]).to eq(timebase)
    end

    it "has platform equal to #{platform}" do
      plugin.run
      expect(plugin[:cpu]).to have_key("platform")
      expect(plugin[:cpu]["platform"]).to eq(platform)
    end

    it "has machine_model equal to #{machine_model}" do
      plugin.run
      expect(plugin[:cpu]).to have_key("machine_model")
      expect(plugin[:cpu]["machine_model"]).to eq(machine_model)
    end

    it "has machine equal to #{machine}" do
      plugin.run
      expect(plugin[:cpu]).to have_key("machine")
      expect(plugin[:cpu]["machine"]).to eq(machine)
    end

    it "has firmware equal to #{firmware}" do
      plugin.run
      if firmware
        expect(plugin[:cpu]).to have_key("firmware")
        expect(plugin[:cpu]["firmware"]).to eq(firmware)
      else
        expect(plugin[:cpu]).to_not have_key("firmware")
      end
    end

    it "has mmu equal to #{mmu}" do
      plugin.run
      if mmu
        expect(plugin[:cpu]).to have_key("mmu")
        expect(plugin[:cpu]["mmu"]).to eq(mmu)
      else
        expect(plugin[:cpu]).to_not have_key("mmu")
      end
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

    it_behaves_like "Common cpu info",
      1,    # total_cpu
      1,    # real_cpu
      false # ls_cpu

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

    flags = %w{acpi aes aperfmperf apic arat arch_perfmon bts clflush cmov constant_tsc cx16 cx8 dca de ds_cpl dtes64 dtherm dts eagerfpu epb ept est flexpriority flush_l1d fpu fxsr ht ibpb ibrs ida intel_stibp lahf_lm lm mca mce mmx monitor msr mtrr nonstop_tsc nopl nx pae pat pbe pcid pclmulqdq pdcm pdpe1gb pebs pge pni popcnt pse pse36 rdtscp rep_good sep smx spec_ctrl ss ssbd sse sse2 sse4_1 sse4_2 ssse3 stibp syscall tm tm2 tpr_shadow tsc vme vmx vnmi vpid xtopology xtpr}
    numa_node_cpus = { "0" => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23] }

    it_behaves_like "Common cpu info",
      24,                 # total_cpu
      2,                  # real_cpu
      true,               # ls_cpu
      "x86_64",           # architecture
      %w{32-bit 64-bit},  # cpu_opmodes
      "little endian",    # byte_order
      24,                 # cpus
      24,                 # cpus_online
      2,                  # threads_per_core
      6,                  # cores_per_socket
      2,                  # sockets
      1,                  # numa_nodes
      "GenuineIntel",     # vendor_id
      "44",               # model
      "Intel(R) Xeon(R) CPU           X5670  @ 2.93GHz", # model_name
      "5851.68",          # bogomips
      "32K",              # l1d_cache
      "32K",              # l1i_cache
      "256K",             # l2_cache
      "12288K",           # l3_cache
      flags,              # flags
      numa_node_cpus      # numa_node_cpus
    it_behaves_like "x86 processor info",
      "6",                # family
      "2",                # stepping
      "2927.000"          # mhz

    it "has virtualization" do
      plugin.run
      expect(plugin[:cpu]).to have_key("virtualization")
      expect(plugin[:cpu]["virtualization"]).to eq("VT-x")
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

  context "x86 guest on kvm" do
    let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-x86-guest-kvm.output")) }
    let(:lscpu) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-x86-guest-kvm.output")) }
    let(:lscpu_cores) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-x86-guest-kvm-cores.output")) }

    before do
      allow(File).to receive(:open).with("/proc/cpuinfo").and_return(cpuinfo_contents)
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(0, lscpu, ""))
      allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(0, lscpu_cores, ""))
    end

    flags = %w{apic clflush cmov cx16 cx8 de eagerfpu fpu fxsr hypervisor lahf_lm lm mca mce mmx msr mtrr nopl nx pae pge pni pse pse36 rep_good sep sse sse2 syscall tsc x2apic xtopology}
    numa_node_cpus = { "0" => [0, 1, 2, 3] }

    it_behaves_like "Common cpu info",
      4,                  # total_cpu
      4,                  # real_cpu
      true,               # ls_cpu
      "x86_64",           # architecture
      %w{32-bit 64-bit},  # cpu_opmodes
      "little endian",    # byte_order
      4,                  # cpus
      4,                  # cpus_online
      1,                  # threads_per_core
      1,                  # cores_per_socket
      4,                  # sockets
      1,                  # numa_nodes
      "GenuineIntel",     # vendor_id
      "13",               # model
      "QEMU Virtual CPU version 2.5+", # model_name
      "6649.99",          # bogomips
      "32K",              # l1d_cache
      "32K",              # l1i_cache
      "4096K",            # l2_cache
      "16384K",           # l3_cache
      flags,              # flags
      numa_node_cpus      # numa_node_cpus
    it_behaves_like "x86 processor info",
      "6",                # family
      "3",                # stepping
      "3324.998"          # mhz
    it_behaves_like "virtualization info",
      "full",             # virtualization_type
      "KVM"               # hypervisor_vendor
  end

  context "x86 guest on kvm (nested)" do
    let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-x86-guest-kvm-nested.output")) }
    let(:lscpu) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-x86-guest-kvm-nested.output")) }
    let(:lscpu_cores) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-x86-guest-kvm-nested-cores.output")) }

    before do
      allow(File).to receive(:open).with("/proc/cpuinfo").and_return(cpuinfo_contents)
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(0, lscpu, ""))
      allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(0, lscpu_cores, ""))
    end

    flags = %w{abm aes apic arat avx avx2 bmi1 bmi2 clflush cmov constant_tsc cx16 cx8 de eagerfpu ept erms f16c flexpriority fma fpu fsgsbase fxsr hypervisor ibpb ibrs intel_stibp invpcid invpcid_single lahf_lm lm mca mce md_clear mmx movbe msr mtrr nopl nx pae pat pcid pclmulqdq pdpe1gb pge pni popcnt pse pse36 rdrand rdtscp rep_good sep smep spec_ctrl ss ssbd sse sse2 sse4_1 sse4_2 ssse3 stibp syscall tpr_shadow tsc tsc_adjust tsc_deadline_timer vme vmx vnmi vpid x2apic xsave xsaveopt xtopology}
    numa_node_cpus = { "0" => [0] }

    it_behaves_like "Common cpu info",
      1,                  # total_cpu
      1,                  # real_cpu
      true,               # ls_cpu
      "x86_64",           # architecture
      %w{32-bit 64-bit},  # cpu_opmodes
      "little endian",    # byte_order
      1,                  # cpus
      0,                  # cpus_online
      1,                  # threads_per_core
      1,                  # cores_per_socket
      1,                  # sockets
      1,                  # numa_nodes
      "GenuineIntel",     # vendor_id
      "60",               # model
      "Intel Core Processor (Haswell, no TSX, IBRS)", # model_name
      "5193.98",          # bogomips
      "32K",              # l1d_cache
      "32K",              # l1i_cache
      "4096K",            # l2_cache
      "16384K",           # l3_cache
      flags,              # flags
      numa_node_cpus      # numa_node_cpus
    it_behaves_like "x86 processor info",
      "6",                # family
      "1",                # stepping
      "2596.990"          # mhz
    it_behaves_like "virtualization info",
      "full",             # virtualization_type
      "KVM"               # hypervisor_vendor

    it "has virtualization" do
      plugin.run
      expect(plugin[:cpu]).to have_key("virtualization")
      expect(plugin[:cpu]["virtualization"]).to eq("VT-x")
    end
  end

  context "x86 guest on xen" do
    let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-x86-guest-xen.output")) }
    let(:lscpu) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-x86-guest-xen.output")) }
    let(:lscpu_cores) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-x86-guest-xen-cores.output")) }

    before do
      allow(File).to receive(:open).with("/proc/cpuinfo").and_return(cpuinfo_contents)
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(0, lscpu, ""))
      allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(0, lscpu_cores, ""))
    end

    flags = %w{clflush cmov constant_tsc cx16 cx8 de eagerfpu fpu fxsr ht hypervisor lahf_lm lm mmx msr nonstop_tsc nopl nx pae pat pni popcnt rep_good sep ss sse sse2 sse4_1 sse4_2 ssse3 syscall tsc}
    numa_node_cpus = { "0" => [0, 1, 2, 3] }

    it_behaves_like "Common cpu info",
      4,                  # total_cpu
      1,                  # real_cpu
      true,               # ls_cpu
      "x86_64",           # architecture
      %w{32-bit 64-bit},  # cpu_opmodes
      "little endian",    # byte_order
      4,                  # cpus
      4,                  # cpus_online
      4,                  # threads_per_core
      1,                  # cores_per_socket
      1,                  # sockets
      1,                  # numa_nodes
      "GenuineIntel",     # vendor_id
      "26",               # model
      "Intel(R) Xeon(R) CPU           L5520  @ 2.27GHz", # model_name
      "4533.49",          # bogomips
      "32K",              # l1d_cache
      "32K",              # l1i_cache
      "256K",             # l2_cache
      "8192K",            # l3_cache
      flags,              # flags
      numa_node_cpus      # numa_node_cpus
    it_behaves_like "x86 processor info",
      "6",                # family
      "5",                # stepping
      "2266.542"          # mhz
    it_behaves_like "virtualization info",
      "para",             # virtualization_type
      "Xen"               # hypervisor_vendor
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

  it_behaves_like "Common cpu info",
    4,    # total_cpu
    nil,  # real_cpu
    false # ls_cpu

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

    flags = %w{dflt dfp edat eimm esan3 etf3eh gs highgprs ldisp msa sort stfle te vx vxd vxe vxe2 vxp zarch}
    numa_node_cpus = { "0" => [0, 1, 2, 3] }

    it_behaves_like "Common cpu info",
      4,                  # total_cpu
      1,                  # real_cpu
      true,               # ls_cpu
      "s390x",            # architecture
      %w{32-bit 64-bit},  # cpu_opmodes
      "big endian",       # byte_order
      4,                  # cpus
      4,                  # cpus_online
      1,                  # threads_per_core
      1,                  # cores_per_socket
      nil,                # sockets
      1,                  # numa_nodes
      "IBM/S390",         # vendor_id
      nil,                # model
      nil,                # model_name
      "3241.00",          # bogomips
      "128K",             # l1d_cache
      "128K",             # l1i_cache
      nil,                # l2_cache
      "262144K",          # l3_cache
      flags,              # flags
      numa_node_cpus      # numa_node_cpus
    it_behaves_like "S390 processor info",
      0,        # cpu_no
      "FF",     # version
      "0618E8", # identification
      "8561",   # machine
      false
    it_behaves_like "S390 processor info",
      1,        # cpu_no
      "FF",     # version
      "0618E8", # identification
      "8561",   # machine
      false

    it "has a cpu 1" do
      plugin.run
      expect(plugin[:cpu]).to have_key("1")
    end

    it "has a bogomips per cpu" do
      plugin.run
      expect(plugin[:cpu]).to have_key("bogomips_per_cpu")
      expect(plugin[:cpu]["bogomips_per_cpu"]).to eql("3241.00")
    end

    it "has features" do
      plugin.run
      expect(plugin[:cpu]).to have_key("features")
      expect(plugin[:cpu]["features"]).to eq(flags)
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
  it_behaves_like "arm64 processor info",
    0,        # cpu_no
    "80.00",  # bogomips
    features  # features
  it_behaves_like "arm64 processor info",
    1,        # cpu_no
    "80.00",  # bogomips
    features  # features

  context "with lscpu data" do
    let(:lscpu) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-aarch64-host.output")) }
    let(:lscpu_cores) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-aarch64-host-cores.output")) }

    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(0, lscpu, ""))
      allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(0, lscpu_cores, ""))
    end

    flags = %w{aes asimd cpuid crc32 evtstrm fp pmull sha1 sha2}
    numa_node_cpus = { "0" => Range.new(0, 31).to_a }

    it_behaves_like "Common cpu info",
      32,                 # total_cpu
      1,                  # real_cpu
      true,               # ls_cpu
      "aarch64",          # architecture
      nil,                # cpu_opmodes
      "little endian",    # byte_order
      32,                 # cpus
      32,                 # cpus_online
      1,                  # threads_per_core
      32,                 # cores_per_socket
      1,                  # sockets
      1,                  # numa_nodes
      nil,                # vendor_id
      "2",                # model
      nil,                # model_name
      "80.00",            # bogomips
      "32K",              # l1d_cache
      "32K",              # l1i_cache
      "256K",             # l2_cache
      nil,                # l3_cache
      flags,              # flags
      numa_node_cpus      # numa_node_cpus
    it_behaves_like "arm64 processor info",
      0,        # cpu_no
      "80.00",  # bogomips
      flags     # features
    it_behaves_like "arm64 processor info",
      1,        # cpu_no
      "80.00",  # bogomips
      flags     # features

    it "has a cpu 1" do
      plugin.run
      expect(plugin[:cpu]).to have_key("1")
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
  end

  context "aarch64 kvm guest" do
    let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-aarch64-guest-kvm.output")) }
    let(:lscpu) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-aarch64-guest-kvm.output")) }
    let(:lscpu_cores) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-aarch64-guest-kvm-cores.output")) }

    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(0, lscpu, ""))
      allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(0, lscpu_cores, ""))
    end

    flags = %w{aes asimd cpuid crc32 evtstrm fp pmull sha1 sha2}
    numa_node_cpus = { "0" => Range.new(0, 1).to_a }

    it_behaves_like "Common cpu info",
      2,                  # total_cpu
      1,                  # real_cpu
      true,               # ls_cpu
      "aarch64",          # architecture
      nil,                # cpu_opmodes
      "little endian",    # byte_order
      2,                  # cpus
      2,                  # cpus_online
      1,                  # threads_per_core
      2,                  # cores_per_socket
      1,                  # sockets
      1,                  # numa_nodes
      nil,                # vendor_id
      "2",                # model
      nil,                # model_name
      "80.00",            # bogomips
      nil,                # l1d_cache
      nil,                # l1i_cache
      nil,                # l2_cache
      nil,                # l3_cache
      flags,              # flags
      numa_node_cpus      # numa_node_cpus
    it_behaves_like "arm64 processor info",
      0,        # cpu_no
      "80.00",  # bogomips
      flags     # features
  end

  context "aarch64 graviton2 guest" do
    let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-aarch64-graviton2.output")) }
    let(:lscpu) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-aarch64-graviton2.output")) }
    let(:lscpu_cores) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-aarch64-graviton2-cores.output")) }

    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(0, lscpu, ""))
      allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(0, lscpu_cores, ""))
    end

    flags = %w{aes asimd asimddp asimdhp asimdrdm atomics cpuid crc32 dcpop evtstrm fp fphp lrcpc pmull sha1 sha2 ssbs}
    numa_node_cpus = { "0" => Range.new(0, 1).to_a }

    it_behaves_like "Common cpu info",
      2,                  # total_cpu
      1,                  # real_cpu
      true,               # ls_cpu
      "aarch64",          # architecture
      %w{32-bit 64-bit},  # cpu_opmodes
      "little endian",    # byte_order
      2,                  # cpus
      2,                  # cpus_online
      1,                  # threads_per_core
      2,                  # cores_per_socket
      1,                  # sockets
      1,                  # numa_nodes
      "ARM",              # vendor_id
      "1",                # model
      "Neoverse-N1",      # model_name
      "243.75",           # bogomips
      "128 KiB",          # l1d_cache
      "128 KiB",          # l1i_cache
      "2 MiB",            # l2_cache
      "32 MiB",           # l3_cache
      flags,              # flags
      numa_node_cpus      # numa_node_cpus
    it_behaves_like "arm64 processor info",
      0,        # cpu_no
      "243.75", # bogomips
      flags     # features

    it "has stepping" do
      plugin.run
      expect(plugin[:cpu]).to have_key("stepping")
      expect(plugin[:cpu]["stepping"]).to eq("r3p1")
    end
  end
end

describe Ohai::System, "ppc64le linux cpu plugin (POWER9)" do
  let(:plugin) { get_plugin("cpu") }
  let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-ppc64le-p9-host.output")) }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(File).to receive(:open).with("/proc/cpuinfo").and_return(cpuinfo_contents)
    allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(1, "", ""))
    allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(1, "", ""))
  end

  it_behaves_like "Common cpu info",
    2,    # total_cpu
    nil,  # real_cpu
    false # ls_cpu

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

    numa_node_cpus =
      {
        "0" => [0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60],
        "8" => [64, 68, 72, 76, 80, 84, 88, 92, 96, 100, 104, 108, 112, 116, 120, 124],
      }

    it_behaves_like "Common cpu info",
      32,                 # total_cpu
      2,                  # real_cpu
      true,               # ls_cpu
      "ppc64le",          # architecture
      nil,                # cpu_opmodes
      "little endian",    # byte_order
      128,                # cpus
      32,                 # cpus_online
      1,                  # threads_per_core
      16,                 # cores_per_socket
      2,                  # sockets
      2,                  # numa_nodes
      nil,                # vendor_id
      "2.2 (pvr 004e 1202)",        # model
      "POWER9, altivec supported",  # model_name
      nil,                # bogomips
      "32K",              # l1d_cache
      "32K",              # l1i_cache
      "512K",             # l2_cache
      "10240K",           # l3_cache
      nil,                # flags
      numa_node_cpus      # numa_node_cpus
    it_behaves_like "ppc64le processor info",
      0,                            # cpu_no
      "POWER9, altivec supported",  # model_name
      "2.2 (pvr 004e 1202)",        # model
      "2166.000000MHz",             # mhz
      "512000000",                  # timebase
      "PowerNV",                    # platform
      "9006-12P",                   # machine_model
      "PowerNV 9006-12P",           # machine
      "OPAL",                       # firmware
      "Radix"                       # mmu

    it "has a cpu 0" do
      plugin.run
      expect(plugin[:cpu]).to have_key("0")
    end

    it "has cpus_offline" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cpus_offline")
      expect(plugin[:cpu]["cpus_offline"]).to eq(96)
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
  end

  context "POWER8 host" do
    let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-ppc64le-p8-host.output")) }
    let(:lscpu) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-ppc64le-p8-host.output")) }
    let(:lscpu_cores) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-ppc64le-p8-host-cores.output")) }

    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(0, lscpu, ""))
      allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(0, lscpu_cores, ""))
    end

    numa_node_cpus =
      {
        "0" => [0, 8, 16, 24, 32],
        "1" => [40, 48, 56, 64, 72],
        "16" => [80, 88, 96, 104, 112],
        "17" => [120, 128, 136, 144, 152],
      }

    it_behaves_like "Common cpu info",
      20,                 # total_cpu
      4,                  # real_cpu
      true,               # ls_cpu
      "ppc64le",          # architecture
      nil,                # cpu_opmodes
      "little endian",    # byte_order
      160,                # cpus
      20,                 # cpus_online
      1,                  # threads_per_core
      5,                  # cores_per_socket
      4,                  # sockets
      4,                  # numa_nodes
      nil,                # vendor_id
      "2.1 (pvr 004b 0201)",              # model
      "POWER8E (raw), altivec supported", # model_name
      nil,                # bogomips
      "64K",              # l1d_cache
      "32K",              # l1i_cache
      "512K",             # l2_cache
      "8192K",            # l3_cache
      nil,                # flags
      numa_node_cpus      # numa_node_cpus
    it_behaves_like "ppc64le processor info",
      0, # cpu_no
      "POWER8E (raw), altivec supported", # model_name
      "2.1 (pvr 004b 0201)",        # model
      "3690.000000MHz",             # mhz
      "512000000",                  # timebase
      "PowerNV",                    # platform
      "8247-22L",                   # machine_model
      "PowerNV 8247-22L",           # machine
      "OPAL",                       # firmware
      "Hash"                        # mmu

    it "has a cpu 0" do
      plugin.run
      expect(plugin[:cpu]).to have_key("0")
    end

    it "has cpus_offline" do
      plugin.run
      expect(plugin[:cpu]).to have_key("cpus_offline")
      expect(plugin[:cpu]["cpus_offline"]).to eq(140)
    end

    it "has mhz_max" do
      plugin.run
      expect(plugin[:cpu]).to have_key("mhz_max")
      expect(plugin[:cpu]["mhz_max"]).to eq("3690.0000")
    end

    it "has mhz_min" do
      plugin.run
      expect(plugin[:cpu]).to have_key("mhz_min")
      expect(plugin[:cpu]["mhz_min"]).to eq("2061.0000")
    end
  end

  context "POWER8 KVM guest" do
    let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-ppc64le-p8-guest-kvm.output")) }
    let(:lscpu) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-ppc64le-p8-guest-kvm.output")) }
    let(:lscpu_cores) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-ppc64le-p8-guest-kvm-cores.output")) }

    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(0, lscpu, ""))
      allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(0, lscpu_cores, ""))
    end

    numa_node_cpus = { "0" => Range.new(0, 15).to_a }

    it_behaves_like "Common cpu info",
      16,                 # total_cpu
      16,                 # real_cpu
      true,               # ls_cpu
      "ppc64le",          # architecture
      nil,                # cpu_opmodes
      "little endian",    # byte_order
      16,                 # cpus
      16,                 # cpus_online
      1,                  # threads_per_core
      1,                  # cores_per_socket
      16,                 # sockets
      1,                  # numa_nodes
      nil,                # vendor_id
      "2.1 (pvr 004b 0201)",                     # model
      "POWER8 (architected), altivec supported", # model_name
      nil,                # bogomips
      "64K",              # l1d_cache
      "32K",              # l1i_cache
      nil,                # l2_cache
      nil,                # l3_cache
      nil,                # flags
      numa_node_cpus      # numa_node_cpus
    it_behaves_like "ppc64le processor info",
      0, # cpu_no
      "POWER8 (architected), altivec supported", # model_name
      "2.1 (pvr 004b 0201)",        # model
      "3425.000000MHz",             # mhz
      "512000000",                  # timebase
      "pSeries",                    # platform
      "IBM pSeries (emulated by qemu)",       # machine_model
      "CHRP IBM pSeries (emulated by qemu)",  # machine
      nil,                          # firmware
      nil                           # mmu

    it_behaves_like "virtualization info",
      "para",             # virtualization_type
      "KVM"               # hypervisor_vendor

    it "has a cpu 0" do
      plugin.run
      expect(plugin[:cpu]).to have_key("0")
    end
  end

  context "POWER9 KVM guest" do
    let(:cpuinfo_contents) { File.read(File.join(SPEC_PLUGIN_PATH, "cpuinfo-ppc64le-p9-guest-kvm.output")) }
    let(:lscpu) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-ppc64le-p9-guest-kvm.output")) }
    let(:lscpu_cores) { File.read(File.join(SPEC_PLUGIN_PATH, "lscpu-ppc64le-p9-guest-kvm-cores.output")) }

    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out).with("lscpu").and_return(mock_shell_out(0, lscpu, ""))
      allow(plugin).to receive(:shell_out).with("lscpu -p=CPU,CORE,SOCKET").and_return(mock_shell_out(0, lscpu_cores, ""))
    end

    numa_node_cpus = { "0" => Range.new(0, 15).to_a }

    it_behaves_like "Common cpu info",
      16,                 # total_cpu
      16,                 # real_cpu
      true,               # ls_cpu
      "ppc64le",          # architecture
      nil,                # cpu_opmodes
      "little endian",    # byte_order
      16,                 # cpus
      16,                 # cpus_online
      1,                  # threads_per_core
      1,                  # cores_per_socket
      16,                 # sockets
      1,                  # numa_nodes
      nil,                # vendor_id
      "2.2 (pvr 004e 1202)",                     # model
      "POWER9 (architected), altivec supported", # model_name
      nil,                # bogomips
      "32K",              # l1d_cache
      "32K",              # l1i_cache
      nil,                # l2_cache
      nil,                # l3_cache
      nil,                # flags
      numa_node_cpus      # numa_node_cpus
    it_behaves_like "ppc64le processor info",
      0, # cpu_no
      "POWER9 (architected), altivec supported", # model_name
      "2.2 (pvr 004e 1202)",        # model
      "2200.000000MHz",             # mhz
      "512000000",                  # timebase
      "pSeries",                    # platform
      "IBM pSeries (emulated by qemu)",       # machine_model
      "CHRP IBM pSeries (emulated by qemu)",  # machine
      nil,                          # firmware
      "Radix"                       # mmu

    it_behaves_like "virtualization info",
      "para",             # virtualization_type
      "KVM"               # hypervisor_vendor

    it "has a cpu 0" do
      plugin.run
      expect(plugin[:cpu]).to have_key("0")
    end
  end
end
