#
#  Author:: Nimesh Pathi <nimesh.patni@msystechnologies.com>
#  Copyright:: Copyright (c) 2018 Chef Software, Inc.
#  License:: Apache License, Version 2.0
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require "spec_helper"
require "wmi-lite/wmi"

describe Ohai::System, "Windows Filesystem Plugin", :windows_only do
  let(:plugin) { get_plugin("filesystem") }

  let(:success) { true }

  let(:logical_disks_instances) do
    [
      {
        "caption" => "C:",
        "deviceid" => "C:",
        "size" => "10000000",
        "filesystem" => "NTFS",
        "freespace" => "100000",
        "name" => "C:",
        "volumename " => "",
      },
      {
        "caption" => "D:",
        "deviceid" => "D:",
        "size" => "10000000",
        "filesystem" => "FAT32",
        "freespace" => "100000",
        "name" => "D:",
        # Lets not pass "volumename" for this drive
      },
    ]
  end

  let(:encryptable_volume_instances) do
    [
      {
        "conversionstatus" => 0,
        "driveletter" => "C:",
      },
      {
        "conversionstatus" => 2,
        "driveletter" => "D:",
      },
    ]
  end

  let(:wmi_exception) do
    namespace = "Exception while testing"
    exception = WIN32OLERuntimeError.new(namespace)
    WmiLite::WmiException.new(exception, :ConnectServer, @namespace)
  end

  before do
    allow(plugin).to receive(:collect_os).and_return(:windows)
  end

  describe "the plugin" do
    context "when there are no volume names" do
      before do
        allow(plugin).to receive(:logical_info).and_return(plugin.logical_properties(logical_disks_instances))
        allow(plugin).to receive(:encryptable_info).and_return(plugin.encryption_properties(encryptable_volume_instances))
        plugin.run
      end

      it "returns space information" do
        {
          "kb_size" => 10000,
          "kb_available" => 100,
          "kb_used" => 9900,
          "percent_used" => 99,
        }.each do |k, v|
          expect(plugin[:filesystem]["C:"][k]).to eq(v)
          expect(plugin[:filesystem]["D:"][k]).to eq(v)
          expect(plugin[:filesystem2]["by_pair"][",C:"][k]).to eq(v)
          expect(plugin[:filesystem2]["by_pair"][",D:"][k]).to eq(v)
        end
      end

      it "returns disk information" do
        {
          "fs_type" => "ntfs",
          "volume_name" => "",
          "encryption_status" => "FullyDecrypted",
        }.each do |k, v|
          expect(plugin[:filesystem]["C:"][k]).to eq(v)
          expect(plugin[:filesystem2]["by_pair"][",C:"][k]).to eq(v)
        end

        {
          "fs_type" => "fat32",
          "volume_name" => "",
          "encryption_status" => "EncryptionInProgress",
        }.each do |k, v|
          expect(plugin[:filesystem]["D:"][k]).to eq(v)
          expect(plugin[:filesystem2]["by_pair"][",D:"][k]).to eq(v)
        end
      end
    end

    context "when there are volume names" do
      before do
        ldi = logical_disks_instances
        ldi.each_with_index { |d, i| d["volume_name"] = "Volume #{i}" }
        allow(plugin).to receive(:logical_info).and_return(plugin.logical_properties(ldi))
        allow(plugin).to receive(:encryptable_info).and_return(plugin.encryption_properties(encryptable_volume_instances))
        plugin.run
      end

      it "returns space information" do
        {
          "kb_size" => 10000,
          "kb_available" => 100,
          "kb_used" => 9900,
          "percent_used" => 99,
        }.each do |k, v|
          expect(plugin[:filesystem]["C:"][k]).to eq(v)
          expect(plugin[:filesystem]["D:"][k]).to eq(v)
          expect(plugin[:filesystem2]["by_pair"]["volume 0,C:"][k]).to eq(v)
          expect(plugin[:filesystem2]["by_pair"]["volume 1,D:"][k]).to eq(v)
        end
      end

      it "returns disk information" do
        {
          "fs_type" => "ntfs",
          "volume_name" => "volume 0",
          "encryption_status" => "FullyDecrypted",
        }.each do |k, v|
          expect(plugin[:filesystem]["C:"][k]).to eq(v)
          expect(plugin[:filesystem2]["by_pair"]["volume 0,C:"][k]).to eq(v)
        end

        {
          "fs_type" => "fat32",
          "volume_name" => "volume 1",
          "encryption_status" => "EncryptionInProgress",
        }.each do |k, v|
          expect(plugin[:filesystem]["D:"][k]).to eq(v)
          expect(plugin[:filesystem2]["by_pair"]["volume 1,D:"][k]).to eq(v)
        end
      end
    end
  end

  describe "#logical_properties" do
    let(:disks) { logical_disks_instances }
    let(:logical_props) { %i{kb_size kb_available kb_used percent_used mount fs_type volume_name device} }

    it "Returns a mash" do
      expect(plugin.logical_properties(disks)).to be_a(Mash)
    end

    it "Returns an empty mash when blank array is passed" do
      expect(plugin.logical_properties([])).to be_a(Mash)
      expect(plugin.logical_properties([])).to be_empty
    end

    it "Returns properties without values when there is no disk information" do
      data = plugin.logical_properties([{}])
      expect(data[","].symbolize_keys.keys).to eq(logical_props)
      expect(data[","]["kb_used"]).to eq(0)
      expect(data[","]["fs_type"]).to be_empty
    end

    it "Refines required logical properties out of given instance" do
      data = plugin.logical_properties(disks)
      expect(data[",C:"].symbolize_keys.keys).to eq(logical_props)
      expect(data[",D:"].symbolize_keys.keys).to eq(logical_props)
    end

    it "Calculates logical properties out of given instance" do
      data = plugin.logical_properties(disks)
      expect(data[",C:"]["kb_used"]).to eq(data[",D:"]["kb_used"]).and eq(9900)
      expect(data[",C:"]["percent_used"]).to eq(data[",D:"]["percent_used"]).and eq(99)
      expect(data[",C:"]["fs_type"]).to eq("ntfs")
      expect(data[",D:"]["fs_type"]).to eq("fat32")
    end
  end

  describe "#logical_info" do
    it "Returns an empty mash when wmi namespace does not exists" do
      allow(WmiLite::Wmi).to receive(:new).and_raise(wmi_exception)
      expect(plugin.logical_info).to be_a(Mash)
      expect(plugin.logical_info).to be_empty
    end

    it "Returns an empty mash when Win32_LogicalDisk could not be processed" do
      allow(WmiLite::Wmi).to receive(:new).and_return(success)
      allow(success)
        .to receive(:instances_of)
        .with("Win32_LogicalDisk")
        .and_raise(wmi_exception)
      expect(plugin.logical_info).to be_a(Mash)
      expect(plugin.logical_info).to be_empty
    end

    it "Returns a Mash loaded with logical details" do
      allow(WmiLite::Wmi).to receive(:new).and_return(success)
      allow(success)
        .to receive(:instances_of)
        .with("Win32_LogicalDisk")
        .and_return(logical_disks_instances)
      expect(plugin.logical_info).to be_a(Mash)
      expect(plugin.logical_info).not_to be_empty
    end
  end

  describe "#encryption_properties" do
    let(:disks) { encryptable_volume_instances }
    let(:encryption_props) { [:encryption_status] }

    it "Returns a mash" do
      expect(plugin.encryption_properties(disks)).to be_a(Mash)
    end

    it "Returns an empty mash when blank array is passed" do
      expect(plugin.encryption_properties([])).to be_a(Mash)
      expect(plugin.encryption_properties([])).to be_empty
    end

    it "Returns properties without values when there is no disk information" do
      data = plugin.encryption_properties([{}])
      expect(data[nil].symbolize_keys.keys).to eq(encryption_props)
      expect(data[nil]["encryption_status"]).to be_empty
    end

    it "Refines required encryption properties out of given instance" do
      data = plugin.encryption_properties(disks)
      expect(data["C:"].symbolize_keys.keys).to eq(encryption_props)
      expect(data["D:"].symbolize_keys.keys).to eq(encryption_props)
    end

    it "Calculates encryption properties out of given instance" do
      data = plugin.encryption_properties(disks)
      expect(data["C:"]["encryption_status"]).to eq("FullyDecrypted")
      expect(data["D:"]["encryption_status"]).to eq("EncryptionInProgress")
    end
  end

  describe "#encryptable_info" do
    it "Returns an empty mash when wmi namespace does not exists" do
      allow(WmiLite::Wmi).to receive(:new).and_raise(wmi_exception)
      expect(plugin.encryptable_info).to be_a(Mash)
      expect(plugin.encryptable_info).to be_empty
    end

    it "Returns an empty mash when Win32_EncryptableVolume could not be processed" do
      allow(WmiLite::Wmi).to receive(:new).and_return(success)
      allow(success)
        .to receive(:instances_of)
        .with("Win32_EncryptableVolume")
        .and_raise(wmi_exception)
      expect(plugin.encryptable_info).to be_a(Mash)
      expect(plugin.encryptable_info).to be_empty
    end

    it "Returns a Mash loaded with encryption details" do
      allow(WmiLite::Wmi).to receive(:new).and_return(success)
      allow(success)
        .to receive(:instances_of)
        .with("Win32_EncryptableVolume")
        .and_return(encryptable_volume_instances)
      expect(plugin.encryptable_info).to be_a(Mash)
      expect(plugin.encryptable_info).not_to be_empty
    end
  end

  describe "#merge_info" do
    let(:logical_info) do
      { "dev1,drive1" => { "mount" => "drive1", "x" => 10, "y" => "test1" },
        "dev2,drive2" => { "mount" => "drive2", "x" => 20, "z" => "test2" },
        "dev2,drive3" => { "mount" => "drive3", "x" => 20, "z" => "test3" } }
    end
    let(:encryption_info) do
      { "drive1" => { "k" => 10, "l" => "test1" },
        "drive2" => { "l" => 20, "m" => "test2" } }
    end
    let(:logical_info2) { { ",drive1" => { "mount" => "drive1", "o" => 10, "p" => "test1" } } }
    let(:encryption_info2) { { "drive2" => { "q" => 10, "r" => "test1" } } }

    it "Merges all the various properties of filesystems" do
      expect(plugin.merge_info(logical_info, encryption_info)).to eq(
        "dev1,drive1" => { "mount" => "drive1", "x" => 10, "y" => "test1", "k" => 10, "l" => "test1" },
        "dev2,drive2" => { "mount" => "drive2", "x" => 20, "z" => "test2", "l" => 20, "m" => "test2" },
        "dev2,drive3" => { "mount" => "drive3", "x" => 20, "z" => "test3" }
      )
    end

    it "Does not affect any core information after processing" do
      expect(plugin.merge_info(logical_info2, encryption_info2)).to eq(
        ",drive1" => { "mount" => "drive1", "o" => 10, "p" => "test1" },
        ",drive2" => { "q" => 10, "r" => "test1" }
      )
      expect(logical_info2).to eq(",drive1" => { "mount" => "drive1", "o" => 10, "p" => "test1" })
      expect(encryption_info2).to eq("drive2" => { "q" => 10, "r" => "test1" })
    end
  end
end
