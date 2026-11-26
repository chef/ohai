# frozen_string_literal: true
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright (c) 2026 Tim Smith
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

# The Linux plugin runs every check in a fixed order and each detection
# overwrites system and role, so the last match wins while systems keeps a
# record of every match. These examples pin that order and the rules that
# depend on it. Examples commented "today's behavior" pin results that look
# wrong; the comment names the open PR that changes them, if there is one.
describe Ohai::System, "Linux virtualization detection order" do
  let(:plugin) { get_plugin("linux/virtualization") }

  # DMI system strings from https://github.com/chef/dmidecode_collection
  let(:openstack_dmi) { ["OpenStack Foundation", "OpenStack Nova", "15.1.5"] } # dreamhost_openstack
  let(:vbox_dmi) { ["innotek GmbH", "VirtualBox", "1.2"] } # virtualbox_5
  let(:hyperv_dmi) { ["Microsoft Corporation", "Virtual Machine", "7.0"] } # azure
  let(:ec2_dmi) { ["Amazon EC2", "c5n.large", "Not Specified"] } # aws_ec2_hypervisor
  # QEMU's default SMBIOS system strings for the i440FX machine type
  # (smbios_set_defaults in QEMU's hw/i386/pc_piix.c)
  let(:qemu_dmi) { ["QEMU", "Standard PC (i440FX + PIIX, 1996)", "pc-i440fx-8.2"] }

  # the model name QEMU's default qemu64 CPU reports in /proc/cpuinfo
  # (target/i386/cpu.c: "QEMU Virtual CPU version " QEMU_HW_VERSION)
  let(:qemu_cpuinfo) { "processor\t: 0\nvendor_id\t: AuthenticAMD\nmodel name\t: QEMU Virtual CPU version 2.5+\nflags\t\t: fpu de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 syscall nx lm nopl cpuid pni cx16 hypervisor lahf_lm svm 3dnowprefetch vmmcall\n" }
  let(:guest_cpu_flags) { "flags\t\t: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss syscall nx rdtscp lm constant_tsc arch_perfmon rep_good nopl pni vmx ssse3 cx16 sse4_1 sse4_2 x2apic popcnt hypervisor lahf_lm vnmi ept tsc_adjust\n" }
  let(:host_cpu_flags) { "flags\t\t: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid\n" }

  # a cgroup v1 host's /proc/self/cgroup: every hierarchy at the root
  let(:root_cgroup) do
    <<~CGROUP
      8:blkio:/
      7:net_cls:/
      6:freezer:/
      5:devices:/
      4:memory:/
      3:cpuacct:/
      2:cpu:/
      1:cpuset:/
    CGROUP
  end

  # a cgroup v2 container's /proc/self/cgroup: the namespace root of the
  # single unified hierarchy ("0::/", see cgroups(7))
  let(:v2_namespace_root_cgroup) { "0::/\n" }

  def set_dmi(manufacturer, product_name, version)
    plugin[:dmi] = { system: { manufacturer: manufacturer, product_name: product_name, version: version } }
  end

  def stub_file(path, content = nil)
    allow(plugin).to receive(:file_exist?).with(path).and_return(true)
    allow(plugin).to receive(:file_read).with(path).and_return(content) unless content.nil?
  end

  def stub_cgroup(cgroup, environ = "")
    stub_file("/proc/self/cgroup", cgroup)
    allow(plugin).to receive(:file_read).with("/proc/1/environ").and_return(environ)
  end

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    # no file or binary exists unless an example says so; stub which rather
    # than the *_exists? helpers so the helpers run
    allow(plugin).to receive(:file_exist?).and_return(false)
    allow(plugin).to receive(:dir_glob).and_return([])
    allow(plugin).to receive(:which).and_return(nil)
  end

  def virt
    plugin[:virtualization]
  end

  describe "DMI after the CPU checks" do
    it "reports an OpenStack guest whose cpuinfo names a QEMU CPU as openstack and keeps kvm in systems" do
      stub_file("/proc/cpuinfo", qemu_cpuinfo)
      set_dmi(*openstack_dmi)
      plugin.run
      expect(virt[:system]).to eq("openstack")
      expect(virt[:role]).to eq("guest")
      expect(virt[:systems][:openstack]).to eq("guest")
      expect(virt[:systems][:kvm]).to eq("guest")
    end

    it "reads the DMI product name from the product_name key" do
      set_dmi(*vbox_dmi)
      plugin.run
      expect(virt[:system]).to eq("vbox")
      expect(virt[:role]).to eq("guest")
      expect(virt[:systems]).to eq("vbox" => "guest")
    end

    # the DMI strings are a Nitro instance's; the /proc/xen pairing is there
    # to show that DMI overrides the Xen check
    it "reports amazonec2 over xen when /proc/xen exists and DMI names Amazon EC2" do
      stub_file("/proc/xen")
      set_dmi(*ec2_dmi)
      plugin.run
      expect(virt[:system]).to eq("amazonec2")
      expect(virt[:role]).to eq("guest")
      expect(virt[:systems][:amazonec2]).to eq("guest")
      expect(virt[:systems][:xen]).to eq("guest")
    end
  end

  describe "the host checks" do
    # today's behavior; see #2072
    it "reports a KVM guest with the docker binary as kvm and keeps docker host in systems" do
      allow(plugin).to receive(:which).with("docker").and_return("/usr/bin/docker")
      stub_file("/sys/devices/virtual/misc/kvm")
      stub_file("/proc/cpuinfo", guest_cpu_flags)
      plugin.run
      expect(virt[:system]).to eq("kvm")
      expect(virt[:role]).to eq("guest")
      expect(virt[:systems][:kvm]).to eq("guest")
      expect(virt[:systems][:docker]).to eq("host")
    end

    # today's behavior; see #2072
    it "reports a host with the nova binary and /dev/kvm as a kvm host and keeps openstack host in systems" do
      allow(plugin).to receive(:which).with("nova").and_return("/usr/bin/nova")
      stub_file("/sys/devices/virtual/misc/kvm")
      stub_file("/proc/cpuinfo", host_cpu_flags)
      plugin.run
      expect(virt[:system]).to eq("kvm")
      expect(virt[:role]).to eq("host")
      expect(virt[:systems][:kvm]).to eq("host")
      expect(virt[:systems][:openstack]).to eq("host")
    end

    # today's behavior; see #2072
    it "reports podman host over docker host when both binaries exist" do
      allow(plugin).to receive(:which).with("docker").and_return("/usr/bin/docker")
      allow(plugin).to receive(:which).with("podman").and_return("/usr/bin/podman")
      plugin.run
      expect(virt[:system]).to eq("podman")
      expect(virt[:role]).to eq("host")
      expect(virt[:systems]).to eq("docker" => "host", "podman" => "host")
    end

    # today's behavior; see #2070 and #2074
    it "reports a kvm guest when /dev/kvm and the hypervisor flag are present under another hypervisor" do
      stub_file("/sys/devices/virtual/misc/kvm")
      stub_file("/proc/cpuinfo", guest_cpu_flags)
      plugin[:cpu] = { hypervisor_vendor: "VMware", virtualization_type: "full" }
      plugin.run
      expect(virt[:system]).to eq("kvm")
      expect(virt[:role]).to eq("guest")
      expect(virt[:systems]).to eq("kvm" => "guest")
    end
  end

  describe "the lscpu fallback" do
    # today's behavior; see #2074
    %w{VMware Microsoft}.each do |vendor|
      it "reports nothing for a #{vendor} hypervisor with full virtualization" do
        plugin[:cpu] = { hypervisor_vendor: vendor, virtualization_type: "full" }
        plugin.run
        expect(virt).to eq("systems" => {})
      end
    end

    # today's behavior
    it "sets system kvm with no role when the KVM hypervisor reports no virtualization type" do
      plugin[:cpu] = { hypervisor_vendor: "KVM", virtualization_type: "none" }
      plugin.run
      expect(virt[:system]).to eq("kvm")
      expect(virt[:role]).to be_nil
      expect(virt[:systems]).to eq({})
    end
  end

  describe "the VirtualBox kernel modules" do
    # /proc/modules lines: name size refcount deps state address (proc(5))
    it "reports a vbox host when both vboxdrv and vboxguest are loaded" do
      stub_file("/proc/modules", "vboxguest 425984 2 vboxsf, Live 0x0000000000000000 (OE)\nvboxdrv 696320 2 vboxnetadp,vboxnetflt, Live 0x0000000000000000 (OE)\n")
      plugin.run
      expect(virt[:system]).to eq("vbox")
      expect(virt[:role]).to eq("host")
      expect(virt[:systems]).to eq("vbox" => "host")
    end

    it "matches the module name only at the start of a line" do
      stub_file("/proc/modules", "foo_vboxdrv 16384 0 - Live 0x0000000000000000\nfoo_vboxguest 16384 0 - Live 0x0000000000000000\n")
      plugin.run
      expect(virt).to eq("systems" => {})
    end
  end

  describe "OpenVZ" do
    it "reports an openvz guest over the DMI result when /proc/vz exists" do
      set_dmi(*qemu_dmi)
      stub_file("/proc/vz")
      plugin.run
      expect(virt[:system]).to eq("openvz")
      expect(virt[:role]).to eq("guest")
      expect(virt[:systems]).to eq("kvm" => "guest", "openvz" => "guest")
    end

    it "reports an openvz host when both /proc/bc/0 and /proc/vz exist" do
      stub_file("/proc/bc/0")
      stub_file("/proc/vz")
      plugin.run
      expect(virt[:system]).to eq("openvz")
      expect(virt[:role]).to eq("host")
      expect(virt[:systems]).to eq("openvz" => "host")
    end
  end

  describe "Hyper-V" do
    # A KVP pool file is an array of records, each a 512-byte key and a
    # 2048-byte value, NUL-padded (struct kvp_record in the Linux kernel's
    # tools/hv/hv_kvp_daemon.c; sizes from HV_KVP_EXCHANGE_MAX_KEY_SIZE and
    # HV_KVP_EXCHANGE_MAX_VALUE_SIZE in include/uapi/linux/hyperv.h). Pool 3
    # holds the host's data, with HostName first.
    def kvp_record(key, value)
      key.ljust(512, "\0") + value.ljust(2048, "\0")
    end

    let(:kvp_pool_3) do
      kvp_record("HostName", "HV-Host01.Example.COM") +
        kvp_record("HostingSystemEditionId", "8") +
        kvp_record("PhysicalHostName", "HV-HOST01")
    end

    it "reports a hyperv guest over the podman host check and records the host name in lower case" do
      allow(plugin).to receive(:which).with("podman").and_return("/usr/bin/podman")
      set_dmi(*hyperv_dmi)
      stub_file("/var/lib/hyperv/.kvp_pool_3", kvp_pool_3)
      plugin.run
      expect(virt[:system]).to eq("hyperv")
      expect(virt[:role]).to eq("guest")
      expect(virt[:systems]).to eq("podman" => "host", "hyperv" => "guest")
      expect(virt[:hypervisor_host]).to eq("hv-host01.example.com")
    end
  end

  describe "container checks from /proc/self/cgroup and /proc/1/environ" do
    { "lxc" => "container=lxc", "nspawn" => "container=systemd-nspawn", "podman" => "container=podman" }.each do |system, environ|
      it "records #{system} guest in systems when /proc/1/environ has #{environ}" do
        stub_cgroup(v2_namespace_root_cgroup, "PATH=/usr/sbin:/usr/bin\0#{environ}\0")
        plugin.run
        expect(virt[:system]).to eq(system)
        expect(virt[:role]).to eq("guest")
        expect(virt[:systems]).to eq(system => "guest")
      end
    end

    # The line format is cgroups(7)'s; the path is made up to reach the lxc
    # alternative of the second cgroup pattern (/<slice>/lxc-<name>), which
    # the first pattern (/lxc/<name>) does not match.
    it "reports an lxc guest for an lxc- cgroup below a top-level cgroup" do
      stub_cgroup("1:name=systemd:/machine.slice/lxc-c1.scope\n")
      plugin.run
      expect(virt[:system]).to eq("lxc")
      expect(virt[:role]).to eq("guest")
      expect(virt[:systems]).to eq("lxc" => "guest")
    end

    it "reports docker from the cgroup even when /proc/1/environ says podman" do
      stub_cgroup("1:name=systemd:/docker/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc\n", "container=podman\0")
      plugin.run
      expect(virt[:system]).to eq("docker")
      expect(virt[:role]).to eq("guest")
      expect(virt[:systems]).to eq("docker" => "guest")
    end

    # today's behavior; see #2061
    it "reports an lxc host when only lxc-version exists" do
      stub_cgroup(root_cgroup)
      allow(plugin).to receive(:which).with("lxc-version").and_return("/usr/bin/lxc-version")
      plugin.run
      expect(virt[:system]).to eq("lxc")
      expect(virt[:role]).to eq("host")
      expect(virt[:systems]).to eq("lxc" => "host")
    end

    it "keeps an already-set system and role but still records lxc host in systems" do
      stub_cgroup(root_cgroup)
      allow(plugin).to receive(:which).with("lxc-start").and_return("/usr/bin/lxc-start")
      plugin[:virtualization] = Mash.new(system: "the cloud", role: "cumulonimbus")
      plugin.run
      expect(virt[:system]).to eq("the cloud")
      expect(virt[:role]).to eq("cumulonimbus")
      expect(virt[:systems]).to eq("lxc" => "host")
    end

    it "keeps a kvm guest found earlier and records lxc host in systems" do
      stub_file("/proc/cpuinfo", qemu_cpuinfo)
      stub_cgroup(root_cgroup)
      allow(plugin).to receive(:which).with("lxc-start").and_return("/usr/bin/lxc-start")
      plugin.run
      expect(virt[:system]).to eq("kvm")
      expect(virt[:role]).to eq("guest")
      expect(virt[:systems]).to eq("kvm" => "guest", "lxc" => "host")
    end
  end

  describe "the Docker and LXD guest files" do
    it "reports a docker guest over the DMI result when /.dockerenv exists" do
      set_dmi(*qemu_dmi)
      stub_file("/.dockerenv")
      plugin.run
      expect(virt[:system]).to eq("docker")
      expect(virt[:role]).to eq("guest")
      expect(virt[:systems]).to eq("kvm" => "guest", "docker" => "guest")
    end

    it "reports an lxd guest over the DMI result when /dev/lxd/sock exists" do
      set_dmi(*qemu_dmi)
      stub_file("/dev/lxd/sock")
      plugin.run
      expect(virt[:system]).to eq("lxd")
      expect(virt[:role]).to eq("guest")
      expect(virt[:systems]).to eq("kvm" => "guest", "lxd" => "guest")
    end

    it "reports an lxd guest, not a host, when /dev/lxd/sock and /var/lib/lxd/devlxd both exist" do
      stub_file("/dev/lxd/sock")
      stub_file("/var/lib/lxd/devlxd")
      plugin.run
      expect(virt[:system]).to eq("lxd")
      expect(virt[:role]).to eq("guest")
      expect(virt[:systems]).to eq("lxd" => "guest")
    end

    ["/var/lib/lxd/devlxd", "/var/snap/lxd/common/lxd/devlxd"].each do |devlxd|
      it "reports an lxd host and records it in systems when only #{devlxd} exists" do
        stub_file(devlxd)
        plugin.run
        expect(virt[:system]).to eq("lxd")
        expect(virt[:role]).to eq("host")
        expect(virt[:systems]).to eq("lxd" => "host")
      end
    end
  end
end
