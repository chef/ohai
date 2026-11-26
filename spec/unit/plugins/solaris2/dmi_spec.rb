#
# Author:: Thom May (<thom@chef.io>)
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

SOLARIS_DMI_OUT = <<~EOS.freeze
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
  before do
    @plugin = get_plugin("solaris2/dmi")
    allow(@plugin).to receive(:collect_os).and_return("solaris2")
    @stdout = SOLARIS_DMI_OUT
    allow(@plugin).to receive(:shell_out).with("smbios").and_return(mock_shell_out(0, @stdout, ""))
  end

  it "runs smbios" do
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
      it "has [:dmi][:#{id}][:#{attribute}] set" do
        @plugin.run
        expect(@plugin[:dmi][id][attribute]).to eql(value)
      end
    end
  end

  it "ignores unwanted types" do
    @plugin.run
    expect(@plugin[:dmi]).not_to have_key(:on_board_devices)
  end

  # Oracle Solaris 11.4 on an OCI VM.Standard.E5.Flex, UUID replaced
  describe "with smbios output from Oracle Solaris 11.4 under KVM" do
    let(:smbios) do
      [
        "ID    SIZE TYPE",
        "256   73   SMB_TYPE_SYSTEM (system information)",
        "",
        "  Manufacturer: QEMU",
        "  Product: Standard PC (Q35 + ICH9, 2009)",
        "  Version: pc-q35-7.2",
        "",
        "  UUID: 0eaf0001-0000-4000-8000-0000feed0001",
        "  Wake-Up Event: 0x6 (power switch)",
        "  SKU Number: ",
        "  Family: ",
        "",
        "ID    SIZE TYPE",
        "768   53   SMB_TYPE_CHASSIS (system enclosure or chassis)",
        "",
        "  Manufacturer: QEMU",
        "  Version: pc-q35-7.2",
        "  Asset Tag: OracleCloud.com",
        "",
        "  SKU Number: ",
        "  OEM Data: 0x0",
        "  Lock Present: N",
        "  Chassis Type: 0x1 (other)",
        "  Boot-Up State: 0x3 (safe)",
        "  Power Supply State: 0x3 (safe)",
        "  Thermal State: 0x3 (safe)",
        "  Chassis Height: 0u",
        "  Power Cords: 0",
        "  Element Records: 0",
        "",
        "ID    SIZE TYPE",
        "1024  63   SMB_TYPE_PROCESSOR (processor)",
        "",
        "  Manufacturer: QEMU",
        "  Version: pc-q35-7.2",
        "  Location Tag: CPU 0",
        "",
        "  Family: 1 (other)",
        "  CPUID: 0x78bfbff00a10f11",
        "  Type: 3 (central processor)",
        "  Socket Upgrade: 1 (other)",
        "  Socket Status: Populated",
        "  Processor Status: 1 (enabled)",
        "  Supported Voltages:",
        "  External Clock Speed: Unknown",
        "  Maximum Speed: 2000MHz",
        "  Current Speed: 2000MHz",
        "  L1 Cache: None",
        "  L2 Cache: None",
        "  L3 Cache: None",
        "  Cores: 1",
        "  Cores Enabled: 1",
        "  Threads: 2",
        "  Characteristics: 0x2",
        "\tSMB_PRC_UNKNOWN (Unknown)",
        "",
        "ID    SIZE TYPE",
        "4096  23   SMB_TYPE_MEMARRAY (physical memory array)",
        "",
        "  Location: 1 (other)",
        "  Use: 3 (system memory)",
        "  ECC: 6 (multi-bit ECC)",
        "  Number of Slots/Sockets: 1",
        "  Memory Error Data: Not Supported",
        "  Max Capacity: 8589934592 bytes",
        "",
        "ID    SIZE TYPE",
        "4352  51   SMB_TYPE_MEMDEVICE (memory device)",
        "",
        "  Manufacturer: QEMU",
        "  Location Tag: DIMM 0",
        "",
        "  Physical Memory Array: 4096",
        "  Memory Error Data: Not Supported",
        "  Total Width: Unknown",
        "  Data Width: Unknown",
        "  Size: 8589934592 bytes",
        "  Form Factor: 9 (DIMM)",
        "  Set: None",
        "  Memory Type: 7 (RAM)",
        "  Flags: 0x2",
        "\tSMB_MDF_OTHER (other)",
        "  Speed: Unknown",
        "  Minimum voltage: Unknown",
        "  Maximum voltage: Unknown",
        "  Configured voltage: Unknown",
        "  Device Locator: DIMM 0",
        "  Bank Locator: ",
        "",
        "ID    SIZE TYPE",
        "4864  31   SMB_TYPE_MEMARRAYMAP (memory array mapped address)",
        "",
        "  Physical Memory Array: 4096",
        "  Devices per Row: 1",
        "  Physical Address: 0x0",
        "  Size: 2147483648 bytes",
        "",
        "ID    SIZE TYPE",
        "4865  31   SMB_TYPE_MEMARRAYMAP (memory array mapped address)",
        "",
        "  Physical Memory Array: 4096",
        "  Devices per Row: 1",
        "  Physical Address: 0x100000000",
        "  Size: 6442450944 bytes",
        "",
        "ID    SIZE TYPE",
        "8192  11   SMB_TYPE_BOOT (system boot status)",
        "",
        "  Boot Status Code: 0x0 (no errors detected)",
        "",
        "ID    SIZE TYPE",
        "0     53   SMB_TYPE_BIOS (BIOS information)",
        "",
        "  Vendor: Oracle",
        "  Version String: 20260902",
        "  Release Date: Sep-02-2026",
        "  Address Segment: 0xe800",
        "  ROM Size: 65536 bytes",
        "  Image Size: 98304 bytes",
        "  Characteristics: 0x8",
        "\tSMB_BIOSFL_BCNOTSUP (BIOS chars not supported)",
        "  Characteristics Extension Byte 1: 0x0",
        "  Characteristics Extension Byte 2: 0x1c",
        "\tSMB_BIOSXB2_ETCDIST (Enable Targeted Content Distrib.)",
        "\tSMB_BIOSXB2_UEFI (UEFI Specification supported)",
        "\tSMB_BIOSXB2_VIRT (SMBIOS describes a virtual machine)",
        "  Version Number: 0.0",
      ].join("\n") + "\n"
    end

    before do
      allow(@plugin).to receive(:shell_out).with("smbios").and_return(mock_shell_out(0, smbios, ""))
      @plugin.run
    end

    it "reads the system, chassis and BIOS strings" do
      expect(@plugin[:dmi][:system]).to include(manufacturer: "QEMU", product: "Standard PC (Q35 + ICH9, 2009)",
        uuid: "0eaf0001-0000-4000-8000-0000feed0001")
      expect(@plugin[:dmi][:chassis][:asset_tag]).to eq("OracleCloud.com")
      expect(@plugin[:dmi][:bios]).to include(vendor: "Oracle", version_string: "20260902", release_date: "Sep-02-2026")
    end

    it "reads the processor's cores and threads" do
      expect(@plugin[:dmi][:processor]).to include(cores: "1", cores_enabled: "1", threads: "2")
    end

    it "names a field that has no value without its colon" do
      expect(@plugin[:dmi][:processor]).to include(supported_voltages: "")
      expect(@plugin[:dmi][:processor]).not_to have_key(:supported_voltages_)
      expect(@plugin[:dmi][:processor][:all_records].first).to include("Supported Voltages" => "")
    end

    it "keeps a field that has an empty value after its colon" do
      expect(@plugin[:dmi][:system]).to include(sku_number: "", family: "")
    end
  end
end
