#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software
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

SOLARIS_DMI_OUT = <<-EOS
ID    SIZE TYPE
0     64   SMB_TYPE_BIOS (type 0) (BIOS information)

  Vendor: American Megatrends Inc.
  Version String: 4701
  Release Date: 08/26/2014
  Address Segment: 0xf000
  ROM Size: 8388608 bytes
  Image Size: 65536 bytes
  Characteristics: 0x53f8b9c80
        SMB_BIOSFL_PCI (PCI is supported)
        SMB_BIOSFL_APM (APM is supported)
        SMB_BIOSFL_FLASH (BIOS is Flash Upgradeable)
        SMB_BIOSFL_SHADOW (BIOS shadowing is allowed)
        SMB_BIOSFL_CDBOOT (Boot from CD is supported)
        SMB_BIOSFL_SELBOOT (Selectable Boot supported)
        SMB_BIOSFL_ROMSOCK (BIOS ROM is socketed)
        SMB_BIOSFL_EDD (EDD Spec is supported)
        SMB_BIOSFL_525_12M (int 0x13 5.25" 1.2M floppy)
        SMB_BIOSFL_35_720K (int 0x13 3.5" 720K floppy)
        SMB_BIOSFL_35_288M (int 0x13 3.5" 2.88M floppy)
        SMB_BIOSFL_I5_PRINT (int 0x5 print screen svcs)
        SMB_BIOSFL_I9_KBD (int 0x9 8042 keyboard svcs)
        SMB_BIOSFL_I14_SER (int 0x14 serial svcs)
        SMB_BIOSFL_I17_PRINTER (int 0x17 printer svcs)
        0x100000000
        0x400000000
  Characteristics Extension Byte 1: 0x3
        SMB_BIOSXB1_ACPI (ACPI is supported)
        SMB_BIOSXB1_USBL (USB legacy is supported)
  Characteristics Extension Byte 2: 0xd
        SMB_BIOSXB2_BBOOT (BIOS Boot Specification supported)
        SMB_BIOSXB2_ETCDIST (Enable Targeted Content Distrib.)
        SMB_BIOSXB2_UEFI (UEFI Specification supported)
  Version Number: 0.0
  Embedded Ctlr Firmware Version Number: 0.0

ID    SIZE TYPE
1     129  SMB_TYPE_SYSTEM (type 1) (system information)

  Manufacturer: System manufacturer
  Product: System Product Name
  Version: System Version
  Serial Number: System Serial Number

  UUID: 20b1001e-8c00-0072-5566-10c37b474fc1
  Wake-Up Event: 0x6 (power switch)
  SKU Number: SKU
  Family: To be filled by O.E.M.

ID    SIZE TYPE
2     116  SMB_TYPE_BASEBOARD (type 2) (base board)

  Manufacturer: ASUSTeK COMPUTER INC.
  Product: P9X79 WS
  Version: Rev 1.xx
  Serial Number: 140525831000250
  Asset Tag: To be filled by O.E.M.
  Location Tag: To be filled by O.E.M.

  Chassis: 3
  Flags: 0x9
        SMB_BBFL_MOTHERBOARD (board is a motherboard)
        SMB_BBFL_REPLACABLE (board is field-replacable)
  Board Type: 0xa (motherboard)

ID    SIZE TYPE
46    38   SMB_TYPE_OBDEVS (type 10) (on-board devices)

  Onboard Ethernet
  Onboard Audio

ID    SIZE TYPE
3     106  SMB_TYPE_CHASSIS (type 3) (system enclosure or chassis)

  Manufacturer: Chassis Manufacture
  Version: Chassis Version
  Serial Number: Chassis Serial Number
  Asset Tag: PCS

  OEM Data: 0x0
  SKU number: ^E
  Lock Present: N
  Chassis Type: 0x3 (desktop)
  Boot-Up State: 0x3 (safe)
  Power Supply State: 0x3 (safe)
  Thermal State: 0x3 (safe)
  Chassis Height: 0u
  Power Cords: 1
  Element Records: 0
EOS

describe Ohai::System, "Solaris2.X DMI plugin" do
  before(:each) do
    @plugin = get_plugin("solaris2/dmi")
    allow(@plugin).to receive(:collect_os).and_return("solaris2")
    @stdout = SOLARIS_DMI_OUT
    allow(@plugin).to receive(:shell_out).with("smbios").and_return(mock_shell_out(0, @stdout, ""))
  end

  it "should run smbios" do
    expect(@plugin).to receive(:shell_out).with("smbios").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
  end

  {
    bios: {
      vendor: "American Megatrends Inc.",
      release_date: "08/26/2014",
    },
    system: {
      manufacturer: "System manufacturer",
      product: "System Product Name",
    },
    chassis: {
      lock_present: "N",
      asset_tag: "PCS",
    },
  }.each do |id, data|
    data.each do |attribute, value|
      it "should have [:dmi][:#{id}][:#{attribute}] set" do
        @plugin.run
        expect(@plugin[:dmi][id][attribute]).to eql(value)
      end
    end
  end

  it "should ignore unwanted types" do
    @plugin.run
    expect(@plugin[:dmi]).not_to have_key(:on_board_devices)
  end
end
