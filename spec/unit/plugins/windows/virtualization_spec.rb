#
# Author:: Pavel Yudin (<pyudin@parallels.com>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2015 Pavel Yudin
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "Windows virtualization platform" do
  let(:plugin) { get_plugin("windows/virtualization") }

  before(:each) do
    allow(plugin).to receive(:collect_os).and_return(:windows)
  end

  context "when running on vmware" do
    it "system is vmware" do
      allow_any_instance_of(WmiLite::Wmi).to receive(:instances_of).with("Win32_BIOS").and_return([{ "bioscharacteristics" => [4, 7, 8, 9, 10, 11, 12, 14, 15, 16, 19, 26, 27, 28, 29, 30, 32, 39, 40, 41, 42, 50, 57, 58],
                                                                                                     "biosversion" => ["INTEL  - 6040000", "PhoenixBIOS 4.0 Release 6.0     "],
                                                                                                     "buildnumber" => nil,
                                                                                                     "caption" => "PhoenixBIOS 4.0 Release 6.0     ",
                                                                                                     "codeset" => nil, "currentlanguage" => nil,
                                                                                                     "description" => "PhoenixBIOS 4.0 Release 6.0     ",
                                                                                                     "identificationcode" => nil,
                                                                                                     "installablelanguages" => nil,
                                                                                                     "installdate" => nil,
                                                                                                     "languageedition" => nil,
                                                                                                     "listoflanguages" => nil,
                                                                                                     "manufacturer" => "Phoenix Technologies LTD",
                                                                                                     "name" => "PhoenixBIOS 4.0 Release 6.0     ",
                                                                                                     "othertargetos" => nil,
                                                                                                     "primarybios" => true,
                                                                                                     "releasedate" => "20130731000000.000000+000",
                                                                                                     "serialnumber" => "VMware-56 4d 65 24 ac cf ec 72-fa 29 b2 7d 8f df b2 7a",
                                                                                                     "smbiosbiosversion" => "6.00",
                                                                                                     "smbiosmajorversion" => 2,
                                                                                                     "smbiosminorversion" => 4,
                                                                                                     "smbiospresent" => true,
                                                                                                     "softwareelementid" => "PhoenixBIOS 4.0 Release 6.0     ",
                                                                                                     "softwareelementstate" => 3,
                                                                                                     "status" => "OK",
                                                                                                     "targetoperatingsystem" => 0,
                                                                                                     "version" => "INTEL  - 6040000"
         }])
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("vmware")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:vmware]).to eq("guest")
    end
  end

  context "when running on parallels desktop" do
    it "system is parallels" do
      allow_any_instance_of(WmiLite::Wmi).to receive(:instances_of).with("Win32_BIOS").and_return([{ "bioscharacteristics" => [4, 7, 9, 10, 15, 24, 25, 27, 28, 29, 30, 32, 42, 44, 48, 49, 51, 64, 65, 67],
                                                                                                     "biosversion" => ["PRLS   - 1"],
                                                                                                     "buildnumber" => nil,
                                                                                                     "caption" => "Default System BIOS",
                                                                                                     "codeset" => nil,
                                                                                                     "currentlanguage" => nil,
                                                                                                     "description" => "Default System BIOS",
                                                                                                     "identificationcode" => nil,
                                                                                                     "installablelanguages" => nil,
                                                                                                     "installdate" => nil,
                                                                                                     "languageedition" => nil,
                                                                                                     "listoflanguages" => nil,
                                                                                                     "manufacturer" => "Parallels Software International Inc.",
                                                                                                     "name" => "Default System BIOS",
                                                                                                     "othertargetos" => nil,
                                                                                                     "primarybios" => true,
                                                                                                     "releasedate" => "20151005000000.000000+000",
                                                                                                     "serialnumber" =>      "Parallels-82 75 A0 A0 9B B4 47 7C 87 A9 D9 E1 2B 90 4B 1F",
                                                                                                     "smbiosbiosversion" => "11.0.2 (31348)",
                                                                                                     "smbiosmajorversion" => 2,
                                                                                                     "smbiosminorversion" => 7,
                                                                                                     "smbiospresent" => true,
                                                                                                     "softwareelementid" => "Default System BIOS",
                                                                                                     "softwareelementstate" => 3,
                                                                                                     "status" => "OK",
                                                                                                     "targetoperatingsystem" => 0,
                                                                                                     "version" => "PRLS   - 1",
         }])
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("parallels")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:parallels]).to eq("guest")
    end
  end

  context "when running on kvm" do
    it "system is kvm" do
      allow_any_instance_of(WmiLite::Wmi).to receive(:instances_of).with("Win32_BIOS").and_return([{ "bioscharacteristics" => [3, 42, 48, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79],
                                                                                                     "biosversion" => ["BOCHS  - 1"],
                                                                                                     "buildnumber" => nil,
                                                                                                     "caption" => "Default System BIOS",
                                                                                                     "codeset" => nil,
                                                                                                     "currentlanguage" => nil,
                                                                                                     "description" => "Default System BIOS",
                                                                                                     "identificationcode" => nil,
                                                                                                     "installablelanguages" => nil,
                                                                                                     "installdate" => nil,
                                                                                                     "languageedition" => nil,
                                                                                                     "listoflanguages" => nil,
                                                                                                     "manufacturer" => "Bochs",
                                                                                                     "name" => "Default System BIOS",
                                                                                                     "othertargetos" => nil,
                                                                                                     "primarybios" => true,
                                                                                                     "releasedate" => "20110101******.******+***",
                                                                                                     "serialnumber" => nil,
                                                                                                     "smbiosbiosversion" => "Bochs",
                                                                                                     "smbiosmajorversion" => 2,
                                                                                                     "smbiosminorversion" => 4,
                                                                                                     "smbiospresent" => true,
                                                                                                     "softwareelementid" => "Default System BIOS",
                                                                                                     "softwareelementstate" => 3,
                                                                                                     "status" => "OK",
                                                                                                     "targetoperatingsystem" => 0, "version" => "BOCHS  -1"
          }])
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("kvm")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:kvm]).to eq("guest")
    end
  end

  context "when running on virtualbox" do
    it "system is vbox" do
      allow_any_instance_of(WmiLite::Wmi).to receive(:instances_of).with("Win32_BIOS").and_return([{ "bioscharacteristics" => [4, 7, 15, 16, 27, 30, 32],
                                                                                                     "biosversion" => ["VBOX   - 1"],
                                                                                                     "buildnumber" => nil,
                                                                                                     "caption" => "Default System BIOS",
                                                                                                     "codeset" => nil,
                                                                                                     "currentlanguage" => nil,
                                                                                                     "description" => "Default System BIOS",
                                                                                                     "identificationcode" => nil,
                                                                                                     "installablelanguages" => nil,
                                                                                                     "installdate" => nil,
                                                                                                     "languageedition" => nil,
                                                                                                     "listoflanguages" => nil,
                                                                                                     "manufacturer" => "innotek GmbH",
                                                                                                     "name" => "Default System BIOS",
                                                                                                     "othertargetos" => nil,
                                                                                                     "primarybios" => true,
                                                                                                     "releasedate" => "20061201000000.000000+000",
                                                                                                     "serialnumber" => "0",
                                                                                                     "smbiosbiosversion" => "VirtualBox",
                                                                                                     "smbiosmajorversion" => 2,
                                                                                                     "smbiosminorversion" => 5,
                                                                                                     "smbiospresent" => true,
                                                                                                     "softwareelementid" => "Default System BIOS",
                                                                                                     "softwareelementstate" => 3,
                                                                                                     "status" => "OK",
                                                                                                     "targetoperatingsystem" => 0,
                                                                                                     "version" => "VBOX   - 1",
        }])
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("vbox")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:vbox]).to eq("guest")
    end
  end

  context "when running on hyper-v" do
    it "system is hyper-v" do
      allow_any_instance_of(WmiLite::Wmi).to receive(:instances_of).with("Win32_BIOS").and_return([{ "bioscharacteristics" => [4, 7, 9, 11, 12, 14, 15, 16, 17, 19, 22, 23, 24, 25, 26, 27, 28, 29, 30, 34, 36, 37, 40],
                                                                                                     "biosversion" => ["VRTUAL - 4001628, BIOS Date: 04/28/16 13:00:17  Ver: 09.00.06, BIOS Date: 04/28/16 13:00:17 Ver: 09.00.06"],
                                                                                                     "buildnumber" => nil,
                                                                                                     "codeset" => nil,
                                                                                                     "currentlanguage" => "enUS",
                                                                                                     "description" => "BIOS Date: 04/28/16 13:00:17  Ver: 09.00.06",
                                                                                                     "identificationcode" => nil,
                                                                                                     "installablelanguages" => 1,
                                                                                                     "installdate" => nil,
                                                                                                     "languageedition" => nil,
                                                                                                     "listoflanguages" => ["enUS"],
                                                                                                     "manufacturer" => "American Megatrends Inc.",
                                                                                                     "name" => "BIOS Date: 04/28/16 13:00:17  Ver: 09.00.06",
                                                                                                     "othertargetos" => nil,
                                                                                                     "primarybios" => true,
                                                                                                     "releasedate" => "20160428000000.000000+000",
                                                                                                     "serialnumber" => "1158-1757-7941-3855-2170-4122-00",
                                                                                                     "smbiosbiosversion" => "090006",
                                                                                                     "smbiosmajorversion" => 2,
                                                                                                     "smbiosminorversion" => 3,
                                                                                                     "smbiospresent" => true,
                                                                                                     "softwareelementid" => "BIOS Date: 04/28/16 13:00:17  Ver: 09.00.06",
                                                                                                     "softwareelementstate" => 3,
                                                                                                     "status" => "OK",
                                                                                                     "targetoperatingsystem" => 0,
                                                                                                     "version" => "VRTUAL - 4001628",
      }])
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("hyper-v")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:hyperv]).to eq("guest")
    end
  end

  context "when running on xen" do
    it "system is xen" do
      allow_any_instance_of(WmiLite::Wmi).to receive(:instances_of).with("Win32_BIOS").and_return([{ "smbiosbiosversion" => ["4.2.amazon"],
                                                                                                     "manufacturer" => "Xen",
                                                                                                     "name" => "Revision: 1.221",
                                                                                                     "serialnumber" => "ec2b487f-d9ed-7d17-c7c0-1d4599d6c1da",
                                                                                                     "version" => "Xen - 0",
      }])
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("xen")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:xen]).to eq("guest")
    end
  end

  context "when running on veertu" do
    it "system is veertu" do
      allow_any_instance_of(WmiLite::Wmi).to receive(:instances_of).with("Win32_BIOS").and_return([{ "smbiosbiosversion" => ["Veertu"],
                                                                                                     "manufacturer" => "Veertu",
                                                                                                     "name" => "Default System BIOS",
                                                                                                     "serialnumber" => "",
                                                                                                     "version" => "Veertu - 1",

      }])
      plugin.run
      expect(plugin[:virtualization][:system]).to eq("veertu")
      expect(plugin[:virtualization][:role]).to eq("guest")
      expect(plugin[:virtualization][:systems][:veertu]).to eq("guest")
    end
  end

  context "when running on a hardware system" do
    it "does not set virtualization attributes" do
      allow_any_instance_of(WmiLite::Wmi).to receive(:instances_of).with("Win32_BIOS").and_return([{ "bioscharacteristics" => [7, 11, 12, 15, 16, 17, 19, 23, 24, 25, 26, 27, 28, 29, 32, 33, 40, 42, 43],
                                                                                                     "biosversion" => ["DELL   - 1072009", "A10", "American Megatrends - 4028D"],
                                                                                                     "buildnumber" => nil,
                                                                                                     "caption" => "A10",
                                                                                                     "codeset" => nil,
                                                                                                     "currentlanguage" => nil,
                                                                                                     "description" => "A10",
                                                                                                     "embeddedcontrollermajorversion" => 255,
                                                                                                     "embeddedcontrollerminorversion" => 255,
                                                                                                     "identificationcode" => nil,
                                                                                                     "installablelanguages" => nil,
                                                                                                     "installdate" => nil,
                                                                                                     "languageedition" => nil,
                                                                                                     "listoflanguages" => nil,
                                                                                                     "manufacturer" => "Dell Inc.",
                                                                                                     "name" => "A10",
                                                                                                     "othertargetos" => nil,
                                                                                                     "primarybios" => true,
                                                                                                     "releasedate" => "20130513000000.000000+000",
                                                                                                     "serialnumber" => "87GBNY1",
                                                                                                     "smbiosbiosversion" => "A10",
                                                                                                     "smbiosmajorversion" => 2,
                                                                                                     "smbiosminorversion" => 7,
                                                                                                     "smbiospresent" => true,
                                                                                                     "softwareelementid" => "A10",
                                                                                                     "softwareelementstate" => 3,
                                                                                                     "status" => "OK",
                                                                                                     "systembiosmajorversion" => 4,
                                                                                                     "systembiosminorversion" => 6,
                                                                                                     "targetoperatingsystem" => 0,
                                                                                                     "version" => "DELL   - 1072009",
        }])
      plugin.run
      expect(plugin[:virtualization]).to eq("systems" => {})
    end
  end
end
