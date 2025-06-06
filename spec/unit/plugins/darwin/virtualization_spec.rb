#
# Author:: Pavel Yudin (<pyudin@parallels.com>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2015 Pavel Yudin
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

describe Ohai::System, "Darwin virtualization platform" do
  let(:plugin) { get_plugin("darwin/virtualization") }
  let(:ioreg_vm) do
    <<-IOREG
      | |   +-o pci1ab8,4000@3  <class IOPCIDevice, id 0x1000001d1, registered, matched, active, busy 0 (40 ms), retain 9>
      | |   | | {
      | |   | |   "compatible" = <"pci1ab8,400","pci1ab8,4000","pciclass,ff0000">
      | |   | |   "subsystem-vendor-id" = <b81a0000>
      | |   | |   "IOName" = "pci1ab8,4000"
      | |   | |   "reg" = <00180000000000000000000000000000000000001018000100000000000000000000000020000000>
      | |   | |   "device-id" = <00400000>
      | |   | |   "assigned-addresses" = <101800810000000040d200000000000020000000>
      | |   | |   "IOPowerManagement" = {"MaxPowerState"=3,"ChildProxyPowerState"=2,"CurrentPowerState"=2}
      | |   | |   "IOPCIResourced" = Yes
      | |   | |   "IODeviceMemory" = ("IOSubMemoryDescriptor is not serializable")
      | |   | |   "revision-id" = <00000000>
      | |   | |   "IOInterruptControllers" = ("IOPCIMessagedInterruptController")
      | |   | |   "vendor-id" = <b81a0000>
      | |   | |   "pcidebug" = "0:3:0"
      | |   | |   "class-code" = <0000ff00>
      | |   | |   "IOInterruptSpecifiers" = (<0000000000000100>)
      | |   | |   "IOPCIMSIMode" = Yes
      | |   | |   "subsystem-id" = <00040000>
      | |   | |   "name" = <"pci1ab8,4000">
      | |   | | }
    IOREG
  end
  let(:ioreg_not_vm) do
    <<-IOREG
      | |   +-o pci8086,2445@1F,4  <class IOPCIDevice, id 0x1000001d4, registered, matched, active, busy 0 (974 ms), retain 11>
      | |     | {
      | |     |   "compatible" = <"pci1ab8,400","pci8086,2445","pciclass,040100">
      | |     |   "subsystem-vendor-id" = <b81a0000>
      | |     |   "IOName" = "pci8086,2445"
      | |     |   "reg" = <00fc00000000000000000000000000000000000010fc00010000000000000000000000000001000014fc000100000000000000000000000000010000>
      | |     |   "device-id" = <45240000>
      | |     |   "assigned-addresses" = <10fc00810000000000d10000000000000001000014fc00810000000000d000000000000000010000>
      | |     |   "IOPowerManagement" = {"ChildrenPowerState"=2,"CurrentPowerState"=2,"ChildProxyPowerState"=2,"MaxPowerState"=3}
      | |     |   "IOPCIResourced" = Yes
      | |     |   "IODeviceMemory" = ("IOSubMemoryDescriptor is not serializable","IOSubMemoryDescriptor is not serializable")
      | |     |   "revision-id" = <02000000>
      | |     |   "IOInterruptControllers" = ("io-apic-0")
      | |     |   "vendor-id" = <86800000>
      | |     |   "pcidebug" = "0:31:4"
      | |     |   "class-code" = <00010400>
      | |     |   "IOInterruptSpecifiers" = (<1100000007000000>)
      | |     |   "subsystem-id" = <00040000>
      | |     |   "name" = <"pci8086,2445">
      | |     | }
    IOREG
  end

  before do
    allow(plugin).to receive(:collect_os).and_return(:darwin)
    allow(plugin).to receive(:prlctl_exists?).and_return(false)
    allow(plugin).to receive(:ioreg_exists?).and_return(false)
    allow(plugin).to receive(:sysctl_exists?).and_return(false)
    allow(plugin).to receive(:vboxmanage_exists?).and_return(false)
    allow(plugin).to receive(:fusion_exists?).and_return(false)
    allow(plugin).to receive(:docker_exists?).and_return(false)
    plugin[:hardware] = Mash.new
    plugin[:hardware][:boot_rom_version] = "not_a_vm"
    plugin[:hardware][:machine_model] = "not_a_vm"
  end

  describe "when detecting OS X virtualization" do
    it "does not set virtualization keys if no binaries are found" do
      plugin.run
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end

    it "sets docker host if docker exists" do
      allow(plugin).to receive(:docker_exists?).and_return(true)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("docker")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems][:docker]).to eq("host")
    end

    it "sets vmware host if /Applications/VMware Fusion.app exists" do
      allow(plugin).to receive(:fusion_exists?).and_return(true)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("vmware")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems][:vmware]).to eq("host")
    end

    it "sets vmware guest if hardware attributes mention vmware" do
      plugin[:hardware][:boot_rom_version] = "VMW71.00V.6997262.B64.1710270607"
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("vmware")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:vmware]).to eq("guest")
    end

    it "sets qemu guest if kern.hv_vmm_present equals 1" do
      allow(plugin).to receive(:sysctl_exists?).and_return(true)
      allow(plugin).to receive(:shell_out).with("sysctl -in kern.hv_vmm_present").and_return(mock_shell_out(0, "1\n", ""))
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("qemu")
      expect(plugin[:virtualization][:role]).to eq("guest")
    end

    it "sets vbox host if /usr/local/bin/VBoxManage exists" do
      allow(plugin).to receive(:vboxmanage_exists?).and_return("/usr/local/bin/VBoxManage")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("vbox")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems][:vbox]).to eq("host")
    end

    it "sets vbox guest if hardware attributes mention virtualbox" do
      plugin[:hardware][:boot_rom_version] = "VirtualBox"
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("vbox")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:vbox]).to eq("guest")
    end

    it "sets parallels guest if /usr/local/bin/prlctl exists, /usr/sbin/ioreg exists, and ioreg's output contains pci1ab8,4000" do
      allow(plugin).to receive(:prlctl_exists?).and_return("/usr/local/bin/prlctl")
      allow(plugin).to receive(:ioreg_exists?).and_return(true)
      shellout = double("shellout")
      allow(shellout).to receive(:stdout).and_return(ioreg_vm)
      allow(plugin).to receive(:shell_out).with("ioreg -l").and_return(shellout)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("parallels")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:parallels]).to eq("guest")
    end

    it "sets parallels guest if /usr/local/bin/prlctl does not exists, /usr/sbin/ioreg exists, and ioreg's output contains pci1ab8,4000" do
      allow(plugin).to receive(:ioreg_exists?).and_return(true)
      shellout = double("shellout")
      allow(shellout).to receive(:stdout).and_return(ioreg_vm)
      allow(plugin).to receive(:shell_out).with("ioreg -l").and_return(shellout)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("parallels")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:parallels]).to eq("guest")
    end

    it "sets parallels host if /usr/local/bin/prlctl exists, /usr/sbin/ioreg exists, and ioreg's output does not contain pci1ab8,4000" do
      allow(plugin).to receive(:prlctl_exists?).and_return("/usr/local/bin/prlctl")
      allow(plugin).to receive(:ioreg_exists?).and_return(true)
      shellout = double("shellout")
      allow(shellout).to receive(:stdout).and_return(ioreg_not_vm)
      allow(plugin).to receive(:shell_out).with("ioreg -l").and_return(shellout)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("parallels")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems][:parallels]).to eq("host")
    end

    it "does not set parallels guest if /usr/local/bin/prlctl does not exist, /usr/sbin/ioreg exists, and ioreg's output does not contain pci1ab8,4000" do
      allow(plugin).to receive(:ioreg_exists?).and_return(true)
      shellout = double("shellout")
      allow(shellout).to receive(:stdout).and_return(ioreg_not_vm)
      allow(plugin).to receive(:shell_out).with("ioreg -l").and_return(shellout)
      plugin.run
      expect(plugin[:virtualization]).to eq({ "systems" => {} })
    end

    it "sets apple guest if hardware attributes mention VirtualMac" do
      plugin[:hardware][:machine_model] = "VirtualMac2,1"
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("apple")
      expect(plugin[:virtualization][:role]).to eq("guest")
    end
  end
end
