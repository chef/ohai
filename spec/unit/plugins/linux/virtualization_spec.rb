#
# Author:: Thom May (<thom@clearairturbulence.org>)
# Copyright:: Copyright (c) 2009-2016 Chef Software, Inc.
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

describe Ohai::System, "Linux virtualization platform" do
  let(:plugin) { get_plugin("linux/virtualization") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)

    # default to all requested Files not existing
    allow(File).to receive(:exist?).with("/proc/xen").and_return(false)
    allow(File).to receive(:exist?).with("/proc/xen/capabilities").and_return(false)
    allow(File).to receive(:exist?).with("/proc/modules").and_return(false)
    allow(File).to receive(:exist?).with("/proc/cpuinfo").and_return(false)
    allow(File).to receive(:exist?).with("/var/lib/hyperv/.kvp_pool_3").and_return(false)
    allow(File).to receive(:exist?).with("/proc/self/status").and_return(false)
    allow(File).to receive(:exist?).with("/proc/bc/0").and_return(false)
    allow(File).to receive(:exist?).with("/proc/vz").and_return(false)
    allow(File).to receive(:exist?).with("/proc/self/cgroup").and_return(false)
    allow(File).to receive(:exist?).with("/.dockerenv").and_return(false)
    allow(File).to receive(:exist?).with("/.dockerinit").and_return(false)
    allow(File).to receive(:exist?).with("/sys/devices/virtual/misc/kvm").and_return(false)
    allow(File).to receive(:exist?).with("/dev/lxd/sock").and_return(false)
    allow(File).to receive(:exist?).with("/var/lib/lxd/devlxd").and_return(false)
    allow(File).to receive(:exist?).with("/var/snap/lxd/common/lxd/devlxd").and_return(false)
    allow(File).to receive(:exist?).with("/proc/1/environ").and_return(false)

    # default the which wrappers to nil
    allow(plugin).to receive(:which).with("lxc-version").and_return(nil)
    allow(plugin).to receive(:which).with("lxc-start").and_return(nil)
    allow(plugin).to receive(:which).with("docker").and_return(nil)
    allow(plugin).to receive(:nova_exists?).and_return(false)
  end

  describe "when we are checking for xen" do
    it "sets xen guest if /proc/xen exists but /proc/xen/capabilities does not" do
      expect(File).to receive(:exist?).with("/proc/xen").and_return(true)
      expect(File).to receive(:exist?).with("/proc/xen/capabilities").and_return(false)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("xen")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:xen]).to eq("guest")
    end

    it "sets xen host if /proc/xen/capabilities contains control_d " do
      expect(File).to receive(:exist?).with("/proc/xen").and_return(true)
      expect(File).to receive(:exist?).with("/proc/xen/capabilities").and_return(true)
      allow(File).to receive(:read).with("/proc/xen/capabilities").and_return("control_d")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("xen")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems][:xen]).to eq("host")
    end

    it "sets xen guest if /proc/xen/capabilities exists but is empty" do
      expect(File).to receive(:exist?).with("/proc/xen").and_return(true)
      expect(File).to receive(:exist?).with("/proc/xen/capabilities").and_return(true)
      allow(File).to receive(:read).with("/proc/xen/capabilities").and_return("")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("xen")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:xen]).to eq("guest")
    end

    it "does not set virtualization if xen isn't there" do
      expect(File).to receive(:exist?).at_least(:once).and_return(false)
      plugin.run
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end
  end

  describe "when we are checking for docker" do
    it "sets docker host if docker binary exists" do
      allow(plugin).to receive(:which).with("docker").and_return(true)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("docker")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems][:docker]).to eq("host")
    end
  end

  describe "when we are checking for openstack" do
    it "sets openstack host if nova binary exists" do
      allow(plugin).to receive(:nova_exists?).and_return("/usr/bin/nova")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("openstack")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems][:openstack]).to eq("host")
    end
  end

  describe "when we are checking for kvm" do
    it "sets kvm guest if /sys/devices/virtual/misc/kvm exists & hypervisor cpu feature is present" do
      allow(File).to receive(:exist?).with("/sys/devices/virtual/misc/kvm").and_return(true)
      allow(File).to receive(:read).with("/proc/cpuinfo").and_return("fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss syscall nx rdtscp lm constant_tsc arch_perfmon rep_good nopl pni vmx ssse3 cx16 sse4_1 sse4_2 x2apic popcnt hypervisor lahf_lm vnmi ept tsc_adjust")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("kvm")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:kvm]).to eq("guest")
    end

    it "sets kvm host if /sys/devices/virtual/misc/kvm exists & hypervisor cpu feature is not present" do
      allow(File).to receive(:exist?).with("/sys/devices/virtual/misc/kvm").and_return(true)
      allow(File).to receive(:read).with("/proc/cpuinfo").and_return("fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm dca sse4_1 sse4_2 popcnt lahf_lm ida dtherm tpr_shadow vnmi flexpriority ept vpid")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("kvm")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems][:kvm]).to eq("host")
    end

    it "sets kvm guest if /proc/cpuinfo contains QEMU Virtual CPU" do
      expect(File).to receive(:exist?).with("/proc/cpuinfo").and_return(true)
      allow(File).to receive(:read).with("/proc/cpuinfo").and_return("QEMU Virtual CPU")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("kvm")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:kvm]).to eq("guest")
    end

    it "sets kvm guest if /proc/cpuinfo contains Common KVM processor" do
      expect(File).to receive(:exist?).with("/proc/cpuinfo").and_return(true)
      allow(File).to receive(:read).with("/proc/cpuinfo").and_return("Common KVM processor")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("kvm")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:kvm]).to eq("guest")
    end

    it "sets kvm guest if /proc/cpuinfo contains Common 32-bit KVM processor" do
      expect(File).to receive(:exist?).with("/proc/cpuinfo").and_return(true)
      allow(File).to receive(:read).with("/proc/cpuinfo").and_return("Common 32-bit KVM processor")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("kvm")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:kvm]).to eq("guest")
    end

    it "does not set virtualization if kvm isn't there" do
      expect(File).to receive(:exist?).at_least(:once).and_return(false)
      plugin.run
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end
  end

  describe "when we are checking for VirtualBox" do
    it "sets vbox host if /proc/modules contains vboxdrv" do
      expect(File).to receive(:exist?).with("/proc/modules").and_return(true)
      allow(File).to receive(:read).with("/proc/modules").and_return("vboxdrv 268268 3 vboxnetadp,vboxnetflt")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("vbox")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems][:vbox]).to eq("host")
    end

    it "sets vbox gues if /proc/modules contains vboxguest" do
      expect(File).to receive(:exist?).with("/proc/modules").and_return(true)
      allow(File).to receive(:read).with("/proc/modules").and_return("vboxguest 214901 2 vboxsf, Live 0xffffffffa00db000 (OF)")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("vbox")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:vbox]).to eq("guest")
    end

    it "does not set virtualization if vbox isn't there" do
      expect(File).to receive(:exist?).at_least(:once).and_return(false)
      plugin.run
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end
  end

  describe "when we are parsing DMI data" do

    it "sets virtualization attributes if the appropriate DMI data is present" do
      plugin[:dmi] = { system: {
                                  manufacturer: "Amazon EC2",
                                  product: "c5n.large",
                                  version: nil,
                               },
                     }
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("amazonec2")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:amazonec2]).to eq("guest")
    end

    it "sets empty virtualization attributes if nothing is detected" do
      plugin[:dmi] = { system: {
                                  manufacturer: "Supermicro",
                                  product: "X10SLH-N6-ST031",
                                  version: "0123456789",
                               },
                     }
      plugin.run
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end
  end

  describe "when we are checking for Hyper-V guest and the hostname of the host" do
    it "sets Hyper-V guest if /var/lib/hyperv/.kvp_pool_3 contains hyper_v.example.com" do
      expect(File).to receive(:exist?).with("/var/lib/hyperv/.kvp_pool_3").and_return(true)
      allow(File).to receive(:read).with("/var/lib/hyperv/.kvp_pool_3").and_return("HostNamehyper_v.example.comHostingSystemEditionId")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("hyperv")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems]["hyperv"]).to eq("guest")
      expect(plugin[:virtualization]["hypervisor_host"]).to eq("hyper_v.example.com")
    end
  end

  describe "when we are checking for Linux-VServer" do
    it "sets Linux-VServer host if /proc/self/status contains s_context: 0" do
      expect(File).to receive(:exist?).with("/proc/self/status").and_return(true)
      allow(File).to receive(:read).with("/proc/self/status").and_return("s_context: 0")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("linux-vserver")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems]["linux-vserver"]).to eq("host")
    end

    it "sets Linux-VServer host if /proc/self/status contains VxID: 0" do
      expect(File).to receive(:exist?).with("/proc/self/status").and_return(true)
      allow(File).to receive(:read).with("/proc/self/status").and_return("VxID: 0")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("linux-vserver")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems]["linux-vserver"]).to eq("host")
    end

    it "sets Linux-VServer host if /proc/self/status contains multiple space VxID:   0" do
      expect(File).to receive(:exist?).with("/proc/self/status").and_return(true)
      allow(File).to receive(:read).with("/proc/self/status").and_return("VxID:   0")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("linux-vserver")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems]["linux-vserver"]).to eq("host")
    end

    it "sets Linux-VServer host if /proc/self/status contains tabbed VxID:\t0" do
      expect(File).to receive(:exist?).with("/proc/self/status").and_return(true)
      allow(File).to receive(:read).with("/proc/self/status").and_return("VxID:\t0")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("linux-vserver")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems]["linux-vserver"]).to eq("host")
    end

    it "sets Linux-VServer guest if /proc/self/status contains s_context > 0" do
      expect(File).to receive(:exist?).with("/proc/self/status").and_return(true)
      allow(File).to receive(:read).with("/proc/self/status").and_return("s_context: 2")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("linux-vserver")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems]["linux-vserver"]).to eq("guest")
    end

    it "sets Linux-VServer guest if /proc/self/status contains VxID > 0" do
      expect(File).to receive(:exist?).with("/proc/self/status").and_return(true)
      allow(File).to receive(:read).with("/proc/self/status").and_return("VxID: 2")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("linux-vserver")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems]["linux-vserver"]).to eq("guest")
    end

    it "does not set virtualization if Linux-VServer isn't there" do
      expect(File).to receive(:exist?).at_least(:once).and_return(false)
      plugin.run
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end
  end

  describe "when we are checking for openvz" do
    it "sets openvz host if /proc/bc/0 exists" do
      expect(File).to receive(:exist?).with("/proc/bc/0").and_return(true)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("openvz")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems][:openvz]).to eq("host")
    end

    it "sets openvz guest if /proc/bc/0 does not exist and /proc/vz exists" do
      expect(File).to receive(:exist?).with("/proc/bc/0").and_return(false)
      expect(File).to receive(:exist?).with("/proc/vz").and_return(true)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("openvz")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:openvz]).to eq("guest")
    end

    it "does not set virtualization if openvz isn't there" do
      expect(File).to receive(:exist?).with("/proc/bc/0").and_return(false)
      expect(File).to receive(:exist?).with("/proc/vz").and_return(false)
      plugin.run
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end
  end

  describe "when we are checking for lxd" do
    it "sets lxc guest if /dev/lxd/sock exists" do
      expect(File).to receive(:exist?).with("/dev/lxd/sock").and_return(true)

      plugin.run
      expect(plugin[:virtualization][:system]).to eq("lxd")
      expect(plugin[:virtualization][:role]).to eq("guest")
    end

    it "sets lxd host if /var/lib/lxd/devlxd exists" do
      expect(File).to receive(:exist?).with("/var/lib/lxd/devlxd").and_return(true)

      plugin.run
      expect(plugin[:virtualization][:system]).to eq("lxd")
      expect(plugin[:virtualization][:role]).to eq("host")
    end

    it "sets lxd host if /var/snap/lxd/common/lxd/devlxd exists" do
      expect(File).to receive(:exist?).with("/var/snap/lxd/common/lxd/devlxd").and_return(true)

      plugin.run
      expect(plugin[:virtualization][:system]).to eq("lxd")
      expect(plugin[:virtualization][:role]).to eq("host")
    end
  end

  describe "when we are checking for lxc" do
    it "sets lxc guest if /proc/self/cgroup exist and there are /lxc/<hexadecimal> mounts" do
      self_cgroup = <<~CGROUP
        8:blkio:/lxc/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
        7:net_cls:/lxc/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
        6:freezer:/lxc/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
        5:devices:/lxc/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
        4:memory:/lxc/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
        3:cpuacct:/lxc/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
        2:cpu:/lxc/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
        1:cpuset:/
      CGROUP
      expect(File).to receive(:exist?).with("/proc/self/cgroup").and_return(true)
      allow(File).to receive(:read).with("/proc/self/cgroup").and_return(self_cgroup)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("lxc")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:lxc]).to eq("guest")
    end

    it "sets lxc guest if /proc/self/cgroup exist and there are /lxc/<name> mounts" do
      self_cgroup = <<~CGROUP
        8:blkio:/lxc/vanilla
        7:net_cls:/lxc/vanilla
        6:freezer:/lxc/vanilla
        5:devices:/lxc/vanilla
        4:memory:/lxc/vanilla
        3:cpuacct:/lxc/vanilla
        2:cpu:/lxc/vanilla
        1:cpuset:/lxc/vanilla
      CGROUP
      expect(File).to receive(:exist?).with("/proc/self/cgroup").and_return(true)
      allow(File).to receive(:read).with("/proc/self/cgroup").and_return(self_cgroup)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("lxc")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:lxc]).to eq("guest")
    end

    it "sets not set anything if /proc/self/cgroup exist and the cgroup is named arbitrarily, it isn't necessarily lxc." do
      self_cgroup = <<~CGROUP
        8:blkio:/Charlie
        7:net_cls:/Charlie
        6:freezer:/Charlie
        5:devices:/Charlie
        4:memory:/Charlie
        3:cpuacct:/Charlie
        2:cpu:/Charlie
        1:cpuset:/Charlie
      CGROUP
      allow(File).to receive(:read).with("/proc/1/environ").and_return("")
      expect(File).to receive(:exist?).with("/proc/self/cgroup").and_return(true)
      allow(File).to receive(:read).with("/proc/self/cgroup").and_return(self_cgroup)
      plugin.run
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end

    context "/proc/self/cgroup only has / mounts" do
      before do
        self_cgroup = <<~CGROUP
          8:blkio:/
          7:net_cls:/
          6:freezer:/
          5:devices:/
          4:memory:/
          3:cpuacct:/
          2:cpu:/
          1:cpuset:/
        CGROUP
        expect(File).to receive(:exist?).with("/proc/self/cgroup").and_return(true)
        allow(File).to receive(:read).with("/proc/self/cgroup").and_return(self_cgroup)
        allow(File).to receive(:read).with("/proc/1/environ").and_return("")
      end

      it "sets lxc host if lxc-version exists" do
        allow(plugin).to receive(:which).with("lxc-start").and_return("/usr/bin/lxc-version")
        plugin.run
        expect(plugin[:virtualization][:system]).to eq("lxc")
        expect(plugin[:virtualization][:role]).to eq("host")
        expect(plugin[:virtualization][:systems][:lxc]).to eq("host")
      end

      it "sets lxc host if lxc-start exists" do
        allow(plugin).to receive(:which).with("lxc-start").and_return("/usr/bin/lxc-start")
        plugin.run
        expect(plugin[:virtualization][:system]).to eq("lxc")
        expect(plugin[:virtualization][:role]).to eq("host")
        expect(plugin[:virtualization][:systems][:lxc]).to eq("host")
      end

      it "does not set the old virtualization attributes if they are already set" do
        allow(plugin).to receive(:which).with("lxc-version").and_return("/usr/bin/lxc-version")
        plugin[:virtualization] = Mash.new
        plugin[:virtualization][:system] = "the cloud"
        plugin[:virtualization][:role] = "cumulonimbus"
        plugin.run
        expect(plugin[:virtualization][:system]).not_to eq("lxc")
        expect(plugin[:virtualization][:role]).not_to eq("host")
      end

      it "does not set lxc host if neither lxc-version nor lxc-start exists" do
        plugin.run
        expect(plugin[:virtualization][:system]).to be_nil
        expect(plugin[:virtualization][:role]).to be_nil
        expect(plugin[:virtualization]).to eq({ "systems" => {} })
      end

      it "sets lxc guest if /proc/1/environ has lxccontainer string in it" do
        one_environ = "container=lxccontainer_ttys=/dev/pts/0 /dev/pts/1 /dev/pts/2 /dev/pts/3".chomp
        allow(File).to receive(:read).with("/proc/1/environ").and_return(one_environ)
        plugin.run
        expect(plugin[:virtualization][:system]).to eq("lxc")
        expect(plugin[:virtualization][:role]).to eq("guest")
      end

    end

    it "does not set virtualization if /proc/self/cgroup isn't there" do
      expect(File).to receive(:exist?).with("/proc/self/cgroup").and_return(false)
      plugin.run
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end
  end

  describe "when we are checking for systemd-nspawn" do
    it "sets nspawn guest if /proc/1/environ has nspawn string in it" do
      allow(File).to receive(:exist?).with("/proc/self/cgroup").and_return(true)
      one_environ = "container=systemd-nspawn_ttys=/dev/pts/0 /dev/pts/1 /dev/pts/2 /dev/pts/3".chomp
      allow(File).to receive(:read).with("/proc/1/environ").and_return(one_environ)
      allow(File).to receive(:read).with("/proc/self/cgroup").and_return("")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("nspawn")
      expect(plugin[:virtualization][:role]).to eq("guest")
    end
  end

  describe "when we are checking for docker" do
    it "sets docker guest if /proc/self/cgroup exist and there are /docker/<hexadecimal> mounts" do
      self_cgroup = <<~CGROUP
        8:blkio:/docker/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
        7:net_cls:/docker/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
        6:freezer:/docker/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
        5:devices:/docker/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
        4:memory:/docker/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
        3:cpuacct:/docker/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
        2:cpu:/docker/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
        1:cpuset:/
      CGROUP
      allow(File).to receive(:exist?).with("/proc/self/cgroup").and_return(true)
      allow(File).to receive(:read).with("/proc/self/cgroup").and_return(self_cgroup)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("docker")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:docker]).to eq("guest")
    end

    it "sets docker guest if /proc/self/cgroup exist and there are /docker/<name> mounts" do
      self_cgroup = <<~CGROUP
        8:blkio:/docker/vanilla
        7:net_cls:/docker/vanilla
        6:freezer:/docker/vanilla
        5:devices:/docker/vanilla
        4:memory:/docker/vanilla
        3:cpuacct:/docker/vanilla
        2:cpu:/docker/vanilla
        1:cpuset:/docker/vanilla
      CGROUP
      allow(File).to receive(:exist?).with("/proc/self/cgroup").and_return(true)
      allow(File).to receive(:read).with("/proc/self/cgroup").and_return(self_cgroup)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("docker")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:docker]).to eq("guest")
    end

    it "sets docker guest if /proc/self/cgroup exist and there are /docker/docker-ce/<hexadecimal> mounts" do
      self_cgroup = <<~CGROUP
        13:name=systemd:/docker-ce/docker/b15b85d19304436488a78d06afeb108d94b20bb6898d852b65cad51bd7dc9468
        12:pids:/docker-ce/docker/b15b85d19304436488a78d06afeb108d94b20bb6898d852b65cad51bd7dc9468
        11:hugetlb:/docker-ce/docker/b15b85d19304436488a78d06afeb108d94b20bb6898d852b65cad51bd7dc9468
        10:net_prio:/docker-ce/docker/b15b85d19304436488a78d06afeb108d94b20bb6898d852b65cad51bd7dc9468
        9:perf_event:/docker-ce/docker/b15b85d19304436488a78d06afeb108d94b20bb6898d852b65cad51bd7dc9468
        8:net_cls:/docker-ce/docker/b15b85d19304436488a78d06afeb108d94b20bb6898d852b65cad51bd7dc9468
        7:freezer:/docker-ce/docker/b15b85d19304436488a78d06afeb108d94b20bb6898d852b65cad51bd7dc9468
        6:devices:/docker-ce/docker/b15b85d19304436488a78d06afeb108d94b20bb6898d852b65cad51bd7dc9468
        5:memory:/docker-ce/docker/b15b85d19304436488a78d06afeb108d94b20bb6898d852b65cad51bd7dc9468
        4:blkio:/docker-ce/docker/b15b85d19304436488a78d06afeb108d94b20bb6898d852b65cad51bd7dc9468
        3:cpuacct:/docker-ce/docker/b15b85d19304436488a78d06afeb108d94b20bb6898d852b65cad51bd7dc9468
        2:cpu:/docker-ce/docker/b15b85d19304436488a78d06afeb108d94b20bb6898d852b65cad51bd7dc9468
        1:cpuset:/docker-ce/docker/b15b85d19304436488a78d06afeb108d94b20bb6898d852b65cad51bd7dc9468
      CGROUP
      allow(File).to receive(:exist?).with("/proc/self/cgroup").and_return(true)
      allow(File).to receive(:read).with("/proc/self/cgroup").and_return(self_cgroup)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("docker")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:docker]).to eq("guest")
    end

    # Relevant at least starting docker 1.6.2, kernel 4.0.5 & systemd 224-1.
    # Doi not exactly know which software/version really matters here.
    it "sets docker guest if /proc/self/cgroup exists and there are /system.slice/docker-<hexadecimal> mounts (systemd managed cgroup)" do
      self_cgroup = <<~CGROUP
        8:devices:/system.slice/docker-47341c91be8d491cb3b8a475ad5b4aef6e79bf728cbb351c384e4a6c410f172f.scope
        7:cpuset:/system.slice/docker-47341c91be8d491cb3b8a475ad5b4aef6e79bf728cbb351c384e4a6c410f172f.scope
        6:blkio:/system.slice/docker-47341c91be8d491cb3b8a475ad5b4aef6e79bf728cbb351c384e4a6c410f172f.scope
        5:freezer:/system.slice/docker-47341c91be8d491cb3b8a475ad5b4aef6e79bf728cbb351c384e4a6c410f172f.scope
        4:net_cls:/
        3:memory:/system.slice/docker-47341c91be8d491cb3b8a475ad5b4aef6e79bf728cbb351c384e4a6c410f172f.scope
        2:cpu,cpuacct:/system.slice/docker-47341c91be8d491cb3b8a475ad5b4aef6e79bf728cbb351c384e4a6c410f172f.scope
        1:name=systemd:/system.slice/docker-47341c91be8d491cb3b8a475ad5b4aef6e79bf728cbb351c384e4a6c410f172f.scope
      CGROUP
      allow(File).to receive(:exist?).with("/proc/self/cgroup").and_return(true)
      allow(File).to receive(:read).with("/proc/self/cgroup").and_return(self_cgroup)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("docker")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:docker]).to eq("guest")
    end

    it "sets not set anything if /proc/self/cgroup exist and the cgroup is named arbitrarily, it isn't necessarily lxc." do
      self_cgroup = <<~CGROUP
        8:blkio:/Charlie
        7:net_cls:/Charlie
        6:freezer:/Charlie
        5:devices:/Charlie
        4:memory:/Charlie
        3:cpuacct:/Charlie
        2:cpu:/Charlie
        1:cpuset:/Charlie
      CGROUP
      allow(File).to receive(:exist?).with("/proc/self/cgroup").and_return(true)
      allow(File).to receive(:read).with("/proc/self/cgroup").and_return(self_cgroup)
      allow(File).to receive(:read).with("/proc/1/environ").and_return("")
      plugin.run
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end

    context "/proc/self/cgroup only has / mounts" do
      before do
        self_cgroup = <<~CGROUP
          8:blkio:/
          7:net_cls:/
          6:freezer:/
          5:devices:/
          4:memory:/
          3:cpuacct:/
          2:cpu:/
          1:cpuset:/
        CGROUP
        allow(File).to receive(:exist?).with("/proc/self/cgroup").and_return(true)
        allow(File).to receive(:read).with("/proc/self/cgroup").and_return(self_cgroup)
        plugin.run
        expect(plugin[:virtualization]).to eq({ "systems" => {} })
      end

    end

    it "does not set the old virtualization attributes if they are already set" do
      plugin[:virtualization] = Mash.new
      plugin[:virtualization][:system] = "the cloud"
      plugin[:virtualization][:role] = "cumulonimbus"
      plugin.run
      expect(plugin[:virtualization][:system]).not_to eq("docker")
      expect(plugin[:virtualization][:role]).not_to eq("host")
    end

    it "does not set docker host if docker does not exist" do
      plugin.run
      expect(plugin[:virtualization][:system]).to be_nil
      expect(plugin[:virtualization][:role]).to be_nil
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end

    it "does not set virtualization if /proc/self/cgroup isn't there" do
      allow(File).to receive(:exist?).with("/proc/self/cgroup").and_return(false)
      plugin.run
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end

    it "sets virtualization if /.dockerenv exists" do
      allow(File).to receive(:exist?).with("/.dockerenv").and_return(true)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("docker")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:docker]).to eq("guest")
    end

    it "sets virtualization if /.dockerinit exists" do
      allow(File).to receive(:exist?).with("/.dockerinit").and_return(true)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("docker")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:docker]).to eq("guest")
    end

    it "does not set virtualization if /.dockerenv or /.dockerinit does not exists" do
      allow(File).to receive(:exist?).with("/.dockerenv").and_return(false)
      allow(File).to receive(:exist?).with("/.dockerinit").and_return(false)
      plugin.run
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end

  end

  it "does not set virtualization if no tests match" do
    plugin.run
    expect(plugin[:virtualization]).to eq({ "systems" => {} })
  end
end
