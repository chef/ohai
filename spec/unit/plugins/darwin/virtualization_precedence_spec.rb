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

# The darwin plugin runs its checks in a fixed order and each detection
# overwrites system and role, so the last match wins. Examples commented
# "today's behavior" pin results that look wrong; the comment names the open
# PR that changes them.
describe Ohai::System, "Darwin virtualization detection order" do
  let(:plugin) { get_plugin("darwin/virtualization") }

  # the Parallels guest PCI device as ioreg -l lists it
  let(:ioreg_parallels) { "      | |   +-o pci1ab8,4000@3  <class IOPCIDevice, id 0x1000001d1, registered, matched, active, busy 0 (40 ms), retain 9>\n" }

  def hv_vmm_present(value)
    allow(plugin).to receive(:which).with("sysctl").and_return("/usr/sbin/sysctl")
    allow(plugin).to receive(:shell_out).with("sysctl -in kern.hv_vmm_present").and_return(mock_shell_out(0, "#{value}\n", ""))
  end

  before do
    allow(plugin).to receive(:collect_os).and_return(:darwin)
    # no file or binary exists unless an example says so; stub which and
    # file_exist? rather than the *_exists? helpers so the helpers run
    allow(plugin).to receive(:which).and_return(nil)
    allow(plugin).to receive(:file_exist?).and_return(false)
    plugin[:hardware] = Mash.new(boot_rom_version: "not_a_vm", machine_model: "not_a_vm")
  end

  describe "kern.hv_vmm_present" do
    # today's behavior; see #2025
    it "reports a VMware guest as qemu and keeps vmware guest in systems" do
      plugin[:hardware][:boot_rom_version] = "VMW71.00V.6997262.B64.1710270607"
      hv_vmm_present(1)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("qemu")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems]).to eq("vmware" => "guest")
    end

    it "reports an Apple Virtualization guest as apple" do
      plugin[:hardware][:machine_model] = "VirtualMac2,1"
      hv_vmm_present(1)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("apple")
      expect(plugin[:virtualization][:role]).to eq("guest")
      # today's behavior; see #2025
      expect(plugin[:virtualization][:systems]).to eq({})
    end

    # the ioreg command changes in #2057
    it "reports a Parallels guest as parallels" do
      allow(plugin).to receive(:which).with("ioreg").and_return("/usr/sbin/ioreg")
      allow(plugin).to receive(:shell_out).with("ioreg -l").and_return(mock_shell_out(0, ioreg_parallels, ""))
      hv_vmm_present(1)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("parallels")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems]).to eq("parallels" => "guest")
    end

    it "reports nothing when kern.hv_vmm_present is 0" do
      hv_vmm_present(0)
      plugin.run
      expect(plugin[:virtualization]).to eq("systems" => {})
    end
  end

  describe "the binary and path helpers" do
    it "finds VirtualBox from the VBoxManage binary" do
      allow(plugin).to receive(:which).with("VBoxManage").and_return("/usr/local/bin/VBoxManage")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("vbox")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems]).to eq("vbox" => "host")
    end

    it "finds Parallels Desktop from the prlctl binary" do
      allow(plugin).to receive(:which).with("prlctl").and_return("/usr/local/bin/prlctl")
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("parallels")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems]).to eq("parallels" => "host")
    end

    it "runs ioreg only when the ioreg binary exists" do
      expect(plugin).not_to receive(:shell_out).with("ioreg -l")
      plugin.run
      expect(plugin[:virtualization]).to eq("systems" => {})
    end

    it "runs sysctl only when the sysctl binary exists" do
      expect(plugin).not_to receive(:shell_out).with("sysctl -in kern.hv_vmm_present")
      plugin.run
      expect(plugin[:virtualization]).to eq("systems" => {})
    end

    it "finds VMware Fusion from its application bundle" do
      allow(plugin).to receive(:file_exist?).with("/Applications/VMware Fusion.app/").and_return(true)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("vmware")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems]).to eq("vmware" => "host")
    end
  end
end
