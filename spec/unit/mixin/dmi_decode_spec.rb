#
# Author:: Tim Smith (tsmith@chef.io)
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
require "ohai/mixin/dmi_decode"

describe Ohai::Mixin::DmiDecode, "guest_from_dmi_data" do
  let(:mixin) { Object.new.extend(described_class) }

  # for the full DMI data used in these tests see https://github.com/chef/dmidecode_collection
  # the fields here are manufacturer, product, and version as passed to #guest_from_dmi_data
  {
    xen: ["Xen", "HVM domU", "4.2.amazon"],
    vmware: ["VMware, Inc.", "VMware Virtual Platform", "None"],
    hyperv: ["Microsoft", "Virtual Machine", "7.0"],
    amazonec2: ["Amazon EC2", "c5n.large", "Not Specified"],
    veertu: ["Veertu", "Veertu", "Not Specified"],
    parallels: ["Parallels Software International Inc.", "Parallels Virtual Platform", "None"],
    vbox: ["Oracle Corporation", "VirtualBox", "1.2"],
    openstack: ["OpenStack Foundation", "", "15.1.5"],
    kvm: ["Red Hat", "KVM", "RHEL 7.0.0 PC (i440FX + PIIX, 1996"],
    bhyve: ["", "BHYVE", "1.0"],
  }.each_pair do |hypervisor, values|
    describe "when passed #{hypervisor} dmi data" do
      it "returns '#{hypervisor}'" do
        expect(mixin.guest_from_dmi_data(values[0], values[1], values[2])).to eq(hypervisor.to_s)
      end
    end
  end

  describe "when passed Redhat's Openstack varient dmi data" do
    it "returns 'openstack'" do
      expect(mixin.guest_from_dmi_data("Red Hat Inc.", "OpenStack Nova", "2014.1.2-1.el6")).to eq("openstack")
    end
  end

  describe "When running on RHEV Hypervisor" do
    it "returns 'kvm'" do
      expect(mixin.guest_from_dmi_data("Red Hat", "RHEV Hypervisor", "6.7-20150911.0.el6ev")).to eq("kvm")
    end
  end

  describe "When the manufactuer is 'QEMU'" do
    it "return kvm" do
      expect(mixin.guest_from_dmi_data("QEMU", "", "")).to eq("kvm")
    end
  end

  describe "returns nil if manufactuer is 'Microsoft', but product is not 'Virtual Machine'" do
    it "returns nil" do
      expect(mixin.guest_from_dmi_data("Microsot", "Zune", "2018")).to be_nil
    end
  end

  # dmidecode System Information from virt-what 1.27's tests/google-cloud
  describe "when running on Google Compute Engine" do
    it "returns 'gce'" do
      expect(mixin.guest_from_dmi_data("Google", "Google Compute Engine", "Not Specified")).to eq("gce")
    end
  end

  # dmidecode System Information from virt-what 1.27's tests/alibaba-cloud-x86
  # and tests/alibaba-cloud-arm
  describe "when running on Alibaba Cloud ECS" do
    it "returns 'alibaba' on x86" do
      expect(mixin.guest_from_dmi_data("Alibaba Cloud", "Alibaba Cloud ECS", "pc-i440fx-2.1")).to eq("alibaba")
    end

    it "returns 'alibaba' on arm64" do
      expect(mixin.guest_from_dmi_data("Alibaba Cloud", "Alibaba Cloud ECS", "virt-rhel7.6.0")).to eq("alibaba")
    end
  end

  # KubeVirt's default SMBIOS manufacturer and product (pkg/virt-config/virt-config.go)
  describe "when running on KubeVirt" do
    it "returns 'kvm'" do
      expect(mixin.guest_from_dmi_data("KubeVirt", "None", nil)).to eq("kvm")
    end
  end

  # dmidecode System Information from virt-what 1.27's tests/nutanix-ahv
  describe "when running on Nutanix AHV" do
    it "returns 'kvm'" do
      expect(mixin.guest_from_dmi_data("Nutanix", "AHV", "RHEL 7.3.0 PC (i440FX + PIIX, 1996)")).to eq("kvm")
    end

    it "returns nil when the Nutanix product isn't AHV" do
      expect(mixin.guest_from_dmi_data("Nutanix", nil, nil)).to be_nil
    end
  end

  # the SMBIOS system entry vdsm gives an oVirt guest (vdsm tests/virt/data/domain.xml)
  describe "when running on oVirt" do
    it "returns 'kvm'" do
      expect(mixin.guest_from_dmi_data("oVirt", "oVirt Node", "7-2.1511.el7.centos.2.10")).to eq("kvm")
    end
  end

  # SeaBIOS's legacy SMBIOS table: manufacturer and product default to
  # BUILD_APPNAME (src/config.h), and the version is left unset
  describe "when running on Bochs" do
    it "returns 'bochs'" do
      expect(mixin.guest_from_dmi_data("Bochs", "Bochs", "Not Specified")).to eq("bochs")
    end
  end

  # VirtualBox's default system vendor (src/VBox/Devices/PC/DevFwCommon.cpp)
  # with the host's product name, as DmiUseHostInfo sets it
  describe "when running on VirtualBox with the host's product name" do
    it "returns 'vbox'" do
      expect(mixin.guest_from_dmi_data("innotek GmbH", "MacBookPro16,1", "1.0")).to eq("vbox")
    end
  end

  describe "When running on an unkown system" do
    it "returns nil" do
      expect(mixin.guest_from_dmi_data("TimCorp", "SuperServer", "2018")).to be_nil
    end
  end
end
