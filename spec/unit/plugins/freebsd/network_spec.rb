#
#  Author:: Phil Dibowitz <phil@ipom.com>
#  Copyright:: Copyright (c) 2024 Phil Dibowitz
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

describe Ohai::System, "FreeBSD Network Plugin" do
  before do
    @freebsd_ifconfig = <<~FREEBSD_IFCONFIG
      vtnet0: flags=1008843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST,LOWER_UP> metric 0 mtu 1500
          options=4c079b<RXCSUM,TXCSUM,VLAN_MTU,VLAN_HWTAGGING,VLAN_HWCSUM,TSO4,TSO6,LRO,VLAN_HWTSO,LINKSTATE,TXCSUM_IPV6>
          ether fa:16:3e:ba:3e:25
          inet 140.211.10.91 netmask 0xffffffc0 broadcast 140.211.10.127
          inet6 fe80::f816:3eff:feba:3e25%vtnet0 prefixlen 64 scopeid 0x1
          inet6 2605:bc80:3010:506:f816:3eff:feba:3e25 prefixlen 64 autoconf pltime 604800 vltime 2592000
          media: Ethernet autoselect (10Gbase-T <full-duplex>)
          status: active
          nd6 options=23<PERFORMNUD,ACCEPT_RTADV,AUTO_LINKLOCAL>
      lo0: flags=1008049<UP,LOOPBACK,RUNNING,MULTICAST,LOWER_UP> metric 0 mtu 16384
          options=680003<RXCSUM,TXCSUM,LINKSTATE,RXCSUM_IPV6,TXCSUM_IPV6>
          inet 127.0.0.1 netmask 0xff000000
          inet6 ::1 prefixlen 128
          inet6 fe80::1%lo0 prefixlen 64 scopeid 0x2
          groups: lo
          nd6 options=21<PERFORMNUD,AUTO_LINKLOCAL>
    FREEBSD_IFCONFIG

    @freebsd_arp = <<~FREEBSD_ARP
      ? (140.211.10.91) at fa:16:3e:ba:3e:25 on vtnet0 permanent [ethernet]
      ? (140.211.10.65) at c0:d6:82:36:03:2b on vtnet0 expires in 1200 seconds [ethernet]
      ? (140.211.10.66) at fa:16:3e:7f:19:ef on vtnet0 expires in 1193 seconds [ethernet]
    FREEBSD_ARP

    @freebsd_route = <<~FREEBSD_ROUTE
         route to: 0.0.0.0
      destination: 0.0.0.0
             mask: 0.0.0.0
          gateway: 140.211.10.65
              fib: 0
        interface: vtnet0
            flags: <UP,GATEWAY,DONE,STATIC>
       recvpipe  sendpipe  ssthresh  rtt,msec    mtu        weight    expire
             0         0         0         0      1500         1         0
    FREEBSD_ROUTE

    @freebsd_netstat = <<~FREEBSD_NETSTAT
      Name     Mtu Network                  Address                                   Ipkts Ierrs Idrop     Ibytes    Opkts Oerrs     Obytes  Coll  Drop
      vtnet0  1500 <Link#1>                 fa:16:3e:ba:3e:25                           579     0     0      46746      210     0      26242     0     0
      vtnet0     - fe80::%vtnet0/64         fe80::f816:3eff:feba:3e25%vtnet0              3     -     -        272        5     -        328     -     -
      vtnet0     - 2605:bc80:3010:506::/64  2605:bc80:3010:506:f816:3eff:feba:3e25       38     -     -       3648       38     -       3648     -     -
      vtnet0     - 140.211.10.64/26         140.211.10.91                               189     -     -      18998      159     -      18594     -     -
      lo0    16384 <Link#2>                 lo0                                           0     0     0          0        0     0          0     0     0
      lo0        - ::1/128                  ::1                                           0     -     -          0        0     -          0     -     -
      lo0        - fe80::%lo0/64            fe80::1%lo0                                   0     -     -          0        0     -          0     -     -
      lo0        - 127.0.0.0/8              127.0.0.1                                     0     -     -          0        0     -          0     -     -
    FREEBSD_NETSTAT

    @freebsd_ifconfig2 = <<~FREEBSD_IFCONFIG
      vtnet0: flags=1008843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST,LOWER_UP> metric 0 mtu 1500
          options=4c079b<RXCSUM,TXCSUM,VLAN_MTU,VLAN_HWTAGGING,VLAN_HWCSUM,TSO4,TSO6,LRO,VLAN_HWTSO,LINKSTATE,TXCSUM_IPV6>
          ether fa:16:3e:ba:3e:25
          inet 140.211.10.91 netmask 0xffffffc0 broadcast 140.211.10.127
          inet6 fe80::f816:3eff:feba:3e25%vtnet0 prefixlen 64 scopeid 0x1
          inet6 2605:bc80:3010:506:f816:3eff:feba:3e25 prefixlen 64 autoconf pltime 604800 vltime 2592000
          media: Ethernet autoselect (10Gbase-T <full-duplex>)
          status: active
          nd6 options=23<PERFORMNUD,ACCEPT_RTADV,AUTO_LINKLOCAL>
      lo0: flags=1008049<UP,LOOPBACK,RUNNING,MULTICAST,LOWER_UP> metric 0 mtu 16384
          options=680003<RXCSUM,TXCSUM,LINKSTATE,RXCSUM_IPV6,TXCSUM_IPV6>
          inet 127.0.0.1 netmask 0xff000000
          inet6 fe80::1%lo0 prefixlen 64 scopeid 0x2
          groups: lo
          nd6 options=21<PERFORMNUD,AUTO_LINKLOCAL>
      lo1: flags=1008049<UP,LOOPBACK,RUNNING,MULTICAST,LOWER_UP> metric 0 mtu 16384
          options=680003<RXCSUM,TXCSUM,LINKSTATE,RXCSUM_IPV6,TXCSUM_IPV6>
          inet6 fe80::1%lo1 prefixlen 64 scopeid 0x3
          inet6 ::1 prefixlen 128
          groups: lo
          nd6 options=21<PERFORMNUD,AUTO_LINKLOCAL>
    FREEBSD_IFCONFIG

    @freebsd_arp2 = <<~FREEBSD_ARP
      ? (140.211.10.91) at fa:16:3e:ba:3e:25 on vtnet0 permanent [ethernet]
      ? (140.211.10.65) at c0:d6:82:36:03:2b on vtnet0 expires in 1200 seconds [ethernet]
      ? (140.211.10.66) at fa:16:3e:7f:19:ef on vtnet0 expires in 1193 seconds [ethernet]
    FREEBSD_ARP

    @freebsd_route2 = <<~FREEBSD_ROUTE
         route to: 0.0.0.0
      destination: 0.0.0.0
             mask: 0.0.0.0
          gateway: 140.211.10.65
              fib: 0
        interface: vtnet0
            flags: <UP,GATEWAY,DONE,STATIC>
       recvpipe  sendpipe  ssthresh  rtt,msec    mtu        weight    expire
             0         0         0         0      1500         1         0
    FREEBSD_ROUTE

    @freebsd_netstat2 = <<~FREEBSD_NETSTAT
      Name     Mtu Network                  Address                                   Ipkts Ierrs Idrop     Ibytes    Opkts Oerrs     Obytes  Coll  Drop
      vtnet0  1500 <Link#1>                 fa:16:3e:ba:3e:25                          3734     0     0   15901987     1740     0     175778     0     0
      vtnet0     - fe80::%vtnet0/64         fe80::f816:3eff:feba:3e25%vtnet0              1     -     -        104        2     -        128     -     -
      vtnet0     - 2605:bc80:3010:506::/64  2605:bc80:3010:506:f816:3eff:feba:3e25        0     -     -          0        0     -          0     -     -
      vtnet0     - 140.211.10.64/26         140.211.10.91                               103     -     -       7093       80     -       7824     -     -
      lo0    16384 <Link#2>                 lo0                                           0     0     0          0        0     0          0     0     0
      lo0        - fe80::%lo0/64            fe80::1%lo0                                   0     -     -          0        0     -          0     -     -
      lo0        - 127.0.0.0/8              127.0.0.1                                     0     -     -          0        0     -          0     -     -
      lo1    16384 <Link#3>                 lo1                                           0     0     0          0        0     0          0     0     0
      lo1        - fe80::%lo1/64            fe80::1%lo1                                   0     -     -          0        0     -          0     -     -
    FREEBSD_NETSTAT
    # If this line is in the HEREDOC above, it messes up vim's ability to syntax highlight. wtf.
    @freebsd_netstat2 << "lo1        - ::/64                    ::1                                           0     -     -          0        0     -          0     -     -\n"

    @plugin = get_plugin("freebsd/network")
    allow(@plugin).to receive(:collect_os).and_return(:freebsd)
  end

  describe "gathering IP layer address info" do
    before do
      allow(@plugin).to receive(:shell_out).with(/ifconfig -a$/).and_return(mock_shell_out(0, @freebsd_ifconfig, ""))
      allow(@plugin).to receive(:shell_out).with("route -n get default").and_return(mock_shell_out(0, @freebsd_route, ""))
      allow(@plugin).to receive(:shell_out).with("arp -an").and_return(mock_shell_out(0, @freebsd_arp, ""))
      allow(@plugin).to receive(:shell_out).with("netstat -ibdn").and_return(mock_shell_out(0, @freebsd_netstat, ""))
      @plugin.run
    end

    it "completes the run" do
      expect(@plugin["network"]).not_to be_nil
    end

    it "detects the interfaces" do
      expect(@plugin["network"]["interfaces"].keys.sort).to eq(%w{lo0 vtnet0})
    end

    it "detects the ipv4 addresses of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"].keys).to include("140.211.10.91")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["140.211.10.91"]["netmask"]).to eq("255.255.255.192")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["140.211.10.91"]["broadcast"]).to eq("140.211.10.127")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["140.211.10.91"]["family"]).to eq("inet")
    end

    it "detects the ipv6 addresses of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"].keys).to include("2605:bc80:3010:506:f816:3eff:feba:3e25")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["2605:bc80:3010:506:f816:3eff:feba:3e25"]["prefixlen"]).to eq("64")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["2605:bc80:3010:506:f816:3eff:feba:3e25"]["family"]).to eq("inet6")

      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"].keys).to include("fe80::f816:3eff:feba:3e25")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["fe80::f816:3eff:feba:3e25"]["prefixlen"]).to eq("64")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["fe80::f816:3eff:feba:3e25"]["family"]).to eq("inet6")
    end

    it "detects the mac addresses of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"].keys).to include("fa:16:3e:ba:3e:25")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["fa:16:3e:ba:3e:25"]["family"]).to eq("lladdr")
    end

    it "detects the encapsulation type of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["vtnet0"]["encapsulation"]).to eq("Ethernet")
    end

    it "detects the flags of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["vtnet0"]["flags"].sort).to eq(%w{BROADCAST LOWER_UP MULTICAST RUNNING SIMPLEX UP})
    end

    it "detects the mtu of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["vtnet0"]["mtu"]).to eq("1500")
    end

    it "detects the ipv4 addresses of the loopback interface" do
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"].keys).to include("127.0.0.1")
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"]["127.0.0.1"]["netmask"]).to eq("255.0.0.0")
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"]["127.0.0.1"]["family"]).to eq("inet")
    end

    it "detects the ipv6 addresses of the loopback interface" do
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"].keys).to include("::1")
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"]["::1"]["prefixlen"]).to eq("128")
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"]["::1"]["family"]).to eq("inet6")
    end

    # on FreeBSD, no encapsulation is reported for loopback
    it "detects the flags of the loopback interface" do
      expect(@plugin["network"]["interfaces"]["lo0"]["flags"].sort).to eq(%w{LOOPBACK LOWER_UP MULTICAST RUNNING UP})
    end

    it "detects the mtu of the loopback interface" do
      expect(@plugin["network"]["interfaces"]["lo0"]["mtu"]).to eq("16384")
    end

    it "detects the arp entries" do
      expect(@plugin["network"]["interfaces"]["vtnet0"]["arp"]["140.211.10.91"]).to eq("fa:16:3e:ba:3e:25")
    end

    it "detects the ethernet counters" do
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["tx"]["bytes"]).to eq("26242")
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["tx"]["packets"]).to eq("210")
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["tx"]["collisions"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["tx"]["errors"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["tx"]["dropped"]).to eq("0")

      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["rx"]["bytes"]).to eq("46746")
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["rx"]["packets"]).to eq("579")
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["rx"]["errors"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["rx"]["dropped"]).to eq("0")
    end

    it "detects the loopback counters" do
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["bytes"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["packets"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["collisions"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["errors"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["dropped"]).to eq("0")

      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["rx"]["bytes"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["rx"]["packets"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["rx"]["errors"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["rx"]["dropped"]).to eq("0")
    end

    it "finds the default interface by asking which iface has the default route" do
      expect(@plugin["network"][:default_interface]).to eq("vtnet0")
    end

    it "finds the default interface by asking which iface has the default route" do
      expect(@plugin["network"][:default_gateway]).to eq("140.211.10.65")
    end
  end

  describe "gathering IP layer address info with lo1" do
    before do
      allow(@plugin).to receive(:shell_out).with(/ifconfig -a$/).and_return(mock_shell_out(0, @freebsd_ifconfig2, ""))
      allow(@plugin).to receive(:shell_out).with("route -n get default").and_return(mock_shell_out(0, @freebsd_route2, ""))
      allow(@plugin).to receive(:shell_out).with("arp -an").and_return(mock_shell_out(0, @freebsd_arp2, ""))
      allow(@plugin).to receive(:shell_out).with("netstat -ibdn").and_return(mock_shell_out(0, @freebsd_netstat2, ""))
      @plugin.run
    end

    it "completes the run" do
      expect(@plugin["network"]).not_to be_nil
    end

    it "detects the interfaces" do
      expect(@plugin["network"]["interfaces"].keys.sort).to eq(%w{lo0 lo1 vtnet0})
    end

    it "detects the ipv4 addresses of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"].keys).to include("140.211.10.91")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["140.211.10.91"]["netmask"]).to eq("255.255.255.192")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["140.211.10.91"]["broadcast"]).to eq("140.211.10.127")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["140.211.10.91"]["family"]).to eq("inet")
    end

    it "detects the ipv6 addresses of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"].keys).to include("2605:bc80:3010:506:f816:3eff:feba:3e25")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["2605:bc80:3010:506:f816:3eff:feba:3e25"]["prefixlen"]).to eq("64")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["2605:bc80:3010:506:f816:3eff:feba:3e25"]["family"]).to eq("inet6")

      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"].keys).to include("fe80::f816:3eff:feba:3e25")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["fe80::f816:3eff:feba:3e25"]["prefixlen"]).to eq("64")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["fe80::f816:3eff:feba:3e25"]["family"]).to eq("inet6")
    end

    it "detects the mac addresses of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"].keys).to include("fa:16:3e:ba:3e:25")
      expect(@plugin["network"]["interfaces"]["vtnet0"]["addresses"]["fa:16:3e:ba:3e:25"]["family"]).to eq("lladdr")
    end

    it "detects the encapsulation type of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["vtnet0"]["encapsulation"]).to eq("Ethernet")
    end

    it "detects the flags of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["vtnet0"]["flags"].sort).to eq(%w{BROADCAST LOWER_UP MULTICAST RUNNING SIMPLEX UP})
    end

    it "detects the mtu of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["vtnet0"]["mtu"]).to eq("1500")
    end

    it "detects the ipv4 addresses of the loopback interface" do
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"].keys).to include("127.0.0.1")
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"]["127.0.0.1"]["netmask"]).to eq("255.0.0.0")
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"]["127.0.0.1"]["family"]).to eq("inet")
    end

    it "detects the ipv6 addresses of the loopback interface" do
      expect(@plugin["network"]["interfaces"]["lo1"]["addresses"].keys).to include("::1")
      expect(@plugin["network"]["interfaces"]["lo1"]["addresses"]["::1"]["prefixlen"]).to eq("128")
      expect(@plugin["network"]["interfaces"]["lo1"]["addresses"]["::1"]["family"]).to eq("inet6")
    end

    # on FreeBSD, no encapsulation is reported for loopback
    it "detects the flags of the loopback interface" do
      expect(@plugin["network"]["interfaces"]["lo0"]["flags"].sort).to eq(%w{LOOPBACK LOWER_UP MULTICAST RUNNING UP})
    end

    it "detects the mtu of the loopback interface" do
      expect(@plugin["network"]["interfaces"]["lo0"]["mtu"]).to eq("16384")
    end

    it "detects the arp entries" do
      expect(@plugin["network"]["interfaces"]["vtnet0"]["arp"]["140.211.10.91"]).to eq("fa:16:3e:ba:3e:25")
    end

    it "detects the ethernet counters" do
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["tx"]["bytes"]).to eq("175778")
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["tx"]["packets"]).to eq("1740")
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["tx"]["collisions"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["tx"]["errors"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["tx"]["dropped"]).to eq("0")

      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["rx"]["bytes"]).to eq("15901987")
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["rx"]["packets"]).to eq("3734")
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["rx"]["errors"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["vtnet0"]["rx"]["dropped"]).to eq("0")
    end

    it "detects the loopback counters" do
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["bytes"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["packets"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["collisions"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["errors"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["dropped"]).to eq("0")

      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["rx"]["bytes"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["rx"]["packets"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["rx"]["errors"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["rx"]["dropped"]).to eq("0")
    end

    it "finds the default interface by asking which iface has the default route" do
      expect(@plugin["network"][:default_interface]).to eq("vtnet0")
    end

    it "finds the default interface by asking which iface has the default route" do
      expect(@plugin["network"][:default_gateway]).to eq("140.211.10.65")
    end
  end
end
