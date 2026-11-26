#
# Author:: Pavel Yudin (<pyudin@parallels.com>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2015 Pavel Yudin
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Ohai::System, "Windows virtualization platform" do
  let(:plugin) { get_plugin("windows/virtualization") }
  let(:wmi) { double("WmiLite::Wmi") }

  let(:vmms_query) { "SELECT Name FROM Win32_Service WHERE Name = 'vmms'" }

  let(:xen_product) do
    { "caption" => "Computer System Product",
      "description" => "Computer System Product",
      "identifyingnumber" => "ec2d6aad-f59b-a10d-5784-ca9b7ba4f727",
      "name" => "HVM domU",
      "skunumber" => nil,
      "uuid" => "EC2D6AAD-F59B-A10D-5784-CA9B7BA4F727",
      "vendor" => "Xen",
      "version" => "4.2.amazon" }
  end

  let(:hardware_product) do
    { "caption" => "Computer System Product",
      "description" => "Computer System Product",
      "identifyingnumber" => "0123456789",
      "name" => "X10SLH-N6-ST031",
      "skunumber" => nil,
      "uuid" => "00000000-0000-0000-0000-0CC47A8F7618",
      "vendor" => "Supermicro",
      "version" => "0123456789" }
  end

  before do
    allow(WmiLite::Wmi).to receive(:new).and_return(wmi)
    allow(plugin).to receive(:collect_os).and_return(:windows)
    allow(wmi).to receive(:first_of).with("Win32_ComputerSystem").and_return({ "hypervisorpresent" => false })
    allow(wmi).to receive(:query).with(vmms_query).and_return([])
  end

  describe "it sets virtualization guest status from Win32_ComputerSystemProduct data" do
    it "system is vmware" do
      allow(wmi).to receive(:first_of).with("Win32_ComputerSystemProduct").and_return(xen_product)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("xen")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:xen]).to eq("guest")
    end
  end

  context "when running on a hardware system" do
    it "does not set virtualization attributes" do
      allow(wmi).to receive(:first_of).with("Win32_ComputerSystemProduct").and_return(hardware_product)
      plugin.run
      expect(plugin[:virtualization]).to eq("systems" => {})
    end
  end

  describe "Hyper-V host detection" do
    def stub_host(product, hypervisor_present:, vmms:)
      allow(wmi).to receive(:first_of).with("Win32_ComputerSystemProduct").and_return(product)
      allow(wmi).to receive(:first_of).with("Win32_ComputerSystem").and_return({ "hypervisorpresent" => hypervisor_present })
      allow(wmi).to receive(:query).with(vmms_query).and_return(vmms ? [{ "name" => "vmms" }] : [])
    end

    it "sets a Hyper-V host when the hypervisor runs and the vmms service exists" do
      stub_host(hardware_product, hypervisor_present: true, vmms: true)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("hyperv")
      expect(plugin[:virtualization][:role]).to eq("host")
      expect(plugin[:virtualization][:systems]).to eq("hyperv" => "host")
    end

    it "does not set a host on hardware running only virtualization based security" do
      stub_host(hardware_product, hypervisor_present: true, vmms: false)
      plugin.run
      expect(plugin[:virtualization]).to eq("systems" => {})
    end

    it "does not set a host when Hyper-V is installed but the hypervisor is not running" do
      stub_host(hardware_product, hypervisor_present: false, vmms: true)
      plugin.run
      expect(plugin[:virtualization]).to eq("systems" => {})
    end

    it "keeps the guest result on a guest that has Hyper-V installed" do
      stub_host(xen_product, hypervisor_present: true, vmms: true)
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("xen")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems]).to eq("xen" => "guest")
    end
  end
end
