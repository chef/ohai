#
# Author:: Thom May (<thom@clearairturbulence.org>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

describe Ohai::System, "Linux virtualization platform" do
  before(:each) do
    @plugin = get_plugin("linux/virtualization")
    @plugin.stub(:collect_os).and_return(:linux)

    # default to all requested Files not existing
    File.stub(:exists?).with("/proc/xen").and_return(false)
    File.stub(:exists?).with("/proc/xen/capabilities").and_return(false)
    File.stub(:exists?).with("/proc/modules").and_return(false)
    File.stub(:exists?).with("/proc/cpuinfo").and_return(false)
    File.stub(:exists?).with("/usr/sbin/dmidecode").and_return(false)
    File.stub(:exists?).with("/proc/self/status").and_return(false)
    File.stub(:exists?).with("/proc/bc/0").and_return(false)
    File.stub(:exists?).with("/proc/vz").and_return(false)
    File.stub(:exists?).with("/proc/self/cgroup").and_return(false)
  end

  describe "when we are checking for xen" do
    it "should set xen guest if /proc/xen exists but /proc/xen/capabilities does not" do
      File.should_receive(:exists?).with("/proc/xen").and_return(true)
      File.should_receive(:exists?).with("/proc/xen/capabilities").and_return(false)
      @plugin.run
      @plugin[:virtualization][:system].should == "xen"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems][:xen].should == "guest"
    end

    it "should set xen host if /proc/xen/capabilities contains control_d " do
      File.should_receive(:exists?).with("/proc/xen").and_return(true)
      File.should_receive(:exists?).with("/proc/xen/capabilities").and_return(true)
      File.stub(:read).with("/proc/xen/capabilities").and_return("control_d")
      @plugin.run
      @plugin[:virtualization][:system].should == "xen"
      @plugin[:virtualization][:role].should == "host"
      @plugin[:virtualization][:systems][:xen].should == "host"
    end

    it "should set xen guest if /proc/xen/capabilities exists but is empty" do
      File.should_receive(:exists?).with("/proc/xen").and_return(true)
      File.should_receive(:exists?).with("/proc/xen/capabilities").and_return(true)
      File.stub(:read).with("/proc/xen/capabilities").and_return("")
      @plugin.run
      @plugin[:virtualization][:system].should == "xen"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems][:xen].should == "guest"
    end

    it "should not set virtualization if xen isn't there" do
      File.should_receive(:exists?).at_least(:once).and_return(false)
      @plugin.run
      @plugin[:virtualization].should == {'systems' => {}}
    end
  end

  describe "when we are checking for kvm" do
    it "should set kvm host if /proc/modules contains kvm" do
      File.should_receive(:exists?).with("/proc/modules").and_return(true)
      File.stub(:read).with("/proc/modules").and_return("kvm 165872  1 kvm_intel")
      @plugin.run
      @plugin[:virtualization][:system].should == "kvm"
      @plugin[:virtualization][:role].should == "host"
      @plugin[:virtualization][:systems][:kvm].should == "host"
    end

    it "should set kvm guest if /proc/cpuinfo contains QEMU Virtual CPU" do
      File.should_receive(:exists?).with("/proc/cpuinfo").and_return(true)
      File.stub(:read).with("/proc/cpuinfo").and_return("QEMU Virtual CPU")
      @plugin.run
      @plugin[:virtualization][:system].should == "kvm"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems][:kvm].should == "guest"
    end

    it "should set kvm guest if /proc/cpuinfo contains Common KVM processor" do
      File.should_receive(:exists?).with("/proc/cpuinfo").and_return(true)
      File.stub(:read).with("/proc/cpuinfo").and_return("Common KVM processor")
      @plugin.run
      @plugin[:virtualization][:system].should == "kvm"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems][:kvm].should == "guest"
    end

    it "should set kvm guest if /proc/cpuinfo contains Common 32-bit KVM processor" do
      File.should_receive(:exists?).with("/proc/cpuinfo").and_return(true)
      File.stub(:read).with("/proc/cpuinfo").and_return("Common 32-bit KVM processor")
      @plugin.run
      @plugin[:virtualization][:system].should == "kvm"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems][:kvm].should == "guest"
    end

    it "should not set virtualization if kvm isn't there" do
      File.should_receive(:exists?).at_least(:once).and_return(false)
      @plugin.run
      @plugin[:virtualization].should == {'systems' => {}}
    end
  end

  describe "when we are checking for VirtualBox" do
    it "should set vbox host if /proc/modules contains vboxdrv" do
      File.should_receive(:exists?).with("/proc/modules").and_return(true)
      File.stub(:read).with("/proc/modules").and_return("vboxdrv 268268 3 vboxnetadp,vboxnetflt")
      @plugin.run
      @plugin[:virtualization][:system].should == "vbox"
      @plugin[:virtualization][:role].should == "host"
      @plugin[:virtualization][:systems][:vbox].should == "host"
    end

    it "should set vbox gues if /proc/modules contains vboxguest" do
      File.should_receive(:exists?).with("/proc/modules").and_return(true)
      File.stub(:read).with("/proc/modules").and_return("vboxguest 214901 2 vboxsf, Live 0xffffffffa00db000 (OF)")
      @plugin.run
      @plugin[:virtualization][:system].should == "vbox"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems][:vbox].should == "guest"
    end

    it "should not set virtualization if vbox isn't there" do
      File.should_receive(:exists?).at_least(:once).and_return(false)
      @plugin.run
      @plugin[:virtualization].should == {'systems' => {}}
    end
  end

  describe "when we are parsing dmidecode" do
    before(:each) do
      File.should_receive(:exists?).with("/usr/sbin/dmidecode").and_return(true)
    end

    it "should set virtualpc guest if dmidecode detects Microsoft Virtual Machine" do
      ms_vpc_dmidecode=<<-MSVPC
System Information
  Manufacturer: Microsoft Corporation
  Product Name: Virtual Machine
  Version: VS2005R2
  Serial Number: 1688-7189-5337-7903-2297-1012-52
  UUID: D29974A4-BE51-044C-BDC6-EFBC4B87A8E9
  Wake-up Type: Power Switch
MSVPC
      @plugin.stub(:shell_out).with("dmidecode").and_return(mock_shell_out(0, ms_vpc_dmidecode, ""))
      @plugin.run
      @plugin[:virtualization][:system].should == "virtualpc"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems][:virtualpc].should == "guest"
    end

    it "should set vmware guest if dmidecode detects VMware Virtual Platform" do
      vmware_dmidecode=<<-VMWARE
System Information
  Manufacturer: VMware, Inc.
  Product Name: VMware Virtual Platform
  Version: None
  Serial Number: VMware-50 3f f7 14 42 d1 f1 da-3b 46 27 d0 29 b4 74 1d
  UUID: a86cc405-e1b9-447b-ad05-6f8db39d876a
  Wake-up Type: Power Switch
  SKU Number: Not Specified
  Family: Not Specified
VMWARE
      @plugin.stub(:shell_out).with("dmidecode").and_return(mock_shell_out(0, vmware_dmidecode, ""))
      @plugin.run
      @plugin[:virtualization][:system].should == "vmware"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems][:vmware].should == "guest"
    end

    it "should set vbox guest if dmidecode detects Oracle Corporation" do
      vbox_dmidecode=<<-VBOX
Base Board Information
  Manufacturer: Oracle Corporation
  Product Name: VirtualBox
  Version: 1.2
  Serial Number: 0
  Asset Tag: Not Specified
  Features:
        Board is a hosting board
  Location In Chasis: Not Specified
  Type: Motherboard
  Contained Object Handles: 0
VBOX
      @plugin.stub(:shell_out).with("dmidecode").and_return(mock_shell_out(0, vbox_dmidecode, ""))
      @plugin.run
      @plugin[:virtualization][:system].should == "vbox"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems][:vbox].should == "guest"
    end

    it "should run dmidecode and not set virtualization if nothing is detected" do
      @plugin.stub(:shell_out).with("dmidecode").and_return(mock_shell_out(0, "", ""))
      @plugin.run
      @plugin[:virtualization].should == {'systems' => {}}
    end
  end

  describe "when we are checking for Linux-VServer" do
    it "should set Linux-VServer host if /proc/self/status contains s_context: 0" do
      File.should_receive(:exists?).with("/proc/self/status").and_return(true)
      File.stub(:read).with("/proc/self/status").and_return("s_context: 0")
      @plugin.run
      @plugin[:virtualization][:system].should == "linux-vserver"
      @plugin[:virtualization][:role].should == "host"
      @plugin[:virtualization][:systems]['linux-vserver'].should == "host"
    end

    it "should set Linux-VServer host if /proc/self/status contains VxID: 0" do
      File.should_receive(:exists?).with("/proc/self/status").and_return(true)
      File.stub(:read).with("/proc/self/status").and_return("VxID: 0")
      @plugin.run
      @plugin[:virtualization][:system].should == "linux-vserver"
      @plugin[:virtualization][:role].should == "host"
      @plugin[:virtualization][:systems]['linux-vserver'].should == "host"
    end

    it "should set Linux-VServer guest if /proc/self/status contains s_context > 0" do
      File.should_receive(:exists?).with("/proc/self/status").and_return(true)
      File.stub(:read).with("/proc/self/status").and_return("s_context: 2")
      @plugin.run
      @plugin[:virtualization][:system].should == "linux-vserver"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems]['linux-vserver'].should == "guest"
    end

    it "should set Linux-VServer guest if /proc/self/status contains VxID > 0" do
      File.should_receive(:exists?).with("/proc/self/status").and_return(true)
      File.stub(:read).with("/proc/self/status").and_return("VxID: 2")
      @plugin.run
      @plugin[:virtualization][:system].should == "linux-vserver"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems]['linux-vserver'].should == "guest"
    end

    it "should not set virtualization if Linux-VServer isn't there" do
      File.should_receive(:exists?).at_least(:once).and_return(false)
      @plugin.run
      @plugin[:virtualization].should == {'systems' => {}}
    end
  end

  describe "when we are checking for openvz" do
    it "should set openvz host if /proc/bc/0 exists" do
      File.should_receive(:exists?).with("/proc/bc/0").and_return(true)
      @plugin.run
      @plugin[:virtualization][:system].should == "openvz"
      @plugin[:virtualization][:role].should == "host"
      @plugin[:virtualization][:systems][:openvz].should == "host"
    end

    it "should set openvz guest if /proc/bc/0 doesn't exist and /proc/vz exists" do
      File.should_receive(:exists?).with("/proc/bc/0").and_return(false)
      File.should_receive(:exists?).with("/proc/vz").and_return(true)
      @plugin.run
      @plugin[:virtualization][:system].should == "openvz"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems][:openvz].should == "guest"
    end

    it "should not set virtualization if openvz isn't there" do
      File.should_receive(:exists?).with("/proc/bc/0").and_return(false)
      File.should_receive(:exists?).with("/proc/vz").and_return(false)
      @plugin.run
      @plugin[:virtualization].should == {'systems' => {}}
    end
  end

  describe "when we are checking for lxc" do
    it "should set lxc guest if /proc/self/cgroup exist and there are /lxc/<hexadecimal> mounts" do
      self_cgroup=<<-CGROUP
8:blkio:/lxc/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
7:net_cls:/lxc/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
6:freezer:/lxc/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
5:devices:/lxc/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
4:memory:/lxc/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
3:cpuacct:/lxc/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
2:cpu:/lxc/baa660ed81bc81d262ac6e19486142aeec5fce2043e2a173eb2505c6fbed89bc
1:cpuset:/
CGROUP
      File.should_receive(:exists?).with("/proc/self/cgroup").and_return(true)
      File.stub(:read).with("/proc/self/cgroup").and_return(self_cgroup)
      @plugin.run
      @plugin[:virtualization][:system].should == "lxc"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems][:lxc].should == "guest"
    end

    it "should set lxc guest if /proc/self/cgroup exist and there are /lxc/<name> mounts" do
      self_cgroup=<<-CGROUP
8:blkio:/lxc/vanilla
7:net_cls:/lxc/vanilla
6:freezer:/lxc/vanilla
5:devices:/lxc/vanilla
4:memory:/lxc/vanilla
3:cpuacct:/lxc/vanilla
2:cpu:/lxc/vanilla
1:cpuset:/lxc/vanilla
CGROUP
      File.should_receive(:exists?).with("/proc/self/cgroup").and_return(true)
      File.stub(:read).with("/proc/self/cgroup").and_return(self_cgroup)
      @plugin.run
      @plugin[:virtualization][:system].should == "lxc"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems][:lxc].should == "guest"
    end

    it "should set lxc guest if /proc/self/cgroup exist and there are /docker/<name> mounts" do
      self_cgroup=<<-CGROUP
11:hugetlb:/
10:perf_event:/
9:blkio:/
8:net_cls:/
7:freezer:/
6:devices:/
5:memory:/
4:cpuacct,cpu:/docker/9c2adaa4c391ec0d3bf994fbd91ff30c3d317694d179e5b1dc7e1e4c8ed56b61
3:cpuset:/
2:name=systemd:/system.slice/docker.service
CGROUP
      File.should_receive(:exists?).with("/proc/self/cgroup").and_return(true)
      File.stub(:read).with("/proc/self/cgroup").and_return(self_cgroup)
      @plugin.run
      @plugin[:virtualization][:system].should == "lxc"
      @plugin[:virtualization][:role].should == "guest"
      @plugin[:virtualization][:systems][:lxc].should == "guest"
    end

    it "should set not set anything if /proc/self/cgroup exist and the cgroup is named arbitrarily, it isn't necessarily lxc." do
      self_cgroup=<<-CGROUP
8:blkio:/Charlie
7:net_cls:/Charlie
6:freezer:/Charlie
5:devices:/Charlie
4:memory:/Charlie
3:cpuacct:/Charlie
2:cpu:/Charlie
1:cpuset:/Charlie
CGROUP
      File.should_receive(:exists?).with("/proc/self/cgroup").and_return(true)
      File.stub(:read).with("/proc/self/cgroup").and_return(self_cgroup)
      @plugin.run
      @plugin[:virtualization].should == {'systems' => {}}
    end

    context "/proc/self/cgroup only has / mounts" do
      before(:each) do
        self_cgroup=<<-CGROUP
8:blkio:/
7:net_cls:/
6:freezer:/
5:devices:/
4:memory:/
3:cpuacct:/
2:cpu:/
1:cpuset:/
CGROUP
        File.should_receive(:exists?).with("/proc/self/cgroup").and_return(true)
        File.stub(:read).with("/proc/self/cgroup").and_return(self_cgroup)
      end
    
      it "sets lxc host if lxc-version exists" do
        @plugin.stub(:lxc_version_exists?).and_return("/usr/bin/lxc-version")
        @plugin.run
        @plugin[:virtualization][:system].should == "lxc"
        @plugin[:virtualization][:role].should == "host"
        @plugin[:virtualization][:systems][:lxc].should == "host"
      end

      it "does not set the old virtualization attributes if they are already set" do
        @plugin.stub(:lxc_version_exists?).and_return("/usr/bin/lxc-version")
        @plugin[:virtualization] = Mash.new
        @plugin[:virtualization][:system] = "the cloud"
        @plugin[:virtualization][:role] = "cumulonimbus"
        @plugin.run
        @plugin[:virtualization][:system].should_not == "lxc"
        @plugin[:virtualization][:role].should_not == "host"
      end

      it "does not set lxc host if lxc-version does not exist" do
        @plugin.stub(:lxc_version_exists?).and_return(false)
        @plugin.run
        @plugin[:virtualization][:system].should be_nil
        @plugin[:virtualization][:role].should be_nil
        @plugin[:virtualization].should == {'systems' => {}}
      end

    end

    it "should not set virtualization if /proc/self/cgroup isn't there" do
      File.should_receive(:exists?).with("/proc/self/cgroup").and_return(false)
      @plugin.run
      @plugin[:virtualization].should == {'systems' => {}}
    end
  end

  it "should not set virtualization if no tests match" do
    @plugin.run
    @plugin[:virtualization].should == {'systems' => {}}
  end
end
