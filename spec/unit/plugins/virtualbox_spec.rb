# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2015-2019 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"

vbox_list_vms_stdout = <<~EOF
  "ubuntu-18.04-amd64_1549746024485_35372" {6294f16b-4f05-4430-afb9-773bdb237aec}
EOF

vbox_vminfo_stdout = <<~EOF
  name="ubuntu-18.04-amd64_1549746024485_35372"
  groups="/"
  ostype="Ubuntu (64-bit)"
  UUID="6294f16b-4f05-4430-afb9-773bdb237aec"
  CfgFile="/virtual/machines/ubuntu-18.04-amd64_1549746024485_35372/ubuntu-18.04-amd64_1549746024485_35372.vbox"
  SnapFldr="/virtual/machines/ubuntu-18.04-amd64_1549746024485_35372/Snapshots"
  LogFldr="/virtual/machines/ubuntu-18.04-amd64_1549746024485_35372/Logs"
  hardwareuuid="6294f16b-4f05-4430-afb9-773bdb237aec"
  memory=1024
  pagefusion="off"
  vram=8
  cpuexecutioncap=100
  hpet="off"
  chipset="piix3"
  firmware="BIOS"
  cpus=1
  pae="on"
  longmode="on"
  triplefaultreset="off"
  apic="on"
  x2apic="on"
  cpuid-portability-level=0
  bootmenu="messageandmenu"
  boot1="disk"
  boot2="dvd"
  boot3="none"
  boot4="none"
  acpi="on"
  ioapic="on"
  biosapic="apic"
  biossystemtimeoffset=0
  rtcuseutc="off"
  hwvirtex="on"
  nestedpaging="on"
  largepages="on"
  vtxvpid="on"
  vtxux="on"
  paravirtprovider="default"
  effparavirtprovider="kvm"
  VMState="poweroff"
  VMStateChangeTime="2019-02-09T21:00:33.575000000"
  monitorcount=1
  accelerate3d="off"
  accelerate2dvideo="off"
  teleporterenabled="off"
  teleporterport=0
  teleporteraddress=""
  teleporterpassword=""
  tracing-enabled="off"
  tracing-allow-vm-access="off"
  tracing-config=""
  autostart-enabled="off"
  autostart-delay=0
  defaultfrontend=""
  storagecontrollername0="IDE Controller"
  storagecontrollertype0="PIIX4"
  storagecontrollerinstance0="0"
  storagecontrollermaxportcount0="2"
  storagecontrollerportcount0="2"
  storagecontrollerbootable0="on"
  storagecontrollername1="SATA Controller"
  storagecontrollertype1="IntelAhci"
  storagecontrollerinstance1="0"
  storagecontrollermaxportcount1="30"
  storagecontrollerportcount1="1"
  storagecontrollerbootable1="on"
  "IDE Controller-0-0"="none"
  "IDE Controller-0-1"="none"
  "IDE Controller-1-0"="none"
  "IDE Controller-1-1"="none"
  "SATA Controller-0-0"="/virtual/machines/ubuntu-18.04-amd64_1549746024485_35372/Snapshots/{1c182745-4b09-41a1-a147-d3ced46f72f6}.vmdk"
  "SATA Controller-ImageUUID-0-0"="1c182745-4b09-41a1-a147-d3ced46f72f6"
  natnet1="nat"
  macaddress1="080027E5FA8F"
  cableconnected1="on"
  nic1="nat"
  nictype1="82540EM"
  nicspeed1="0"
  mtu="0"
  sockSnd="64"
  sockRcv="64"
  tcpWndSnd="64"
  tcpWndRcv="64"
  nic2="none"
  nic3="none"
  nic4="none"
  nic5="none"
  nic6="none"
  nic7="none"
  nic8="none"
  hidpointing="ps2mouse"
  hidkeyboard="ps2kbd"
  uart1="off"
  uart2="off"
  uart3="off"
  uart4="off"
  lpt1="off"
  lpt2="off"
  audio="pulse"
  audio_in="false"
  audio_out="false"
  clipboard="disabled"
  draganddrop="disabled"
  vrde="on"
  vrdeport=-1
  vrdeports="5947"
  vrdeaddress="127.0.0.1"
  vrdeauthtype="null"
  vrdemulticon="off"
  vrdereusecon="off"
  vrdevideochannel="off"
  vrdeproperty[TCP/Ports]="5947"
  vrdeproperty[TCP/Address]="127.0.0.1"
  usb="off"
  ehci="off"
  xhci="off"
  GuestMemoryBalloon=0
  SnapshotName="base"
  SnapshotUUID="085cbbec-70cd-4864-9208-5d938dcabb71"
  CurrentSnapshotName="base"
  CurrentSnapshotUUID="085cbbec-70cd-4864-9208-5d938dcabb71"
  CurrentSnapshotNode="SnapshotName"
EOF

vbox_list_hdds_stdout = <<~EOF
  UUID:           ebb6dca0-879f-480b-a50e-9efe330bd021
  Parent UUID:    base
  State:          locked read
  Type:           normal (base)
  Location:       /virtual/machines/ubuntu-18.04-amd64_1549746024485_35372/ubuntu-18.04-amd64-disk001.vmdk
  Storage format: VMDK
  Capacity:       65536 MBytes
  Encryption:     disabled

  UUID:           1c182745-4b09-41a1-a147-d3ced46f72f6
  Parent UUID:    ebb6dca0-879f-480b-a50e-9efe330bd021
  State:          created
  Type:           normal (differencing)
  Location:       /virtual/machines/ubuntu-18.04-amd64_1549746024485_35372/Snapshots/{1c182745-4b09-41a1-a147-d3ced46f72f6}.vmdk
  Storage format: VMDK
  Capacity:       65536 MBytes
  Encryption:     disabled

EOF

vbox_list_dvds_stdout = <<~EOF
  UUID:           897aa7bc-1ec1-4e13-a16d-101d3716c72d
  State:          created
  Type:           normal (base)
  Location:       /tmp/test.dvd
  Storage format: RAW
  Capacity:       100 MBytes
  Encryption:     disabled

EOF

vbox_list_hostdvds_stdout = <<~EOF
  UUID:         00445644-0000-0000-2f64-65762f737230
  Name:         /dev/sr0

EOF

vbox_list_hostfloppies_stdout = <<~EOF

EOF

vbox_list_hostonlyifs_stdout = <<~EOF
  Name:            vboxnet0
  GUID:            786f6276-656e-4074-8000-0a0027000000
  DHCP:            Disabled
  IPAddress:       192.168.33.1
  NetworkMask:     255.255.255.0
  IPV6Address:
  IPV6NetworkMaskPrefixLength: 0
  HardwareAddress: 0a:00:27:00:00:00
  MediumType:      Ethernet
  Wireless:        No
  Status:          Down
  VBoxNetworkName: HostInterfaceNetworking-vboxnet0

  Name:            vboxnet1
  GUID:            786f6276-656e-4174-8000-0a0027000001
  DHCP:            Disabled
  IPAddress:       192.168.19.1
  NetworkMask:     255.255.255.0
  IPV6Address:     fe80::800:27ff:fe00:1
  IPV6NetworkMaskPrefixLength: 64
  HardwareAddress: 0a:00:27:00:00:01
  MediumType:      Ethernet
  Wireless:        No
  Status:          Up
  VBoxNetworkName: HostInterfaceNetworking-vboxnet1

EOF

vbox_list_bridgedifs_stdout = <<~EOF
  Name:            eno1
  GUID:            316f6e65-0000-4000-8000-309c233b62a9
  DHCP:            Disabled
  IPAddress:       10.143.72.133
  NetworkMask:     255.255.255.224
  IPV6Address:     fe80::9226:82e9:1101:60e6
  IPV6NetworkMaskPrefixLength: 64
  HardwareAddress: 30:9c:23:3b:62:a9
  MediumType:      Ethernet
  Wireless:        No
  Status:          Up
  VBoxNetworkName: HostInterfaceNetworking-eno1

EOF

vbox_list_dhcpservers_stdout = <<~EOF
  NetworkName:    HostInterfaceNetworking-vboxnet0
  IP:             192.168.56.100
  NetworkMask:    255.255.255.0
  lowerIPAddress: 192.168.56.101
  upperIPAddress: 192.168.56.254
  Enabled:        Yes

  NetworkName:    HostInterfaceNetworking-vboxnet1
  IP:             192.168.19.2
  NetworkMask:    255.255.255.0
  lowerIPAddress: 192.168.19.3
  upperIPAddress: 192.168.19.254
  Enabled:        Yes

EOF

# output of: VBoxManage list --sorted natnets
vbox_list_natnets_stdout = <<~EOF
  NetworkName:    NatNetwork
  IP:             10.0.2.1
  Network:        10.0.2.0/24
  IPv6 Enabled:   No
  IPv6 Prefix:    fd17:625c:f037:2::/64
  DHCP Enabled:   Yes
  Enabled:        Yes
  loopback mappings (ipv4)
          127.0.0.1=2

EOF

expected_output = { "guests" => { "ubuntu-18.04-amd64_1549746024485_35372" => { "groups" => "/", "ostype" => "Ubuntu (64-bit)", "uuid" => "6294f16b-4f05-4430-afb9-773bdb237aec", "cfgfile" => "/virtual/machines/ubuntu-18.04-amd64_1549746024485_35372/ubuntu-18.04-amd64_1549746024485_35372.vbox", "snapfldr" => "/virtual/machines/ubuntu-18.04-amd64_1549746024485_35372/Snapshots", "logfldr" => "/virtual/machines/ubuntu-18.04-amd64_1549746024485_35372/Logs", "hardwareuuid" => "6294f16b-4f05-4430-afb9-773bdb237aec", "memory" => "1024", "pagefusion" => "off", "vram" => "8", "cpuexecutioncap" => "100", "hpet" => "off", "chipset" => "piix3", "firmware" => "BIOS", "cpus" => "1", "pae" => "on", "longmode" => "on", "triplefaultreset" => "off", "apic" => "on", "x2apic" => "on", "cpuid-portability-level" => "0", "bootmenu" => "messageandmenu", "boot1" => "disk", "boot2" => "dvd", "boot3" => "none", "boot4" => "none", "acpi" => "on", "ioapic" => "on", "biosapic" => "apic", "biossystemtimeoffset" => "0", "rtcuseutc" => "off", "hwvirtex" => "on", "nestedpaging" => "on", "largepages" => "on", "vtxvpid" => "on", "vtxux" => "on", "paravirtprovider" => "default", "effparavirtprovider" => "kvm", "vmstate" => "poweroff", "vmstatechangetime" => "2019-02-09T21:00:33.575000000", "monitorcount" => "1", "accelerate3d" => "off", "accelerate2dvideo" => "off", "teleporterenabled" => "off", "teleporterport" => "0", "teleporteraddress" => "", "teleporterpassword" => "", "tracing-enabled" => "off", "tracing-allow-vm-access" => "off", "tracing-config" => "", "autostart-enabled" => "off", "autostart-delay" => "0", "defaultfrontend" => "", "storagecontrollername0" => "IDE Controller", "storagecontrollertype0" => "PIIX4", "storagecontrollerinstance0" => "0", "storagecontrollermaxportcount0" => "2", "storagecontrollerportcount0" => "2", "storagecontrollerbootable0" => "on", "storagecontrollername1" => "SATA Controller", "storagecontrollertype1" => "IntelAhci", "storagecontrollerinstance1" => "0", "storagecontrollermaxportcount1" => "30", "storagecontrollerportcount1" => "1", "storagecontrollerbootable1" => "on", "ide controller-0-0" => "none", "ide controller-0-1" => "none", "ide controller-1-0" => "none", "ide controller-1-1" => "none", "sata controller-0-0" => "/virtual/machines/ubuntu-18.04-amd64_1549746024485_35372/Snapshots/{1c182745-4b09-41a1-a147-d3ced46f72f6}.vmdk", "sata controller-imageuuid-0-0" => "1c182745-4b09-41a1-a147-d3ced46f72f6", "natnet1" => "nat", "macaddress1" => "080027E5FA8F", "cableconnected1" => "on", "nic1" => "nat", "nictype1" => "82540EM", "nicspeed1" => "0", "mtu" => "0", "socksnd" => "64", "sockrcv" => "64", "tcpwndsnd" => "64", "tcpwndrcv" => "64", "nic2" => "none", "nic3" => "none", "nic4" => "none", "nic5" => "none", "nic6" => "none", "nic7" => "none", "nic8" => "none", "hidpointing" => "ps2mouse", "hidkeyboard" => "ps2kbd", "uart1" => "off", "uart2" => "off", "uart3" => "off", "uart4" => "off", "lpt1" => "off", "lpt2" => "off", "audio" => "pulse", "audio_in" => "false", "audio_out" => "false", "clipboard" => "disabled", "draganddrop" => "disabled", "vrde" => "on", "vrdeport" => "-1", "vrdeports" => "5947", "vrdeaddress" => "127.0.0.1", "vrdeauthtype" => "null", "vrdemulticon" => "off", "vrdereusecon" => "off", "vrdevideochannel" => "off", "vrdeproperty[tcp/ports]" => "5947", "vrdeproperty[tcp/address]" => "127.0.0.1", "usb" => "off", "ehci" => "off", "xhci" => "off", "guestmemoryballoon" => "0", "snapshotname" => "base", "snapshotuuid" => "085cbbec-70cd-4864-9208-5d938dcabb71", "currentsnapshotname" => "base", "currentsnapshotuuid" => "085cbbec-70cd-4864-9208-5d938dcabb71", "currentsnapshotnode" => "SnapshotName" } }, "hdds" => { "/virtual/machines/ubuntu-18.04-amd64_1549746024485_35372/ubuntu-18.04-amd64-disk001.vmdk" => { "uuid" => "ebb6dca0-879f-480b-a50e-9efe330bd021", "parent uuid" => "base", "state" => "locked read", "type" => "normal (base)", "storage format" => "VMDK", "capacity" => "65536 MBytes", "encryption" => "disabled" }, "/virtual/machines/ubuntu-18.04-amd64_1549746024485_35372/Snapshots/{1c182745-4b09-41a1-a147-d3ced46f72f6}.vmdk" => { "uuid" => "1c182745-4b09-41a1-a147-d3ced46f72f6", "parent uuid" => "ebb6dca0-879f-480b-a50e-9efe330bd021", "state" => "created", "type" => "normal (differencing)", "storage format" => "VMDK", "capacity" => "65536 MBytes", "encryption" => "disabled" } }, "dvds" => { "/tmp/test.dvd" => { "uuid" => "897aa7bc-1ec1-4e13-a16d-101d3716c72d", "state" => "created", "type" => "normal (base)", "storage format" => "RAW", "capacity" => "100 MBytes", "encryption" => "disabled" } }, "hostdvds" => { "/dev/sr0" => { "uuid" => "00445644-0000-0000-2f64-65762f737230" } }, "hostfloppies" => {}, "hostonlyifs" => { "vboxnet0" => { "guid" => "786f6276-656e-4074-8000-0a0027000000", "dhcp" => "Disabled", "ipaddress" => "192.168.33.1", "networkmask" => "255.255.255.0", "ipv6address" => "", "ipv6networkmaskprefixlength" => "0", "hardwareaddress" => "0a:00:27:00:00:00", "mediumtype" => "Ethernet", "wireless" => "No", "status" => "Down", "vboxnetworkname" => "HostInterfaceNetworking-vboxnet0" }, "vboxnet1" => { "guid" => "786f6276-656e-4174-8000-0a0027000001", "dhcp" => "Disabled", "ipaddress" => "192.168.19.1", "networkmask" => "255.255.255.0", "ipv6address" => "fe80::800:27ff:fe00:1", "ipv6networkmaskprefixlength" => "64", "hardwareaddress" => "0a:00:27:00:00:01", "mediumtype" => "Ethernet", "wireless" => "No", "status" => "Up", "vboxnetworkname" => "HostInterfaceNetworking-vboxnet1" } }, "bridgedifs" => { "eno1" => { "guid" => "316f6e65-0000-4000-8000-309c233b62a9", "dhcp" => "Disabled", "ipaddress" => "10.143.72.133", "networkmask" => "255.255.255.224", "ipv6address" => "fe80::9226:82e9:1101:60e6", "ipv6networkmaskprefixlength" => "64", "hardwareaddress" => "30:9c:23:3b:62:a9", "mediumtype" => "Ethernet", "wireless" => "No", "status" => "Up", "vboxnetworkname" => "HostInterfaceNetworking-eno1" } }, "dhcpservers" => { "HostInterfaceNetworking-vboxnet0" => { "ip" => "192.168.56.100", "networkmask" => "255.255.255.0", "loweripaddress" => "192.168.56.101", "upperipaddress" => "192.168.56.254", "enabled" => "Yes" }, "HostInterfaceNetworking-vboxnet1" => { "ip" => "192.168.19.2", "networkmask" => "255.255.255.0", "loweripaddress" => "192.168.19.3", "upperipaddress" => "192.168.19.254", "enabled" => "Yes" } }, "natnets" => { "NatNetwork" => { "ip" => "10.0.2.1", "network" => "10.0.2.0/24", "ipv6 enabled" => "No", "ipv6 prefix" => "fd17:625c:f037:2::/64", "dhcp enabled" => "Yes", "enabled" => "Yes" } } }

vbox_output = <<~EOF
  Oracle VM VirtualBox Guest Additions Command Line Management Interface Version 5.0.2
  (C) 2008-2015 Oracle Corporation
  All rights reserved.

  Name: /VirtualBox/GuestInfo/OS/Product, value: Linux, timestamp: 1448390422246549000, flags: <NULL>
  Name: /VirtualBox/GuestInfo/Net/0/V4/IP, value: 10.0.2.15, timestamp: 1448390422248366000, flags: <NULL>
  Name: /VirtualBox/HostInfo/GUI/LanguageID, value: en_US, timestamp: 1448390412061749000, flags: <NULL>
  Name: /VirtualBox/GuestInfo/Net/0/MAC, value: 080027FBB38C, timestamp: 1448390422248652000, flags: <NULL>
  Name: /VirtualBox/GuestInfo/OS/ServicePack, value: <NULL>, timestamp: 1448390422246976000, flags: <NULL>
  Name: /VirtualBox/HostInfo/VBoxVerExt, value: 5.0.10, timestamp: 1448390411701508000, flags: TRANSIENT, RDONLYGUEST
  Name: /VirtualBox/GuestInfo/Net/0/V4/Netmask, value: 255.255.255.0, timestamp: 1448390422248569000, flags: <NULL>
  Name: /VirtualBox/GuestInfo/OS/Version, value: #36~14.04.1-Ubuntu SMP Thu Oct 8 10:21:08 UTC 2015, timestamp: 1448390422246810000, flags: <NULL>
  Name: /VirtualBox/GuestAdd/VersionExt, value: 5.0.2, timestamp: 1448390422247220000, flags: <NULL>
  Name: /VirtualBox/GuestAdd/Revision, value: 102096, timestamp: 1448390422247266000, flags: <NULL>
  Name: /VirtualBox/HostGuest/SysprepExec, value: <NULL>, timestamp: 1448390411701168000, flags: TRANSIENT, RDONLYGUEST
  Name: /VirtualBox/GuestInfo/OS/LoggedInUsers, value: 1, timestamp: 1448390452251425000, flags: TRANSIENT, TRANSRESET
  Name: /VirtualBox/GuestInfo/Net/0/Status, value: Up, timestamp: 1448390422248755000, flags: <NULL>
  Name: /VirtualBox/GuestInfo/Net/0/Name, value: eth0, timestamp: 1448390422248814000, flags: <NULL>
  Name: /VirtualBox/HostGuest/SysprepArgs, value: <NULL>, timestamp: 1448390411701220000, flags: TRANSIENT, RDONLYGUEST
  Name: /VirtualBox/GuestAdd/Version, value: 5.0.2, timestamp: 1448390422247066000, flags: <NULL>
  Name: /VirtualBox/HostInfo/VBoxRev, value: 104061, timestamp: 1448390411701536000, flags: TRANSIENT, RDONLYGUEST
  Name: /VirtualBox/GuestInfo/Net/0/V4/Broadcast, value: 10.0.2.255, timestamp: 1448390422248498000, flags: <NULL>
  Name: /VirtualBox/HostInfo/VBoxVer, value: 5.0.10, timestamp: 1448390411701485000, flags: TRANSIENT, RDONLYGUEST
  Name: /VirtualBox/GuestInfo/OS/LoggedInUsersList, value: tim, timestamp: 1448390452251274000, flags: TRANSIENT, TRANSRESET
  Name: /VirtualBox/GuestInfo/Net/Count, value: 1, timestamp: 1448391352440445000, flags: <NULL>
  Name: /VirtualBox/GuestInfo/OS/Release, value: 3.19.0-31-generic, timestamp: 1448390422246638000, flags: <NULL>
  Name: /VirtualBox/GuestInfo/OS/NoLoggedInUsers, value: false, timestamp: 1448390452251532000, flags: TRANSIENT, TRANSRESET
EOF

describe Ohai::System, "plugin virtualbox" do
  let(:plugin) { get_plugin("virtualbox") }

  before do
    plugin[:virtualization] = Mash.new
    plugin[:virtualization][:systems] = Mash.new
  end

  context "when not on a virtualbox guest" do
    it "does not set the virtualbox attribute" do
      plugin[:virtualization][:systems][:vmware] = "host"
      plugin.run
      expect(plugin).not_to have_key(:virtualbox)
    end
  end

  context "when on a vbox guest" do
    context "when VBoxControl shellout fails" do
      it "does not set the virtualbox attribute" do
        plugin[:virtualization][:systems][:vbox] = "guest"
        allow(plugin).to receive(:shell_out).with("VBoxControl guestproperty enumerate").and_return(mock_shell_out(1, "", ""))
        plugin.run
        expect(plugin).not_to have_key(:virtualbox)
      end
    end

    context "when VBoxControl shellout succeeds" do
      before do
        plugin[:virtualization][:systems][:vbox] = "guest"
        allow(plugin).to receive(:shell_out).with("VBoxControl guestproperty enumerate").and_return(mock_shell_out(0, vbox_output, ""))
        plugin.run
      end

      it "sets the host version" do
        expect(plugin[:virtualbox][:host][:version]).to eql("5.0.10")
      end

      it "sets the host revision" do
        expect(plugin[:virtualbox][:host][:revision]).to eql("104061")
      end

      it "sets the host language" do
        expect(plugin[:virtualbox][:host][:language]).to eql("en_US")
      end

      it "sets the guest additions version" do
        expect(plugin[:virtualbox][:guest][:guest_additions_version]).to eql("5.0.2")
      end

      it "sets the guest additions revision" do
        expect(plugin[:virtualbox][:guest][:guest_additions_revision]).to eql("102096")
      end
    end
  end

  context "when on a vbox host" do
    context "if the host has virtualbox installed" do
      it "creates a vbox attribute with accurate data" do
        plugin[:virtualization][:systems][:vbox] = "host"
        allow(plugin).to receive(:which).with("VBoxManage").and_return("/usr/bin/VBoxManage")
        allow(plugin).to receive(:shell_out).with("VBoxManage list --sorted vms").and_return(mock_shell_out(0, vbox_list_vms_stdout, ""))
        allow(plugin).to receive(:shell_out).with("VBoxManage showvminfo 6294f16b-4f05-4430-afb9-773bdb237aec --machinereadable").and_return(mock_shell_out(0, vbox_vminfo_stdout, ""))
        allow(plugin).to receive(:shell_out).with("VBoxManage list --sorted hdds").and_return(mock_shell_out(0, vbox_list_hdds_stdout, ""))
        allow(plugin).to receive(:shell_out).with("VBoxManage list --sorted dvds").and_return(mock_shell_out(0, vbox_list_dvds_stdout, ""))
        allow(plugin).to receive(:shell_out).with("VBoxManage list --sorted hostdvds").and_return(mock_shell_out(0, vbox_list_hostdvds_stdout, ""))
        allow(plugin).to receive(:shell_out).with("VBoxManage list --sorted hostfloppies").and_return(mock_shell_out(0, vbox_list_hostfloppies_stdout, ""))
        allow(plugin).to receive(:shell_out).with("VBoxManage list --sorted hostonlyifs").and_return(mock_shell_out(0, vbox_list_hostonlyifs_stdout, ""))
        allow(plugin).to receive(:shell_out).with("VBoxManage list --sorted bridgedifs").and_return(mock_shell_out(0, vbox_list_bridgedifs_stdout, ""))
        allow(plugin).to receive(:shell_out).with("VBoxManage list --sorted dhcpservers").and_return(mock_shell_out(0, vbox_list_dhcpservers_stdout, ""))
        allow(plugin).to receive(:shell_out).with("VBoxManage list --sorted natnets").and_return(mock_shell_out(0, vbox_list_natnets_stdout, ""))
        plugin.run
        expect(plugin).to have_key(:virtualbox)
        expect(plugin[:virtualbox]).to eq(expected_output)
      end
    end
  end
end
