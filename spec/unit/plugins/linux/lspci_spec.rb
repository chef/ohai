#
# Author:: Phil Dibowitz <phil@ipom.com>
# Copyright:: Copyright (c) 2017 Facebook, Inc.
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

describe Ohai::System, "Linux lspci plugin" do
  let(:plugin) { get_plugin("linux/lspci") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    @stdout = <<~LSPCI
      Device:	00:1f.3
      Class:	Audio device [0403]
      Vendor:	Intel Corporation [8086]
      Device:	Sunrise Point-LP HD Audio [9d71]
      SVendor:	Lenovo [17aa]
      SDevice:	Sunrise Point-LP HD Audio [224e]
      Rev:	21
      Driver:	snd_hda_intel
      Module:	snd_hda_intel
      Module:	snd_soc_skl

      Device:	00:1f.4
      Class:	SMBus [0c05]
      Vendor:	Intel Corporation [8086]
      Device:	Sunrise Point-LP SMBus [9d23]
      SVendor:	Lenovo [17aa]
      SDevice:	Sunrise Point-LP SMBus [224e]
      Rev:	21
      Driver:	i801_smbus
      Module:	i2c_i801

      Device:	00:1f.6
      Class:	Ethernet controller [0200]
      Vendor:	Intel Corporation [8086]
      Device:	Ethernet Connection (4) I219-LM [15d7]
      SVendor:	Lenovo [17aa]
      SDevice:	Ethernet Connection (4) I219-LM [224e]
      Rev:	21
      Driver:	e1000e
      Module:	e1000e

      Device:	02:00.0
      Class:	Unassigned class [ff00]
      Vendor:	Realtek Semiconductor Co., Ltd. [10ec]
      Device:	RTS525A PCI Express Card Reader [525a]
      SVendor:	Lenovo [17aa]
      SDevice:	RTS525A PCI Express Card Reader [224e]
      Rev:	01
      Driver:	rtsx_pci
      Module:	rtsx_pci

      Device:	04:00.0
      Class:	Network controller [0280]
      Vendor:	Intel Corporation [8086]
      Device:	Wireless 8265 / 8275 [24fd]
      SVendor:	Intel Corporation [8086]
      SDevice:	Wireless 8265 / 8275 [0130]
      Rev:	88
      Driver:	iwlwifi
      Module:	iwlwifi

      Device:	05:00.0
      Class:	Non-Volatile memory controller [0108]
      Vendor:	Toshiba America Info Systems [1179]
      Device:	Device [0115]
      SVendor:	Toshiba America Info Systems [1179]
      SDevice:	Device [0001]
      Rev:	01
      ProgIf:	02
      Driver:	nvme
      Module:	nvme
      NUMANode:	0
    LSPCI
    allow(plugin).to receive(:shell_out).with("lspci -vnnmk").and_return(
      mock_shell_out(0, @stdout, "")
    )
  end

  describe "when gathering data from lspci" do
    it "lists all devices" do
      plugin.run
      expect(plugin[:pci].keys).to eq(
        ["00:1f.3", "00:1f.4", "00:1f.6", "02:00.0", "04:00.0", "05:00.0"]
      )
    end

    it "parses out device name vs id" do
      plugin.run
      expect(plugin[:pci]["04:00.0"]["device_name"]).to eq("Wireless 8265 / 8275")
      expect(plugin[:pci]["04:00.0"]["device_id"]).to eq("24fd")
    end

    it "parses out sdevice name vs id" do
      plugin.run
      expect(plugin[:pci]["04:00.0"]["sdevice_name"]).to eq("Wireless 8265 / 8275")
      expect(plugin[:pci]["04:00.0"]["sdevice_id"]).to eq("0130")
    end

    it "parses out class name vs id" do
      plugin.run
      expect(plugin[:pci]["04:00.0"]["class_name"]).to eq("Network controller")
      expect(plugin[:pci]["04:00.0"]["class_id"]).to eq("0280")
    end

    it "parses out vendor name vs id" do
      plugin.run
      expect(plugin[:pci]["04:00.0"]["vendor_name"]).to eq("Intel Corporation")
      expect(plugin[:pci]["04:00.0"]["vendor_id"]).to eq("8086")
    end

    it "provides drivers and modules" do
      plugin.run
      expect(plugin[:pci]["04:00.0"]["driver"]).to eq(["iwlwifi"])
      expect(plugin[:pci]["04:00.0"]["module"]).to eq(["iwlwifi"])
    end
  end
end
