#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Author:: Isa Farnik (<isa@chef.io>)
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

require "spec_helper"

describe Ohai::System, "AIX network plugin" do
  before do
    @netstat_rn = <<~NETSTAT_RN
    Destination      Gateway            Flags  Refcnt Use       Interface
    Destination        Gateway           Flags   Refs     Use  If   Exp  Groups
    Only the root user can specify the Z flag
     (Internet):
    default            172.31.0.1        UG        2   1652046 en0      -      -   =>
    127/8              127.0.0.1         U         5   2455591 lo0      -      -   =>
    172.31.0.0         172.31.10.23      UHSb      0         0 en0      -      -   =>
    172.31/20          172.31.10.23      U         1   1015674 en0      -      -   =>
    172.31.10.23       127.0.0.1         UGHS      0         1 lo0      -      -
    172.31.15.255      172.31.10.23      UHSb      0         1 en0      -      -   =>
    Only the root user can specify the Z flag
     (Internet v6):
    ::1%1              ::1%1             UH        1    677032 lo0      -      -   =>
    NETSTAT_RN

    @ifconfig = <<~IFCONFIG
      en0: flags=1e080863,480<UP,BROADCAST,NOTRAILERS,RUNNING,SIMPLEX,MULTICAST,GROUPRT,64BIT,CHECKSUM_OFFLOAD(ACTIVE),CHAIN> metric 1
              inet 172.29.174.58 netmask 0xffffc000 broadcast 172.29.191.255
              inet 172.29.174.59 broadcast 172.29.191.255
              inet 172.29.174.60 netmask 0xffffc000 broadcast 172.29.191.255
              inet6 ::1%1/0
           tcp_sendspace 262144 tcp_recvspace 262144 rfc1323 1
      en1: flags=1e084863,480<UP,BROADCAST,NOTRAILERS,RUNNING,SIMPLEX,MULTICAST,GROUPRT,64BIT,CHECKSUM_OFFLOAD(ACTIVE),CHAIN>
              inet 172.31.10.211 netmask 0xfffffc00 broadcast 172.31.11.255
               tcp_sendspace 262144 tcp_recvspace 262144 rfc1323 1
      lo0: flags=e08084b,c0<UP,BROADCAST,LOOPBACK,RUNNING,SIMPLEX,MULTICAST,GROUPRT,64BIT,LARGESEND,CHAIN>
              inet 127.0.0.1 netmask 0xff000000 broadcast 127.255.255.255
              inet6 ::1%1/0
               tcp_sendspace 131072 tcp_recvspace 131072 rfc1323 1
    IFCONFIG

    @netstat_nrf_inet = <<~NETSTAT_NRF_INET
      Destination        Gateway           Flags   Refs     Use  If   Exp  Groups
      Route Tree for Protocol Family 2 (Internet):
      default            172.29.128.13     UG        0    587683 en0      -      -
      172.29.128.0       172.29.174.58     UHSb      0         0 en0      -      -   =>
      172.29.128/18      172.29.174.58     U         7   1035485 en0      -      -
      172.29.191.255     172.29.174.58     UHSb      0         1 en0      -      -
    NETSTAT_NRF_INET

    @entstat = <<~ENTSTAT
      -------------------------------------------------------------
      ETHERNET STATISTICS (en0) :
      Device Type: Virtual I/O Ethernet Adapter (l-lan)
      Hardware Address: 62:c5:1c:3a:5d:03
      Elapsed Time: 141 days 2 hours 15 minutes 31 seconds

      Transmit Statistics:                          Receive Statistics:
      --------------------                          -------------------
      Packets: 34322371                             Packets: 116444596
      Bytes: 2746892822                             Bytes: 122798204927
      Interrupts: 0                                 Interrupts: 72980222
      Transmit Errors: 0                            Receive Errors: 0
      Packets Dropped: 0                            Packets Dropped: 0
                                                    Bad Packets: 0
      Max Packets on S/W Transmit Queue: 0
      S/W Transmit Queue Overflow: 0
      Current S/W+H/W Transmit Queue Length: 0

      Broadcast Packets: 11                         Broadcast Packets: 25084677
      Multicast Packets: 2                          Multicast Packets: 0
      No Carrier Sense: 0                           CRC Errors: 0
      DMA Underrun: 0                               DMA Overrun: 0
      Lost CTS Errors: 0                            Alignment Errors: 0
      Max Collision Errors: 0                       No Resource Errors: 0
      Late Collision Errors: 0                      Receive Collision Errors: 0
      Deferred: 0                                   Packet Too Short Errors: 0
      SQE Test: 0                                   Packet Too Long Errors: 0
      Timeout Errors: 0                             Packets Discarded by Adapter: 0
      Single Collision Count: 0                     Receiver Start Count: 0
      Multiple Collision Count: 0
      Current HW Transmit Queue Length: 0

      General Statistics:
      -------------------
      No mbuf Errors: 0
      Adapter Reset Count: 0
      Adapter Data Rate: 20000
      Driver Flags: Up Broadcast Running
              Simplex 64BitSupport ChecksumOffload
              DataRateSet VIOENT

      Virtual I/O Ethernet Adapter (l-lan) Specific Statistics:
      ---------------------------------------------------------
      RQ Length: 4545
      Trunk Adapter: False
      Filter MCast Mode: False
      Filters: 255
        Enabled: 1  Queued: 0  Overflow: 0
      LAN State: Operational

      LPAR Active Memory Sharing: Disabled

      Hypervisor Send Failures: 0
        Receiver Failures: 0
        Send Errors: 0
      Hypervisor Receive Failures: 0

      Invalid VLAN ID Packets: 0

      ILLAN Attributes: 0000000000003002 [0000000000002000]

      Port VLAN ID:     1
      VLAN Tag IDs:  None


      Switch ID: ETHERNET0

      Hypervisor Information
        Virtual Memory
          Total (KB)                 80
        I/O Memory
          VRM Minimum (KB)          100
          VRM Desired (KB)          100
          DMA Max Min (KB)          128

      Transmit Information
        Transmit Buffers
          Buffer Size             65536
          Buffers                    32
          History
            No Buffers                0
        Virtual Memory
          Total (KB)               2048
        I/O Memory
          VRM Minimum (KB)         2176
          VRM Desired (KB)        16384
          DMA Max Min (KB)        16384

      Receive Information
        Receive Buffers
          Buffer Type              Tiny    Small   Medium    Large     Huge
          Min Buffers              2048     2048      256       64       64
          Max Buffers              2048     2048      256       64       64
          Allocated                2048     2048      256       64       64
          Registered               2048     2048      256       64       64
          History
            Max Allocated          2048     2048      256       64       64
            Lowest Registered      2047     1849      256       64       64
        Virtual Memory
          Minimum (KB)             1024     4096     4096     2048     4096
          Maximum (KB)             1024     4096     4096     2048     4096
        I/O Memory
          VRM Minimum (KB)        16384    16384     5120     2304     4352
          VRM Desired (KB)        16384    16384     5120     2304     4352
          DMA Max Min (KB)        16384    16384     8192     4096     8192
        Buffer Mode: Max Min

      I/O Memory Information
        Total VRM Minimum (KB)    46820
        Total VRM Desired (KB)    61028
        Total DMA Max Min (KB)    69760
    ENTSTAT

    @entstat_err = <<~ENSTAT_ERR


      entstat: 0909-002 Unable to open device en0, errno = 13
      grep: 0652-033 Cannot open Address".
    ENSTAT_ERR

    @aix_arp_an = <<~ARP_AN
        ? (172.29.131.16) at 6e:87:70:0:40:3 [ethernet] stored in bucket 16

        ? (10.153.50.202) at 34:40:b5:ab:fb:5a [ethernet] stored in bucket 40

        ? (10.153.1.99) at 52:54:0:8e:f2:fb [ethernet] stored in bucket 58

        ? (172.29.132.250) at 34:40:b5:a5:d7:1e [ethernet] stored in bucket 59

        ? (172.29.132.253) at 34:40:b5:a5:d7:2a [ethernet] stored in bucket 62

        ? (172.29.128.13) at 60:73:5c:69:42:44 [ethernet] stored in bucket 139

      bucket:    0     contains:    0 entries
      There are 6 entries in the arp table.
    ARP_AN

    @plugin = get_plugin("aix/network")
    allow(@plugin).to receive(:collect_os).and_return(:aix)
    @plugin[:network] = Mash.new
    allow(@plugin).to receive(:shell_out).with("uname -W").and_return(mock_shell_out(0, "0", nil))
    allow(@plugin).to receive(:shell_out).with("netstat -rn").and_return(mock_shell_out(0, @netstat_rn, nil))
    allow(@plugin).to receive(:shell_out).with("ifconfig -a").and_return(mock_shell_out(0, @ifconfig, nil))
    allow(@plugin).to receive(:shell_out).with("entstat -d en0").and_return(mock_shell_out(0, @entstat, nil))
    allow(@plugin).to receive(:shell_out).with("entstat -d en1").and_return(mock_shell_out(0, @entstat_err, nil))
    allow(@plugin).to receive(:shell_out).with("entstat -d lo0").and_return(mock_shell_out(0, @entstat_err, nil))
    allow(@plugin).to receive(:shell_out).with("netstat -nrf inet").and_return(mock_shell_out(0, @netstat_nrf_inet, nil))
    allow(@plugin).to receive(:shell_out).with("netstat -nrf inet6").and_return(mock_shell_out(0, "::1%1  ::1%1  UH 1 109392 en0  -  -", nil))
    allow(@plugin).to receive(:shell_out).with("arp -an").and_return(mock_shell_out(0, @aix_arp_an, nil))
  end

  describe "run" do
    before do
      @plugin.run
    end

    it "detects network information" do
      expect(@plugin["network"]).not_to be_nil
    end

    it "detects the interfaces" do
      expect(@plugin["network"]["interfaces"].keys.sort).to eq(%w{en0 en1 lo0})
    end

    it "detects the ip addresses of the interfaces" do
      expect(@plugin["network"]["interfaces"]["en0"]["addresses"].keys).to include("172.29.174.58")
    end
  end

  describe "when running on an LPAR" do
    describe "sets the top-level attribute correctly" do
      before do
        @plugin.run
      end

      it "for 'macaddress'" do
        expect(@plugin[:macaddress]).to eq("62:C5:1C:3A:5D:03")
      end
    end

    describe "netstat -rn" do
      before do
        @plugin.run
      end

      it "returns the default gateway of the system's network" do
        expect(@plugin[:network][:default_gateway]).to eq("172.31.0.1")
      end

      it "returns the default interface of the system's network" do
        expect(@plugin[:network][:default_interface]).to eq("en0")
      end
    end
  end

  describe "when running on a WPAR" do
    before do
      allow(@plugin).to receive(:shell_out).with("uname -W").and_return(mock_shell_out(0, "6", nil))
      @plugin.run
    end

    it "avoids collecting routing information" do
      expect(@plugin[:network][:default_gateway]).to be_nil
    end

    it "avoids collecting default interface" do
      expect(@plugin[:network][:default_gateway]).to be_nil
    end

    it "avoids collecting a macaddress" do
      expect(@plugin[:macaddress]).to be_nil
    end
  end

  describe "lsdev -Cc if" do
    it "detects the state of the interfaces in the system" do
      @plugin.run
      expect(@plugin["network"]["interfaces"]["en0"][:state]).to eq("up")
    end

    describe "ifconfig interface" do
      it "detects the CHAIN network flag" do
        @plugin.run
        expect(@plugin["network"]["interfaces"]["en0"][:flags]).to include("CHAIN")
      end

      it "detects the metric network flag" do
        @plugin.run
        expect(@plugin["network"]["interfaces"]["en0"][:metric]).to eq("1")
      end

      context "inet entries" do
        before do
          @plugin.run
          @inet_entry = @plugin["network"]["interfaces"]["en0"][:addresses]["172.29.174.58"]
        end

        it "detects the family" do
          expect(@inet_entry[:family]).to eq("inet")
        end

        it "detects the netmask" do
          expect(@inet_entry[:netmask]).to eq("255.255.192.0")
        end

        it "detects the broadcast" do
          expect(@inet_entry[:broadcast]).to eq("172.29.191.255")
        end

        it "detects all key-values" do
          expect(@plugin["network"]["interfaces"]["en0"][:tcp_sendspace]).to eq("262144")
          expect(@plugin["network"]["interfaces"]["en0"][:tcp_recvspace]).to eq("262144")
          expect(@plugin["network"]["interfaces"]["en0"][:rfc1323]).to eq("1")
        end

        # For an output with no netmask like inet 172.29.174.59 broadcast 172.29.191.255
        context "with no netmask in the output" do
          before do
            allow(@plugin).to receive(:shell_out).with("ifconfig en0").and_return(mock_shell_out(0, "inet 172.29.174.59 broadcast 172.29.191.255", nil))
          end

          it "detects the default prefixlen" do
            @inet_entry = @plugin["network"]["interfaces"]["en0"][:addresses]["172.29.174.59"]
            expect(@inet_entry[:prefixlen]).to eq("32")
          end

          it "detects the default netmask" do
            @inet_entry = @plugin["network"]["interfaces"]["en0"][:addresses]["172.29.174.59"]
            expect(@inet_entry[:netmask]).to eq("255.255.255.255")
          end
        end
      end

      context "inet6 entries" do
        before do
          @plugin.run
          @inet_entry = @plugin["network"]["interfaces"]["en0"][:addresses]["::1"]
        end

        it "detects the prefixlen" do
          expect(@inet_entry[:prefixlen]).to eq("0")
        end

        it "detects the family" do
          expect(@inet_entry[:family]).to eq("inet6")
        end
      end
    end

    context "entstat -d interface" do
      before do
        @plugin.run
        @inet_interface_addresses = @plugin["network"]["interfaces"]["en0"][:addresses]["62:C5:1C:3A:5D:03"]
      end

      it "detects the family" do
        expect(@inet_interface_addresses[:family]).to eq("lladdr")
      end
    end
  end

  describe "netstat -nrf family" do
    before do
      @plugin.run
    end

    context "inet" do
      it "detects the route destinations" do
        expect(@plugin["network"]["interfaces"]["en0"][:routes][0][:destination]).to eq("default")
        expect(@plugin["network"]["interfaces"]["en0"][:routes][1][:destination]).to eq("172.29.128.0")
      end

      it "detects the route family" do
        expect(@plugin["network"]["interfaces"]["en0"][:routes][0][:family]).to eq("inet")
      end

      it "detects the route gateway" do
        expect(@plugin["network"]["interfaces"]["en0"][:routes][0][:via]).to eq("172.29.128.13")
      end

      it "detects the route flags" do
        expect(@plugin["network"]["interfaces"]["en0"][:routes][0][:flags]).to eq("UG")
      end
    end

    context "inet6" do
      it "detects the route destinations" do
        expect(@plugin["network"]["interfaces"]["en0"][:routes][4][:destination]).to eq("::1%1")
      end

      it "detects the route family" do
        expect(@plugin["network"]["interfaces"]["en0"][:routes][4][:family]).to eq("inet6")
      end

      it "detects the route gateway" do
        expect(@plugin["network"]["interfaces"]["en0"][:routes][4][:via]).to eq("::1%1")
      end

      it "detects the route flags" do
        expect(@plugin["network"]["interfaces"]["en0"][:routes][4][:flags]).to eq("UH")
      end
    end
  end

  describe "arp -an" do
    before do
      @plugin.run
    end

    it "supresses the hostname entries" do
      expect(@plugin["network"]["arp"][0][:remote_host]).to eq("?")
    end

    it "detects the remote ip entry" do
      expect(@plugin["network"]["arp"][0][:remote_ip]).to eq("172.29.131.16")
    end

    it "detects the remote mac entry" do
      expect(@plugin["network"]["arp"][0][:remote_mac]).to eq("6e:87:70:0:40:3")
    end
  end
end
