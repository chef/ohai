#
#  Author:: Caleb Tennis <caleb.tennis@gmail.com>
#  Author:: Chris Read <chris.read@gmail.com>
#  Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

begin
  require 'ipaddress'
rescue LoadError => e
  puts "The linux network plugin spec tests will fail without the 'ipaddress' library/gem.\n\n"
  raise e
end

describe Ohai::System, "Linux Network Plugin" do
  let(:plugin) { get_plugin("linux/network") }

  let(:linux_ifconfig) {
'eth0      Link encap:Ethernet  HWaddr 12:31:3D:02:BE:A2
          inet addr:10.116.201.76  Bcast:10.116.201.255  Mask:255.255.255.0
          inet6 addr: fe80::1031:3dff:fe02:bea2/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:2659966 errors:0 dropped:0 overruns:0 frame:0
          TX packets:1919690 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:1392844460 (1.2 GiB)  TX bytes:691785313 (659.7 MiB)
          Interrupt:16

eth0:5    Link encap:Ethernet  HWaddr 00:0c:29:41:71:45
          inet addr:192.168.5.1  Bcast:192.168.5.255  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1

eth0.11   Link encap:Ethernet  HWaddr 00:aa:bb:cc:dd:ee
          inet addr:192.168.0.16  Bcast:192.168.0.255  Mask:255.255.255.0
          inet6 addr: fe80::2aa:bbff:fecc:ddee/64 Scope:Link
          inet6 addr: 1111:2222:3333:4444::2/64 Scope:Global
          inet6 addr: 1111:2222:3333:4444::3/64 Scope:Global
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:1208795008 errors:0 dropped:0 overruns:0 frame:0
          TX packets:3269635153 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1751940374 (1.6 GiB)  TX bytes:2195567597 (2.0 GiB)

eth0.151  Link encap:Ethernet  HWaddr 00:aa:bb:cc:dd:ee
          inet addr:10.151.0.16  Bcast:10.151.0.255  Mask:255.255.255.0
          inet6 addr: fe80::2aa:bbff:fecc:ddee/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:206553677 errors:0 dropped:0 overruns:0 frame:0
          TX packets:163901336 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:3190792261 (2.9 GiB)  TX bytes:755086548 (720.1 MiB)

eth0.152  Link encap:Ethernet  HWaddr 00:aa:bb:cc:dd:ee
          inet addr:10.152.1.16  Bcast:10.152.3.255  Mask:255.255.252.0
          inet6 addr: fe80::2aa:bbff:fecc:ddee/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:14016741 errors:0 dropped:0 overruns:0 frame:0
          TX packets:55232 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:664957462 (634.1 MiB)  TX bytes:4876434 (4.6 MiB)

eth0.153  Link encap:Ethernet  HWaddr 00:aa:bb:cc:dd:ee
          inet addr:10.153.1.16  Bcast:10.153.3.255  Mask:255.255.252.0
          inet6 addr: fe80::2aa:bbff:fecc:ddee/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:2022667595 errors:0 dropped:0 overruns:0 frame:0
          TX packets:1798627472 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:4047036732 (3.7 GiB)  TX bytes:3451231474 (3.2 GiB)

foo:veth0@eth0 Link encap:Ethernet  HWaddr ca:b3:73:8b:0c:e4
          BROADCAST MULTICAST  MTU:1500  Metric:1

tun0      Link encap:UNSPEC  HWaddr 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00
          inet addr:172.16.19.39  P-t-P:172.16.19.1  Mask:255.255.255.255
          UP POINTOPOINT RUNNING NOARP MULTICAST  MTU:1418  Metric:1
          RX packets:57200 errors:0 dropped:0 overruns:0 frame:0
          TX packets:13782 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:100
          RX bytes:7377600 (7.0 MiB)  TX bytes:1175481 (1.1 MiB)

venet0    Link encap:UNSPEC  HWaddr 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00
          UP POINTOPOINT RUNNING NOARP MULTICAST  MTU:1418  Metric:1
          RX packets:57200 errors:0 dropped:0 overruns:0 frame:0
          TX packets:13782 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:100
          RX bytes:7377600 (7.0 MiB)  TX bytes:1175481 (1.1 MiB)

venet0:0  Link encap:UNSPEC  HWaddr 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00
          UP POINTOPOINT RUNNING NOARP MULTICAST  MTU:1418  Metric:1
          RX packets:57200 errors:0 dropped:0 overruns:0 frame:0
          TX packets:13782 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:100
          RX bytes:7377600 (7.0 MiB)  TX bytes:1175481 (1.1 MiB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:16436  Metric:1
          RX packets:524 errors:0 dropped:0 overruns:0 frame:0
          TX packets:524 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:35224 (34.3 KiB)  TX bytes:35224 (34.3 KiB)

eth3      Link encap:Ethernet  HWaddr E8:39:35:C5:C8:54
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:13395101 errors:0 dropped:0 overruns:0 frame:0
          TX packets:9492909 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:1325650573 (1.2 GiB)  TX bytes:1666310189 (1.5 GiB)
          Interrupt:36 Memory:f4800000-f4ffffff

ovs-system Link encap:Ethernet  HWaddr 7A:7A:80:80:6C:24
          BROADCAST MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 b)  TX bytes:0 (0.0 b)

xapi1     Link encap:Ethernet  HWaddr E8:39:35:C5:C8:50
          inet addr:192.168.13.34  Bcast:192.168.13.255  Mask:255.255.255.0
          UP BROADCAST RUNNING  MTU:1500  Metric:1
          RX packets:160275 errors:0 dropped:0 overruns:0 frame:0
          TX packets:6 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:21515031 (20.5 MiB)  TX bytes:2052 (2.0 KiB)
'
# Note that ifconfig shows foo:veth0@eth0 but fails to show any address information.
# This was not a mistake collecting the output and Apparently ifconfig is broken in this regard.
  }

  let(:linux_ip_route) {
'10.116.201.0/24 dev eth0  proto kernel
192.168.5.0/24 dev eth0  proto kernel  src 192.168.5.1
192.168.212.0/24 dev foo:veth0@eth0  proto kernel  src 192.168.212.2
172.16.151.0/24 dev eth0  proto kernel  src 172.16.151.100
192.168.0.0/24 dev eth0  proto kernel  src 192.168.0.2
10.5.4.0/24 \\ nexthop via 10.5.4.1 dev eth0 weight 1\\ nexthop via 10.5.4.2 dev eth0 weight 1
default via 10.116.201.1 dev eth0
'
  }

  let(:linux_route_n) {
'Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
10.116.201.0    0.0.0.0         255.255.255.0   U     0      0        0 eth0
169.254.0.0     0.0.0.0         255.255.0.0     U     1002   0        0 eth0
0.0.0.0         10.116.201.1    0.0.0.0         UG    0      0        0 eth0
'
  }

  let(:linux_ip_route_inet6) {
'fe80::/64 dev eth0  proto kernel  metric 256
fe80::/64 dev eth0.11  proto kernel  metric 256
1111:2222:3333:4444::/64 dev eth0.11  metric 1024  expires 86023sec
default via 1111:2222:3333:4444::1 dev eth0.11  metric 1024
'
  }

  let(:linux_ip_addr) {
'1: lo: <LOOPBACK,UP,LOWER_UP> mtu 16436 qdisc noqueue state UNKNOWN
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 12:31:3d:02:be:a2 brd ff:ff:ff:ff:ff:ff
    inet 10.116.201.76/24 brd 10.116.201.255 scope global eth0
    inet 10.116.201.75/32 scope global eth0
    inet 10.116.201.74/24 scope global secondary eth0
    inet 192.168.5.1/24 brd 192.168.5.255 scope global eth0:5
    inet6 fe80::1031:3dff:fe02:bea2/64 scope link
       valid_lft forever preferred_lft forever
   inet6 2001:44b8:4160:8f00:a00:27ff:fe13:eacd/64 scope global dynamic
       valid_lft 6128sec preferred_lft 2526sec
3: eth0.11@eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
    link/ether 00:aa:bb:cc:dd:ee brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.16/24 brd 192.168.0.255 scope global eth0.11
    inet6 fe80::2e0:81ff:fe2b:48e7/64 scope link
    inet6 1111:2222:3333:4444::2/64 scope global
       valid_lft forever preferred_lft forever
    inet6 1111:2222:3333:4444::3/64 scope global
       valid_lft forever preferred_lft forever
4: eth0.151@eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
    link/ether 00:aa:bb:cc:dd:ee brd ff:ff:ff:ff:ff:ff
    inet 10.151.0.16/24 brd 10.151.0.255 scope global eth0.151
    inet 10.151.1.16/24 scope global eth0.151
    inet6 fe80::2e0:81ff:fe2b:48e7/64 scope link
       valid_lft forever preferred_lft forever
5: eth0.152@eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
    link/ether 00:aa:bb:cc:dd:ee brd ff:ff:ff:ff:ff:ff
    inet 10.152.1.16/22 brd 10.152.3.255 scope global eth0.152
    inet6 fe80::2e0:81ff:fe2b:48e7/64 scope link
       valid_lft forever preferred_lft forever
6: eth0.153@eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
    link/ether 00:aa:bb:cc:dd:ee brd ff:ff:ff:ff:ff:ff
    inet 10.153.1.16/22 brd 10.153.3.255 scope global eth0.153
    inet6 fe80::2e0:81ff:fe2b:48e7/64 scope link
       valid_lft forever preferred_lft forever
7: foo:veth0@eth0@veth0: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN
    link/ether ca:b3:73:8b:0c:e4 brd ff:ff:ff:ff:ff:ff
    inet 192.168.212.2/24 scope global foo:veth0@eth0
8: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc mq state UP qlen 1000
    link/none
    inet 172.16.19.39 peer 172.16.19.1 scope global tun0
9: venet0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP qlen 1000
    link/void
    inet 127.0.0.2/32 scope host venet0
    inet 172.16.19.48/32 scope global venet0:0
12: xapi1: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN
    link/ether e8:39:35:c5:c8:50 brd ff:ff:ff:ff:ff:ff
    inet 192.168.13.34/24 brd 192.168.13.255 scope global xapi1
       valid_lft forever preferred_lft forever
'
  }

  let(:linux_ip_link_s_d) {
'1: lo: <LOOPBACK,UP,LOWER_UP> mtu 16436 qdisc noqueue state UNKNOWN
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    RX: bytes  packets  errors  dropped overrun mcast
    35224      524      0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    35224      524      0       0       0       0
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 12:31:3d:02:be:a2 brd ff:ff:ff:ff:ff:ff
    RX: bytes  packets  errors  dropped overrun mcast
    1392844460 2659966  0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    691785313  1919690  0       0       0       0
3: eth0.11@eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
    link/ether 00:0c:29:41:71:45 brd ff:ff:ff:ff:ff:ff
    vlan id 11 <REORDER_HDR>
    RX: bytes  packets  errors  dropped overrun mcast
    0          0        0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    0          0        0       0       0       0
4: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN qlen 100
    link/none
    RX: bytes  packets  errors  dropped overrun mcast
    1392844460 2659966  0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    691785313  1919690  0       0       0       0
5: venet0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP qlen 1000
    link/void
    RX: bytes  packets  errors  dropped overrun mcast
    1392844460 2659966  0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    691785313  1919690  0       0       0       0
10: eth3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq master ovs-system state UP mode DEFAULT qlen 1000
    link/ether e8:39:35:c5:c8:54 brd ff:ff:ff:ff:ff:ff
    RX: bytes  packets  errors  dropped overrun mcast
    1321907045 13357087 0       0       0       3126613
    TX: bytes  packets  errors  dropped carrier collsns
    1661526184 9467091  0       0       0       0
11: ovs-system: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT
    link/ether 7a:7a:80:80:6c:24 brd ff:ff:ff:ff:ff:ff
    RX: bytes  packets  errors  dropped overrun mcast
    0          0        0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    0          0        0       0       0       0
12: xapi1: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN mode DEFAULT
    link/ether e8:39:35:c5:c8:50 brd ff:ff:ff:ff:ff:ff
    RX: bytes  packets  errors  dropped overrun mcast
    21468183   159866   0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    2052       6        0       0       0       0
'
  }

  let(:linux_arp_an) {
'? (10.116.201.1) at fe:ff:ff:ff:ff:ff [ether] on eth0
'
  }

  let(:linux_ip_neighbor_show) {
'10.116.201.1 dev eth0 lladdr fe:ff:ff:ff:ff:ff REACHABLE
'
  }

  let(:linux_ip_inet6_neighbor_show) {
'1111:2222:3333:4444::1 dev eth0.11 lladdr 00:1c:0e:12:34:56 router REACHABLE
fe80::21c:eff:fe12:3456 dev eth0.11 lladdr 00:1c:0e:30:28:00 router REACHABLE
fe80::21c:eff:fe12:3456 dev eth0.153 lladdr 00:1c:0e:30:28:00 router REACHABLE
'
  }

  before(:each) do
    allow(plugin).to receive(:collect_os).and_return(:linux)

    allow(plugin).to receive(:shell_out).with("ip addr").and_return(mock_shell_out(0, linux_ip_addr, ""))
    allow(plugin).to receive(:shell_out).with("ip -d -s link").and_return(mock_shell_out(0, linux_ip_link_s_d, ""))
    allow(plugin).to receive(:shell_out).with("ip -f inet neigh show").and_return(mock_shell_out(0, linux_ip_neighbor_show, ""))
    allow(plugin).to receive(:shell_out).with("ip -f inet6 neigh show").and_return(mock_shell_out(0, linux_ip_inet6_neighbor_show, ""))
    allow(plugin).to receive(:shell_out).with("ip -o -f inet route show").and_return(mock_shell_out(0, linux_ip_route, ""))
    allow(plugin).to receive(:shell_out).with("ip -o -f inet6 route show").and_return(mock_shell_out(0, linux_ip_route_inet6, ""))

    allow(plugin).to receive(:shell_out).with("route -n").and_return(mock_shell_out(0, linux_route_n, ""))
    allow(plugin).to receive(:shell_out).with("ifconfig -a").and_return(mock_shell_out(0, linux_ifconfig, ""))
    allow(plugin).to receive(:shell_out).with("arp -an").and_return(mock_shell_out(0, linux_arp_an, ""))
  end

  describe "#iproute2_binary_available?" do
    ["/sbin/ip", "/usr/bin/ip"].each do |path|
      it "accepts #{path}" do
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with(path).and_return(true)
        expect(plugin.iproute2_binary_available?).to be_truthy
      end
    end
  end

  ["ifconfig","iproute2"].each do |network_method|

    describe "gathering IP layer address info via #{network_method}" do
      before(:each) do
        allow(plugin).to receive(:iproute2_binary_available?).and_return( network_method == "iproute2" )
        plugin.run
      end

      it "completes the run" do
        expect(Ohai::Log).not_to receive(:debug).with(/Plugin linux::network threw exception/)
        expect(plugin['network']).not_to be_nil
      end

      it "detects the interfaces" do
        expect(plugin['network']['interfaces'].keys.sort).to eq(["eth0", "eth0.11", "eth0.151", "eth0.152", "eth0.153", "eth0:5", "eth3", "foo:veth0@eth0", "lo", "ovs-system",  "tun0", "venet0", "venet0:0", "xapi1"])
      end

      it "detects the ipv4 addresses of the ethernet interface" do
        expect(plugin['network']['interfaces']['eth0']['addresses'].keys).to include('10.116.201.76')
        expect(plugin['network']['interfaces']['eth0']['addresses']['10.116.201.76']['netmask']).to eq('255.255.255.0')
        expect(plugin['network']['interfaces']['eth0']['addresses']['10.116.201.76']['broadcast']).to eq('10.116.201.255')
        expect(plugin['network']['interfaces']['eth0']['addresses']['10.116.201.76']['family']).to eq('inet')
      end

      it "detects the ipv4 addresses of an ethernet subinterface" do
        expect(plugin['network']['interfaces']['eth0.11']['addresses'].keys).to include('192.168.0.16')
        expect(plugin['network']['interfaces']['eth0.11']['addresses']['192.168.0.16']['netmask']).to eq('255.255.255.0')
        expect(plugin['network']['interfaces']['eth0.11']['addresses']['192.168.0.16']['broadcast']).to eq('192.168.0.255')
        expect(plugin['network']['interfaces']['eth0.11']['addresses']['192.168.0.16']['family']).to eq('inet')
      end

      it "detects the ipv6 addresses of the ethernet interface" do
        expect(plugin['network']['interfaces']['eth0']['addresses'].keys).to include('fe80::1031:3dff:fe02:bea2')
        expect(plugin['network']['interfaces']['eth0']['addresses']['fe80::1031:3dff:fe02:bea2']['scope']).to eq('Link')
        expect(plugin['network']['interfaces']['eth0']['addresses']['fe80::1031:3dff:fe02:bea2']['prefixlen']).to eq('64')
        expect(plugin['network']['interfaces']['eth0']['addresses']['fe80::1031:3dff:fe02:bea2']['family']).to eq('inet6')
      end

      it "detects the ipv6 addresses of an ethernet subinterface" do
        %w[ 1111:2222:3333:4444::2 1111:2222:3333:4444::3 ].each  do |addr|
          expect(plugin['network']['interfaces']['eth0.11']['addresses'].keys).to include(addr)
          expect(plugin['network']['interfaces']['eth0.11']['addresses'][addr]['scope']).to eq('Global')
          expect(plugin['network']['interfaces']['eth0.11']['addresses'][addr]['prefixlen']).to eq('64')
          expect(plugin['network']['interfaces']['eth0.11']['addresses'][addr]['family']).to eq('inet6')
        end
      end

      it "detects the mac addresses of the ethernet interface" do
        expect(plugin['network']['interfaces']['eth0']['addresses'].keys).to include('12:31:3D:02:BE:A2')
        expect(plugin['network']['interfaces']['eth0']['addresses']['12:31:3D:02:BE:A2']['family']).to eq('lladdr')
      end

      it "detects the encapsulation type of the ethernet interface" do
        expect(plugin['network']['interfaces']['eth0']['encapsulation']).to eq('Ethernet')
      end

      it "detects the flags of the ethernet interface" do
        if network_method == "ifconfig"
          expect(plugin['network']['interfaces']['eth0']['flags'].sort).to eq(['BROADCAST','MULTICAST','RUNNING','UP'])
        else
          expect(plugin['network']['interfaces']['eth0']['flags'].sort).to eq(['BROADCAST','LOWER_UP','MULTICAST','UP'])
        end
      end

      it "detects the number of the ethernet interface" do
        expect(plugin['network']['interfaces']['eth0']['number']).to eq("0")
      end

      it "detects the mtu of the ethernet interface" do
        expect(plugin['network']['interfaces']['eth0']['mtu']).to eq("1500")
      end

      it "detects the ipv4 addresses of the loopback interface" do
        expect(plugin['network']['interfaces']['lo']['addresses'].keys).to include('127.0.0.1')
        expect(plugin['network']['interfaces']['lo']['addresses']['127.0.0.1']['netmask']).to eq('255.0.0.0')
        expect(plugin['network']['interfaces']['lo']['addresses']['127.0.0.1']['family']).to eq('inet')
      end

      it "detects the ipv6 addresses of the loopback interface" do
        expect(plugin['network']['interfaces']['lo']['addresses'].keys).to include('::1')
        expect(plugin['network']['interfaces']['lo']['addresses']['::1']['scope']).to eq('Node')
        expect(plugin['network']['interfaces']['lo']['addresses']['::1']['prefixlen']).to eq('128')
        expect(plugin['network']['interfaces']['lo']['addresses']['::1']['family']).to eq('inet6')
      end

      it "detects the encapsulation type of the loopback interface" do
        expect(plugin['network']['interfaces']['lo']['encapsulation']).to eq('Loopback')
      end

      it "detects the flags of the ethernet interface" do
        if network_method == "ifconfig"
          expect(plugin['network']['interfaces']['lo']['flags'].sort).to eq(['LOOPBACK','RUNNING','UP'])
        else
          expect(plugin['network']['interfaces']['lo']['flags'].sort).to eq(['LOOPBACK','LOWER_UP','UP'])
        end
      end


      it "detects the mtu of the loopback interface" do
        expect(plugin['network']['interfaces']['lo']['mtu']).to eq("16436")
      end

      it "detects the arp entries" do
        expect(plugin['network']['interfaces']['eth0']['arp']['10.116.201.1']).to eq('fe:ff:ff:ff:ff:ff')
      end

    end

    describe "gathering interface counters via #{network_method}" do
      before(:each) do
        allow(plugin).to receive(:iproute2_binary_available?).and_return( network_method == "iproute2" )
        plugin.run
      end

      it "detects the ethernet counters" do
        expect(plugin['counters']['network']['interfaces']['eth0']['tx']['bytes']).to eq("691785313")
        expect(plugin['counters']['network']['interfaces']['eth0']['tx']['packets']).to eq("1919690")
        expect(plugin['counters']['network']['interfaces']['eth0']['tx']['collisions']).to eq("0")
        expect(plugin['counters']['network']['interfaces']['eth0']['tx']['queuelen']).to eq("1000")
        expect(plugin['counters']['network']['interfaces']['eth0']['tx']['errors']).to eq("0")
        expect(plugin['counters']['network']['interfaces']['eth0']['tx']['carrier']).to eq("0")
        expect(plugin['counters']['network']['interfaces']['eth0']['tx']['drop']).to eq("0")

        expect(plugin['counters']['network']['interfaces']['eth0']['rx']['bytes']).to eq("1392844460")
        expect(plugin['counters']['network']['interfaces']['eth0']['rx']['packets']).to eq("2659966")
        expect(plugin['counters']['network']['interfaces']['eth0']['rx']['errors']).to eq("0")
        expect(plugin['counters']['network']['interfaces']['eth0']['rx']['overrun']).to eq("0")
        expect(plugin['counters']['network']['interfaces']['eth0']['rx']['drop']).to eq("0")
      end

      it "detects the loopback counters" do
        expect(plugin['counters']['network']['interfaces']['lo']['tx']['bytes']).to eq("35224")
        expect(plugin['counters']['network']['interfaces']['lo']['tx']['packets']).to eq("524")
        expect(plugin['counters']['network']['interfaces']['lo']['tx']['collisions']).to eq("0")
        expect(plugin['counters']['network']['interfaces']['lo']['tx']['errors']).to eq("0")
        expect(plugin['counters']['network']['interfaces']['lo']['tx']['carrier']).to eq("0")
        expect(plugin['counters']['network']['interfaces']['lo']['tx']['drop']).to eq("0")

        expect(plugin['counters']['network']['interfaces']['lo']['rx']['bytes']).to eq("35224")
        expect(plugin['counters']['network']['interfaces']['lo']['rx']['packets']).to eq("524")
        expect(plugin['counters']['network']['interfaces']['lo']['rx']['errors']).to eq("0")
        expect(plugin['counters']['network']['interfaces']['lo']['rx']['overrun']).to eq("0")
        expect(plugin['counters']['network']['interfaces']['lo']['rx']['drop']).to eq("0")
      end
    end

    describe "setting the node's default IP address attribute with #{network_method}" do
      before(:each) do
        allow(plugin).to receive(:iproute2_binary_available?).and_return( network_method == "iproute2" )
        plugin.run
      end

      describe "without a subinterface" do
        it "finds the default interface by asking which iface has the default route" do
          expect(plugin['network']['default_interface']).to eq('eth0')
        end

        it "finds the default gateway by asking which iface has the default route" do
          expect(plugin['network']['default_gateway']).to eq('10.116.201.1')
        end
      end

      describe "with a link level default route" do
        let(:linux_ip_route) {
'10.116.201.0/24 dev eth0  proto kernel
default dev eth0 scope link
'
        }

        let(:linux_route_n) {
'Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
10.116.201.0    0.0.0.0         255.255.255.0   U     0      0        0 eth0
0.0.0.0         0.0.0.0         0.0.0.0         U     0      0        0 eth0
'
        }

        before(:each) do
          plugin.run
        end

        it "finds the default interface by asking which iface has the default route" do
          expect(plugin['network']['default_interface']).to eq('eth0')
        end

        it "finds the default interface by asking which iface has the default route" do
          expect(plugin['network']['default_gateway']).to eq('0.0.0.0')
        end
      end

      describe "with a subinterface" do
        let(:linux_ip_route) {
'192.168.0.0/24 dev eth0.11  proto kernel  src 192.168.0.2
default via 192.168.0.15 dev eth0.11
'
        }

        let(:linux_route_n) {
'Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
192.168.0.0    0.0.0.0         255.255.255.0   U     0      0        0 eth0.11
0.0.0.0         192.168.0.15   0.0.0.0         UG    0      0        0 eth0.11
'
        }

        before(:each) do
          plugin.run
        end

        it "finds the default interface by asking which iface has the default route" do
          expect(plugin['network']["default_interface"]).to eq('eth0.11')
        end

        it "finds the default interface by asking which iface has the default route" do
          expect(plugin['network']["default_gateway"]).to eq('192.168.0.15')
        end
      end
    end
  end

  describe "for newer network features using iproute2 only" do
    before(:each) do
      allow(File).to receive(:exist?).with("/sbin/ip").and_return(true) # iproute2 only
      plugin.run
    end

    it "completes the run" do
      expect(Ohai::Log).not_to receive(:debug).with(/Plugin linux::network threw exception/)
      expect(plugin['network']).not_to be_nil
    end

    it "finds the default inet6 interface if there's a inet6 default route" do
      expect(plugin['network']['default_inet6_interface']).to eq('eth0.11')
    end

    it "finds the default inet6 gateway if there's a inet6 default route" do
      expect(plugin['network']['default_inet6_gateway']).to eq('1111:2222:3333:4444::1')
    end

    it "finds inet6 neighbours" do
      expect(plugin['network']['interfaces']['eth0.11']['neighbour_inet6']['1111:2222:3333:4444::1']).to eq('00:1c:0e:12:34:56')
    end

    it "detects the ipv4 addresses of an ethernet interface with a crazy name" do
      expect(plugin['network']['interfaces']['foo:veth0@eth0']['addresses'].keys).to include('192.168.212.2')
      expect(plugin['network']['interfaces']['foo:veth0@eth0']['addresses']['192.168.212.2']['netmask']).to eq('255.255.255.0')
      expect(plugin['network']['interfaces']['foo:veth0@eth0']['addresses']['192.168.212.2']['family']).to eq('inet')
    end

    it "generates a fake interface for ip aliases for backward compatibility" do
      expect(plugin['network']['interfaces']['eth0:5']['addresses'].keys).to include('192.168.5.1')
      expect(plugin['network']['interfaces']['eth0:5']['addresses']['192.168.5.1']['netmask']).to eq('255.255.255.0')
      expect(plugin['network']['interfaces']['eth0:5']['addresses']['192.168.5.1']['family']).to eq('inet')
    end

    it "adds the vlan information of an interface" do
      expect(plugin['network']['interfaces']['eth0.11']['vlan']['id']).to eq('11')
      expect(plugin['network']['interfaces']['eth0.11']['vlan']['flags']).to eq([ 'REORDER_HDR' ])
    end

    it "adds the state of an interface" do
      expect(plugin['network']['interfaces']['eth0.11']['state']).to eq('up')
    end

    it "detects interfaces only visible via ip link" do
      expect(plugin['network']['interfaces']['eth3']['state']).to eq('up')
    end

    describe "when dealing with routes" do
      it "adds routes" do
        plugin.run
        expect(plugin['network']['interfaces']['eth0']['routes']).to include Mash.new( :destination => "10.116.201.0/24", :proto => "kernel", :family =>"inet" )
        expect(plugin['network']['interfaces']['eth0']['routes']).to include Mash.new( :destination => "10.5.4.0/24", :family =>"inet", :via => "10.5.4.1")
        expect(plugin['network']['interfaces']['eth0']['routes']).to include Mash.new( :destination => "10.5.4.0/24", :family =>"inet", :via => "10.5.4.2")
        expect(plugin['network']['interfaces']['foo:veth0@eth0']['routes']).to include Mash.new( :destination => "192.168.212.0/24", :proto => "kernel", :src => "192.168.212.2", :family =>"inet" )
        expect(plugin['network']['interfaces']['eth0']['routes']).to include Mash.new( :destination => "fe80::/64", :metric => "256", :proto => "kernel", :family => "inet6" )
        expect(plugin['network']['interfaces']['eth0.11']['routes']).to include Mash.new( :destination => "1111:2222:3333:4444::/64", :metric => "1024", :family => "inet6" )
        expect(plugin['network']['interfaces']['eth0.11']['routes']).to include Mash.new( :destination => "default", :via => "1111:2222:3333:4444::1", :metric => "1024", :family => "inet6")
      end

      describe "when there isn't a source field in route entries " do
        before(:each) do
          plugin.run
        end

        it "doesn't set ipaddress" do
          expect(plugin['ipaddress']).to be nil
        end

        it "doesn't set macaddress" do
          expect(plugin['macaddress']).to be nil
        end

        it "doesn't set ip6address" do
          expect(plugin['ip6address']).to be nil
        end
      end

      describe "when there's a source field in the default route entry" do
        let(:linux_ip_route) {
'10.116.201.0/24 dev eth0  proto kernel
192.168.5.0/24 dev eth0  proto kernel  src 192.168.5.1
192.168.212.0/24 dev foo:veth0@eth0  proto kernel  src 192.168.212.2
172.16.151.0/24 dev eth0  proto kernel  src 172.16.151.100
192.168.0.0/24 dev eth0  proto kernel  src 192.168.0.2
default via 10.116.201.1 dev eth0  src 10.116.201.76
'
        }

        let(:linux_ip_route_inet6) {
'fe80::/64 dev eth0  proto kernel  metric 256
fe80::/64 dev eth0.11  proto kernel  metric 256
1111:2222:3333:4444::/64 dev eth0.11  metric 1024
default via 1111:2222:3333:4444::1 dev eth0.11  metric 1024  src 1111:2222:3333:4444::3
'
        }

        before(:each) do
          plugin.run
        end

        it "completes the run" do
          expect(Ohai::Log).not_to receive(:debug).with(/Plugin linux::network threw exception/)
          expect(plugin['network']).not_to be_nil
        end

        it "sets ipaddress" do
          expect(plugin['ipaddress']).to eq("10.116.201.76")
        end

        it "sets ip6address" do
          expect(plugin['ip6address']).to eq("1111:2222:3333:4444::3")
        end
      end

      describe "when there're several default routes" do
        let(:linux_ip_route) {
'10.116.201.0/24 dev eth0  proto kernel  src 10.116.201.76
192.168.5.0/24 dev eth0  proto kernel  src 192.168.5.1
192.168.212.0/24 dev foo:veth0@eth0  proto kernel  src 192.168.212.2
172.16.151.0/24 dev eth0  proto kernel  src 172.16.151.100
192.168.0.0/24 dev eth0  proto kernel  src 192.168.0.2
default via 10.116.201.1 dev eth0 metric 10
default via 10.116.201.254 dev eth0 metric 9
'
        }

        let(:linux_ip_route_inet6) {
'fe80::/64 dev eth0  proto kernel  metric 256
fe80::/64 dev eth0.11  proto kernel  metric 256
1111:2222:3333:4444::/64 dev eth0.11  metric 1024  src 1111:2222:3333:4444::3
default via 1111:2222:3333:4444::1 dev eth0.11  metric 1024
default via 1111:2222:3333:4444::ffff dev eth0.11  metric 1023
'
        }

        before(:each) do
          plugin.run
        end

        it "completes the run" do
          expect(Ohai::Log).not_to receive(:debug).with(/Plugin linux::network threw exception/)
          expect(plugin['network']).not_to be_nil
        end

        it "sets default ipv4 interface and gateway" do
          expect(plugin['network']['default_interface']).to eq('eth0')
          expect(plugin['network']['default_gateway']).to eq('10.116.201.254')
        end

        it "sets default ipv6 interface and gateway" do
          expect(plugin['network']['default_inet6_interface']).to eq('eth0.11')
          expect(plugin['network']['default_inet6_gateway']).to eq('1111:2222:3333:4444::ffff')
        end
      end

      describe "when there're a mixed setup of routes that could be used to set ipaddress" do
        let(:linux_ip_route) {
'10.116.201.0/24 dev eth0  proto kernel  src 10.116.201.76
192.168.5.0/24 dev eth0  proto kernel  src 192.168.5.1
192.168.212.0/24 dev foo:veth0@eth0  proto kernel  src 192.168.212.2
172.16.151.0/24 dev eth0  proto kernel  src 172.16.151.100
192.168.0.0/24 dev eth0  proto kernel  src 192.168.0.2
default via 10.116.201.1 dev eth0 metric 10
default via 10.116.201.254 dev eth0 metric 9 src 10.116.201.74
'
        }

        let(:linux_ip_route_inet6) {
'fe80::/64 dev eth0  proto kernel  metric 256
fe80::/64 dev eth0.11  proto kernel  metric 256
1111:2222:3333:4444::/64 dev eth0.11  metric 1024  src 1111:2222:3333:4444::3
default via 1111:2222:3333:4444::1 dev eth0.11  metric 1024
default via 1111:2222:3333:4444::ffff dev eth0.11  metric 1023 src 1111:2222:3333:4444::2
'
        }

        before(:each) do
          plugin.run
        end

        it "completes the run" do
          expect(Ohai::Log).not_to receive(:debug).with(/Plugin linux::network threw exception/)
          expect(plugin['network']).not_to be_nil
        end

        it "sets ipaddress" do
          expect(plugin["ipaddress"]).to eq("10.116.201.74")
        end

        it "sets ip6address" do
          expect(plugin["ip6address"]).to eq("1111:2222:3333:4444::2")
        end
      end

      describe "when there's a source field in a local route entry " do
        let(:linux_ip_route) {
'10.116.201.0/24 dev eth0  proto kernel  src 10.116.201.76
192.168.5.0/24 dev eth0  proto kernel  src 192.168.5.1
192.168.212.0/24 dev foo:veth0@eth0  proto kernel  src 192.168.212.2
172.16.151.0/24 dev eth0  proto kernel  src 172.16.151.100
192.168.0.0/24 dev eth0  proto kernel  src 192.168.0.2
default via 10.116.201.1 dev eth0
'
        }

        let(:linux_ip_route_inet6) {
'fe80::/64 dev eth0  proto kernel  metric 256
fe80::/64 dev eth0.11  proto kernel  metric 256
1111:2222:3333:4444::/64 dev eth0.11  metric 1024  src 1111:2222:3333:4444::3
default via 1111:2222:3333:4444::1 dev eth0.11  metric 1024
'
        }

        it "completes the run" do
          expect(Ohai::Log).not_to receive(:debug).with(/Plugin linux::network threw exception/)
          plugin.run
          expect(plugin['network']).not_to be_nil
        end

        it "sets ipaddress" do
          plugin.run
          expect(plugin['ipaddress']).to eq("10.116.201.76")
        end

        describe "when about to set macaddress" do
          it "sets macaddress" do
            plugin.run
            expect(plugin['macaddress']).to eq("12:31:3D:02:BE:A2")
          end

          describe "when then interface has the NOARP flag" do
            let(:linux_ip_route) {
'10.118.19.1 dev tun0 proto kernel  src 10.118.19.39
default via 172.16.19.1 dev tun0
'
            }

            it "completes the run" do
              expect(Ohai::Log).not_to receive(:debug).with(/Plugin linux::network threw exception/)
              plugin.run
              expect(plugin['network']).not_to be_nil
            end

            it "doesn't set macaddress" do
              plugin.run
              expect(plugin['macaddress']).to be_nil
            end
          end
        end

        it "sets ip6address" do
          plugin.run
          expect(plugin['ip6address']).to eq("1111:2222:3333:4444::3")
        end
      end

      describe "with a link level default route" do
        let(:linux_ip_route) {
'default dev venet0 scope link
'
        }

        before(:each) do
          plugin.run
        end

        it "completes the run" do
          expect(Ohai::Log).not_to receive(:debug).with(/Plugin linux::network threw exception/)
          expect(plugin['network']).not_to be_nil
        end

        it "doesn't set ipaddress" do
          expect(plugin['ipaddress']).to be_nil
        end
      end

      describe "when not having a global scope ipv6 address" do
        let(:linux_ip_route_inet6) {
'fe80::/64 dev eth0  proto kernel  metric 256
default via fe80::21c:eff:fe12:3456 dev eth0.153  src fe80::2e0:81ff:fe2b:48e7  metric 1024
'
        }
        before(:each) do
          plugin.run
        end

        it "completes the run" do
          expect(Ohai::Log).not_to receive(:debug).with(/Plugin linux::network threw exception/)
          expect(plugin['network']).not_to be_nil
        end

        it "doesn't set ip6address" do
          expect(plugin['ip6address']).to be_nil
        end

      end

      describe "with no default route" do
        let(:linux_ip_route) {
'10.116.201.0/24 dev eth0  proto kernel  src 10.116.201.76
192.168.5.0/24 dev eth0  proto kernel  src 192.168.5.1
192.168.212.0/24 dev foo:veth0@eth0  proto kernel  src 192.168.212.2
172.16.151.0/24 dev eth0  proto kernel  src 172.16.151.100
192.168.0.0/24 dev eth0  proto kernel  src 192.168.0.2
'
        }

        let(:linux_ip_route_inet6) {
'fe80::/64 dev eth0  proto kernel  metric 256
fe80::/64 dev eth0.11  proto kernel  metric 256
1111:2222:3333:4444::/64 dev eth0.11  metric 1024  src 1111:2222:3333:4444::3
'
        }

        before(:each) do
          plugin.run
        end

        it "completes the run" do
          expect(Ohai::Log).not_to receive(:debug).with(/Plugin linux::network threw exception/)
          expect(plugin['network']).not_to be_nil
        end

        it "doesn't set ipaddress" do
          expect(plugin['ipaddress']).to be_nil
        end

        it "doesn't set ip6address" do
          expect(plugin['ip6address']).to be_nil
        end
      end

      describe "with irrelevant routes (container setups)" do
        let(:linux_ip_route) {
'10.116.201.0/26 dev eth0 proto kernel  src 10.116.201.39
10.116.201.0/26 dev if4 proto kernel  src 10.116.201.45
10.118.19.0/26 dev eth0 proto kernel  src 10.118.19.39
10.118.19.0/26 dev if5 proto kernel  src 10.118.19.45
default via 10.116.201.1 dev eth0  src 10.116.201.99
'
        }

        let(:linux_ip_route_inet6) {
'fe80::/64 dev eth0  proto kernel  metric 256
fe80::/64 dev eth0.11  proto kernel  metric 256
1111:2222:3333:4444::/64 dev eth0.11  metric 1024 src 1111:2222:3333:4444::FFFF:2
default via 1111:2222:3333:4444::1 dev eth0.11  metric 1024
'
        }

        before(:each) do
          plugin.run
        end

        it "completes the run" do
          expect(Ohai::Log).not_to receive(:debug).with(/Plugin linux::network threw exception/)
          expect(plugin['network']).not_to be_nil
        end

        it "doesn't add bogus routes" do
          expect(plugin['network']['interfaces']['eth0']['routes']).not_to include Mash.new( :destination => "10.116.201.0/26", :proto => "kernel", :family => "inet", :via => "10.116.201.39" )
          expect(plugin['network']['interfaces']['eth0']['routes']).not_to include Mash.new( :destination => "10.118.19.0/26", :proto => "kernel", :family => "inet", :via => "10.118.19.39" )
          expect(plugin['network']['interfaces']['eth0']['routes']).not_to include Mash.new( :destination => "1111:2222:3333:4444::/64", :family => "inet6", :metric => "1024" )
        end

        it "doesn't set ipaddress" do
          expect(plugin['ipaddress']).to be_nil
        end

        it "doesn't set ip6address" do
          expect(plugin['ip6address']).to be_nil
        end
      end

      # This should never happen in the real world.
      describe "when encountering a surprise interface" do
        let(:linux_ip_route) {
'192.168.122.0/24 dev virbr0  proto kernel  src 192.168.122.1
'
        }

        it "logs a message and skips previously unseen interfaces in 'ip route show'" do
          expect(Ohai::Log).to receive(:debug).with("Skipping previously unseen interface from 'ip route show': virbr0").once
          allow(Ohai::Log).to receive(:debug) # Catches the 'Loading plugin network' type messages
          plugin.run
        end
      end

      describe "when running with ip version ss131122" do
        let(:linux_ip_link_s_d) {
'1: lo: <LOOPBACK,UP,LOWER_UP> mtu 16436 qdisc noqueue state UNKNOWN mode DEFAULT group default
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00 promiscuity 0
    RX: bytes  packets  errors  dropped overrun mcast
    35224      524      0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    35224      524      0       0       0       0
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 12:31:3d:02:be:a2 brd ff:ff:ff:ff:ff:ff promiscuity 0
    RX: bytes  packets  errors  dropped overrun mcast
    1392844460 2659966  0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    691785313  1919690  0       0       0       0
3: eth0.11@eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default
    link/ether 00:0c:29:41:71:45 brd ff:ff:ff:ff:ff:ff promiscuity 0
    vlan protocol 802.1Q id 11 <REORDER_HDR>
    RX: bytes  packets  errors  dropped overrun mcast
    0          0        0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    0          0        0       0       0       0
4: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN mode DEFAULT group default qlen 100
    link/none promiscuity 0
    RX: bytes  packets  errors  dropped overrun mcast
    1392844460 2659966  0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    691785313  1919690  0       0       0       0
5: venet0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/void promiscuity 0
    RX: bytes  packets  errors  dropped overrun mcast
    1392844460 2659966  0       0       0       0
    TX: bytes  packets  errors  dropped carrier collsns
    691785313  1919690  0       0       0       0
'
        }

        it "adds the vlan information of an interface" do
          plugin.run
          expect(plugin['network']['interfaces']['eth0.11']['vlan']['id']).to eq('11')
          expect(plugin['network']['interfaces']['eth0.11']['vlan']['protocol']).to eq('802.1Q')
          expect(plugin['network']['interfaces']['eth0.11']['vlan']['flags']).to eq([ 'REORDER_HDR' ])
        end
      end
    end
  end
end
