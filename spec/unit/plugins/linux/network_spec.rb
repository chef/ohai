#
#  Author:: Caleb Tennis <caleb.tennis@gmail.com>
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

def prepare_data
  @ifconfig_lines = @linux_ifconfig.split("\n")
  @route_lines = @linux_route_n.split("\n")
  @arp_lines = @linux_arp_an.split("\n")
  @ipaddr_lines = @linux_ip_addr.split("\n")
  @iplink_lines = @linux_ip_link_s_d.split("\n")
  @ipneighbor_lines = @linux_ip_neighbor_show.split("\n")
  @ipneighbor_lines_inet6 = @linux_ip_inet6_neighbor_show.split("\n")
  @ip_route_lines = @linux_ip_route.split("\n")
  @ip_route_inet6_lines = @linux_ip_route_inet6.split("\n")
end

def do_stubs
  @ohai.stub!(:from).with("route -n \| grep -m 1 ^0.0.0.0").and_return(@route_lines.last)
  @ohai.stub!(:popen4).with("ifconfig -a").and_yield(nil, @stdin_ifconfig, @ifconfig_lines, nil)
  @ohai.stub!(:popen4).with("arp -an").and_yield(nil, @stdin_arp, @arp_lines, nil)
  @ohai.stub!(:popen4).with("ip -f inet neigh show").and_yield(nil, @stdin_ipneighbor, @ipneighbor_lines, nil)
  @ohai.stub!(:popen4).with("ip -f inet6 neigh show").and_yield(nil, @stdin_ipneighbor_inet6, @ipneighbor_lines_inet6, nil)
  @ohai.stub!(:popen4).with("ip addr").and_yield(nil, @stdin_ipaddr, @ipaddr_lines, nil)
  @ohai.stub!(:popen4).with("ip -d -s link").and_yield(nil, @stdin_iplink, @iplink_lines, nil)
  @ohai.stub!(:popen4).with("ip -f inet route show").and_yield(nil, @stdin_ip_route, @ip_route_lines, nil)
  @ohai.stub!(:popen4).with("ip -f inet6 route show").and_yield(nil, @stdin_ip_route_inet6, @ip_route_inet6_lines, nil)
end

describe Ohai::System, "Linux Network Plugin" do

  before do
    @linux_ifconfig = <<-ENDIFCONFIG
eth0      Link encap:Ethernet  HWaddr 12:31:3D:02:BE:A2  
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
ENDIFCONFIG
# Note that ifconfig shows foo:veth0@eth0 but fails to show any address information.
# This was not a mistake collecting the output and Apparently ifconfig is broken in this regard.

    @linux_ip_addr = <<-IP_ADDR
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 16436 qdisc noqueue state UNKNOWN 
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
IP_ADDR

    @linux_ip_link_s_d = <<-IP_LINK_S
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 16436 qdisc noqueue state UNKNOWN 
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
IP_LINK_S

    @linux_route_n = <<-ROUTE_N
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
10.116.201.0    0.0.0.0         255.255.255.0   U     0      0        0 eth0
169.254.0.0     0.0.0.0         255.255.0.0     U     1002   0        0 eth0
0.0.0.0         10.116.201.1    0.0.0.0         UG    0      0        0 eth0
ROUTE_N

    @linux_arp_an = <<-ARP_AN
? (10.116.201.1) at fe:ff:ff:ff:ff:ff [ether] on eth0
ARP_AN

    @linux_ip_neighbor_show = <<-NEIGHBOR_SHOW
10.116.201.1 dev eth0 lladdr fe:ff:ff:ff:ff:ff REACHABLE
NEIGHBOR_SHOW

    @linux_ip_inet6_neighbor_show = <<-NEIGHBOR_SHOW
1111:2222:3333:4444::1 dev eth0.11 lladdr 00:1c:0e:12:34:56 router REACHABLE
fe80::21c:eff:fe12:3456 dev eth0.11 lladdr 00:1c:0e:30:28:00 router REACHABLE
fe80::21c:eff:fe12:3456 dev eth0.153 lladdr 00:1c:0e:30:28:00 router REACHABLE
NEIGHBOR_SHOW

    @linux_ip_route = <<-IP_ROUTE_SCOPE
10.116.201.0/24 dev eth0  proto kernel
192.168.5.0/24 dev eth0  proto kernel  src 192.168.5.1
192.168.212.0/24 dev foo:veth0@eth0  proto kernel  src 192.168.212.2
172.16.151.0/24 dev eth0  proto kernel  src 172.16.151.100
192.168.0.0/24 dev eth0  proto kernel  src 192.168.0.2
default via 10.116.201.1 dev eth0
IP_ROUTE_SCOPE

    @linux_ip_route_inet6 = <<-IP_ROUTE_SCOPE
fe80::/64 dev eth0  proto kernel  metric 256
fe80::/64 dev eth0.11  proto kernel  metric 256
1111:2222:3333:4444::/64 dev eth0.11  metric 1024  expires 86023sec
default via 1111:2222:3333:4444::1 dev eth0.11  metric 1024
IP_ROUTE_SCOPE

    @stdin_ifconfig = StringIO.new
    @stdin_arp = StringIO.new
    @stdin_ipaddr = StringIO.new
    @stdin_iplink = StringIO.new
    @stdin_ipneighbor = StringIO.new
    @stdin_ipneighbor_inet6 = StringIO.new
    @stdin_ip_route = StringIO.new
    @stdin_ip_route_inet6 = StringIO.new

    prepare_data
    
    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)

    @ohai.stub(:popen4).with("ifconfig -a")
    @ohai.stub(:popen4).with("arp -an")
    
    Ohai::Log.should_receive(:warn).with(/unable to detect/).exactly(3).times
    @ohai._require_plugin("network")
  end

  ["ifconfig","iproute2"].each do |network_method|

    describe "gathering IP layer address info via #{network_method}" do
      before do
        File.stub!(:exist?).with("/sbin/ip").and_return( network_method == "iproute2" )
        do_stubs
      end

      it "completes the run" do
        Ohai::Log.should_not_receive(:debug).with(/Plugin linux::network threw exception/)
        @ohai._require_plugin("linux::network")
        @ohai['network'].should_not be_nil
      end

      it "detects the interfaces" do
        @ohai._require_plugin("linux::network")
        @ohai['network']['interfaces'].keys.sort.should == ["eth0", "eth0.11", "eth0.151", "eth0.152", "eth0.153", "eth0:5", "foo:veth0@eth0", "lo", "tun0", "venet0", "venet0:0"]
      end

      it "detects the ipv4 addresses of the ethernet interface" do
        @ohai._require_plugin("linux::network")
        @ohai['network']['interfaces']['eth0']['addresses'].keys.should include('10.116.201.76')
        @ohai['network']['interfaces']['eth0']['addresses']['10.116.201.76']['netmask'].should == '255.255.255.0'
        @ohai['network']['interfaces']['eth0']['addresses']['10.116.201.76']['broadcast'].should == '10.116.201.255'
        @ohai['network']['interfaces']['eth0']['addresses']['10.116.201.76']['family'].should == 'inet'
      end

      it "detects the ipv4 addresses of an ethernet subinterface" do
        @ohai._require_plugin("linux::network")
        @ohai['network']['interfaces']['eth0.11']['addresses'].keys.should include('192.168.0.16')
        @ohai['network']['interfaces']['eth0.11']['addresses']['192.168.0.16']['netmask'].should == '255.255.255.0'
        @ohai['network']['interfaces']['eth0.11']['addresses']['192.168.0.16']['broadcast'].should == '192.168.0.255'
        @ohai['network']['interfaces']['eth0.11']['addresses']['192.168.0.16']['family'].should == 'inet'
      end

      it "detects the ipv6 addresses of the ethernet interface" do
        @ohai._require_plugin("linux::network")
        @ohai['network']['interfaces']['eth0']['addresses'].keys.should include('fe80::1031:3dff:fe02:bea2')
        @ohai['network']['interfaces']['eth0']['addresses']['fe80::1031:3dff:fe02:bea2']['scope'].should == 'Link'
        @ohai['network']['interfaces']['eth0']['addresses']['fe80::1031:3dff:fe02:bea2']['prefixlen'].should == '64'
        @ohai['network']['interfaces']['eth0']['addresses']['fe80::1031:3dff:fe02:bea2']['family'].should == 'inet6'
      end

      it "detects the ipv6 addresses of an ethernet subinterface" do
        @ohai._require_plugin("linux::network")
        %w[ 1111:2222:3333:4444::2 1111:2222:3333:4444::3 ].each  do |addr|
          @ohai['network']['interfaces']['eth0.11']['addresses'].keys.should include(addr)
          @ohai['network']['interfaces']['eth0.11']['addresses'][addr]['scope'].should == 'Global'
          @ohai['network']['interfaces']['eth0.11']['addresses'][addr]['prefixlen'].should == '64'
          @ohai['network']['interfaces']['eth0.11']['addresses'][addr]['family'].should == 'inet6'
        end
      end

      it "detects the mac addresses of the ethernet interface" do
        @ohai._require_plugin("linux::network")
        @ohai['network']['interfaces']['eth0']['addresses'].keys.should include('12:31:3D:02:BE:A2')
        @ohai['network']['interfaces']['eth0']['addresses']['12:31:3D:02:BE:A2']['family'].should == 'lladdr'
      end

      it "detects the encapsulation type of the ethernet interface" do
        @ohai._require_plugin("linux::network")
        @ohai['network']['interfaces']['eth0']['encapsulation'].should == 'Ethernet'
      end

      it "detects the flags of the ethernet interface" do
        @ohai._require_plugin("linux::network")
        if network_method == "ifconfig"
          @ohai['network']['interfaces']['eth0']['flags'].sort.should == ['BROADCAST','MULTICAST','RUNNING','UP']
        else
          @ohai['network']['interfaces']['eth0']['flags'].sort.should == ['BROADCAST','LOWER_UP','MULTICAST','UP']
        end
      end

      it "detects the number of the ethernet interface" do
        @ohai._require_plugin("linux::network")
        @ohai['network']['interfaces']['eth0']['number'].should == "0"
      end

      it "detects the mtu of the ethernet interface" do
        @ohai._require_plugin("linux::network")
        @ohai['network']['interfaces']['eth0']['mtu'].should == "1500"
      end
    
      it "detects the ipv4 addresses of the loopback interface" do
        @ohai._require_plugin("linux::network")
        @ohai['network']['interfaces']['lo']['addresses'].keys.should include('127.0.0.1')
        @ohai['network']['interfaces']['lo']['addresses']['127.0.0.1']['netmask'].should == '255.0.0.0'
        @ohai['network']['interfaces']['lo']['addresses']['127.0.0.1']['family'].should == 'inet'
      end

      it "detects the ipv6 addresses of the loopback interface" do
        @ohai._require_plugin("linux::network")
        @ohai['network']['interfaces']['lo']['addresses'].keys.should include('::1')
        @ohai['network']['interfaces']['lo']['addresses']['::1']['scope'].should == 'Node'
        @ohai['network']['interfaces']['lo']['addresses']['::1']['prefixlen'].should == '128'
        @ohai['network']['interfaces']['lo']['addresses']['::1']['family'].should == 'inet6'
      end

      it "detects the encapsulation type of the loopback interface" do
        @ohai._require_plugin("linux::network")
        @ohai['network']['interfaces']['lo']['encapsulation'].should == 'Loopback'
      end

      it "detects the flags of the ethernet interface" do
        @ohai._require_plugin("linux::network")
        if network_method == "ifconfig"
          @ohai['network']['interfaces']['lo']['flags'].sort.should == ['LOOPBACK','RUNNING','UP']
        else
          @ohai['network']['interfaces']['lo']['flags'].sort.should == ['LOOPBACK','LOWER_UP','UP']
        end
      end


      it "detects the mtu of the loopback interface" do
        @ohai._require_plugin("linux::network")
        @ohai['network']['interfaces']['lo']['mtu'].should == "16436"
      end

      it "detects the arp entries" do
        @ohai._require_plugin("linux::network")
        @ohai['network']['interfaces']['eth0']['arp']['10.116.201.1'].should == 'fe:ff:ff:ff:ff:ff'
      end

    end
  
    describe "gathering interface counters via #{network_method}" do
      before do
        File.stub!(:exist?).with("/sbin/ip").and_return( network_method == "iproute2" )
        do_stubs
        @ohai._require_plugin("linux::network")
      end

      it "detects the ethernet counters" do
        @ohai['counters']['network']['interfaces']['eth0']['tx']['bytes'].should == "691785313"
        @ohai['counters']['network']['interfaces']['eth0']['tx']['packets'].should == "1919690"
        @ohai['counters']['network']['interfaces']['eth0']['tx']['collisions'].should == "0"
        @ohai['counters']['network']['interfaces']['eth0']['tx']['queuelen'].should == "1000"
        @ohai['counters']['network']['interfaces']['eth0']['tx']['errors'].should == "0"
        @ohai['counters']['network']['interfaces']['eth0']['tx']['carrier'].should == "0"
        @ohai['counters']['network']['interfaces']['eth0']['tx']['drop'].should == "0"

        @ohai['counters']['network']['interfaces']['eth0']['rx']['bytes'].should == "1392844460"
        @ohai['counters']['network']['interfaces']['eth0']['rx']['packets'].should == "2659966"
        @ohai['counters']['network']['interfaces']['eth0']['rx']['errors'].should == "0"
        @ohai['counters']['network']['interfaces']['eth0']['rx']['overrun'].should == "0"
        @ohai['counters']['network']['interfaces']['eth0']['rx']['drop'].should == "0"
      end

      it "detects the loopback counters" do
        @ohai['counters']['network']['interfaces']['lo']['tx']['bytes'].should == "35224"
        @ohai['counters']['network']['interfaces']['lo']['tx']['packets'].should == "524"
        @ohai['counters']['network']['interfaces']['lo']['tx']['collisions'].should == "0"
        @ohai['counters']['network']['interfaces']['lo']['tx']['errors'].should == "0"
        @ohai['counters']['network']['interfaces']['lo']['tx']['carrier'].should == "0"
        @ohai['counters']['network']['interfaces']['lo']['tx']['drop'].should == "0"

        @ohai['counters']['network']['interfaces']['lo']['rx']['bytes'].should == "35224"
        @ohai['counters']['network']['interfaces']['lo']['rx']['packets'].should == "524"
        @ohai['counters']['network']['interfaces']['lo']['rx']['errors'].should == "0"
        @ohai['counters']['network']['interfaces']['lo']['rx']['overrun'].should == "0"
        @ohai['counters']['network']['interfaces']['lo']['rx']['drop'].should == "0"
      end
    end

    describe "setting the node's default IP address attribute with #{network_method}" do
      before do
        File.stub!(:exist?).with("/sbin/ip").and_return( network_method == "iproute2" )
        do_stubs
      end

      describe "without a subinterface" do
        before do
          @ohai._require_plugin("linux::network")
        end
  
        it "finds the default interface by asking which iface has the default route" do
          @ohai['network']['default_interface'].should == 'eth0'
        end
  
        it "finds the default gateway by asking which iface has the default route" do
          @ohai['network']['default_gateway'].should == '10.116.201.1'
        end
      end
  
      describe "with a link level default route" do
        before do
          @linux_ip_route = <<-IP_ROUTE
10.116.201.0/24 dev eth0  proto kernel
default dev eth0 scope link
IP_ROUTE
          @linux_route_n = <<-ROUTE_N
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
10.116.201.0    0.0.0.0         255.255.255.0   U     0      0        0 eth0
0.0.0.0         0.0.0.0         0.0.0.0         U     0      0        0 eth0
ROUTE_N
          prepare_data
          do_stubs

          @ohai._require_plugin("linux::network")
        end

        it "finds the default interface by asking which iface has the default route" do
          @ohai['network']['default_interface'].should == 'eth0'
        end
  
        it "finds the default interface by asking which iface has the default route" do
          @ohai['network']['default_gateway'].should == '0.0.0.0'
        end
      end

      describe "with a subinterface" do
        before do
          @linux_ip_route = <<-IP_ROUTE
192.168.0.0/24 dev eth0.11  proto kernel  src 192.168.0.2
default via 192.168.0.15 dev eth0.11
IP_ROUTE
          @linux_route_n = <<-ROUTE_N
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
192.168.0.0    0.0.0.0         255.255.255.0   U     0      0        0 eth0.11
0.0.0.0         192.168.0.15   0.0.0.0         UG    0      0        0 eth0.11
ROUTE_N

          prepare_data
          do_stubs

          @ohai._require_plugin("linux::network")
        end
  
        it "finds the default interface by asking which iface has the default route" do
          @ohai['network']["default_interface"].should == 'eth0.11'
        end
  
        it "finds the default interface by asking which iface has the default route" do
          @ohai['network']["default_gateway"].should == '192.168.0.15'
        end
      end
    end
  end

  describe "for newer network features using iproute2 only" do
    before do
      File.stub!(:exist?).with("/sbin/ip").and_return(true) # iproute2 only
      do_stubs
    end

    it "completes the run" do
      Ohai::Log.should_not_receive(:debug).with(/Plugin linux::network threw exception/)
      @ohai._require_plugin("linux::network")
      @ohai['network'].should_not be_nil
    end

    it "finds the default inet6 interface if there's a inet6 default route" do
      @ohai._require_plugin("linux::network")
      @ohai['network']['default_inet6_interface'].should == 'eth0.11'
    end

    it "finds the default inet6 gateway if there's a inet6 default route" do
      @ohai._require_plugin("linux::network")
      @ohai['network']['default_inet6_gateway'].should == '1111:2222:3333:4444::1'
    end

    it "finds inet6 neighbours" do
      @ohai._require_plugin("linux::network")
      @ohai['network']['interfaces']['eth0.11']['neighbour_inet6']['1111:2222:3333:4444::1'].should == '00:1c:0e:12:34:56'
    end

    it "detects the ipv4 addresses of an ethernet interface with a crazy name" do
      @ohai._require_plugin("linux::network")
      @ohai['network']['interfaces']['foo:veth0@eth0']['addresses'].keys.should include('192.168.212.2')
      @ohai['network']['interfaces']['foo:veth0@eth0']['addresses']['192.168.212.2']['netmask'].should == '255.255.255.0'
      @ohai['network']['interfaces']['foo:veth0@eth0']['addresses']['192.168.212.2']['family'].should == 'inet'
    end

    it "generates a fake interface for ip aliases for backward compatibility" do
      @ohai._require_plugin("linux::network")
      @ohai['network']['interfaces']['eth0:5']['addresses'].keys.should include('192.168.5.1')
      @ohai['network']['interfaces']['eth0:5']['addresses']['192.168.5.1']['netmask'].should == '255.255.255.0'
      @ohai['network']['interfaces']['eth0:5']['addresses']['192.168.5.1']['family'].should == 'inet'
    end

    it "adds the vlan information of an interface" do
      @ohai._require_plugin("linux::network")
      @ohai['network']['interfaces']['eth0.11']['vlan']['id'].should == '11'
      @ohai['network']['interfaces']['eth0.11']['vlan']['flags'].should == [ 'REORDER_HDR' ]
    end

    it "adds the state of an interface" do
      @ohai._require_plugin("linux::network")
      @ohai['network']['interfaces']['eth0.11']['state'].should == 'up'
    end

    describe "when dealing with routes" do
      it "adds routes" do
        @ohai._require_plugin("linux::network")
        @ohai['network']['interfaces']['eth0']['routes'].should include Mash.new( :destination => "10.116.201.0/24", :proto => "kernel", :family =>"inet" )
        @ohai['network']['interfaces']['foo:veth0@eth0']['routes'].should include Mash.new( :destination => "192.168.212.0/24", :proto => "kernel", :src => "192.168.212.2", :family =>"inet" )
        @ohai['network']['interfaces']['eth0']['routes'].should include Mash.new( :destination => "fe80::/64", :metric => "256", :proto => "kernel", :family => "inet6" )
        @ohai['network']['interfaces']['eth0.11']['routes'].should include Mash.new( :destination => "1111:2222:3333:4444::/64", :metric => "1024", :family => "inet6" )
        @ohai['network']['interfaces']['eth0.11']['routes'].should include Mash.new( :destination => "default", :via => "1111:2222:3333:4444::1", :metric => "1024", :family => "inet6")
      end

      describe "when there isn't a source field in route entries " do
        it "doesn't set ipaddress" do
          @ohai._require_plugin("linux::network")
          @ohai['ipaddress'].should be nil
        end

        it "doesn't set macaddress" do
          @ohai._require_plugin("linux::network")
          @ohai['macaddress'].should be nil
        end

        it "doesn't set ip6address" do
          @ohai._require_plugin("linux::network")
          @ohai['ip6address'].should be nil
        end
      end

      describe "when there's a source field in the default route entry" do
        before do
          @linux_ip_route = <<-IP_ROUTE_SCOPE
10.116.201.0/24 dev eth0  proto kernel
192.168.5.0/24 dev eth0  proto kernel  src 192.168.5.1
192.168.212.0/24 dev foo:veth0@eth0  proto kernel  src 192.168.212.2
172.16.151.0/24 dev eth0  proto kernel  src 172.16.151.100
192.168.0.0/24 dev eth0  proto kernel  src 192.168.0.2
default via 10.116.201.1 dev eth0  src 10.116.201.76
IP_ROUTE_SCOPE

          @linux_ip_route_inet6 = <<-IP_ROUTE_SCOPE
fe80::/64 dev eth0  proto kernel  metric 256
fe80::/64 dev eth0.11  proto kernel  metric 256
1111:2222:3333:4444::/64 dev eth0.11  metric 1024
default via 1111:2222:3333:4444::1 dev eth0.11  metric 1024  src 1111:2222:3333:4444::3
IP_ROUTE_SCOPE

          prepare_data
          do_stubs
        end

        it "completes the run" do
          Ohai::Log.should_not_receive(:debug).with(/Plugin linux::network threw exception/)
          @ohai._require_plugin("linux::network")
          @ohai['network'].should_not be_nil
        end

        it "sets ipaddress" do
          @ohai._require_plugin("linux::network")
          @ohai['ipaddress'].should == "10.116.201.76"
        end

        it "sets ip6address" do
          @ohai._require_plugin("linux::network")
          @ohai['ip6address'].should == "1111:2222:3333:4444::3"
        end
      end

      describe "when there're several default routes" do
        before do
          @linux_ip_route = <<-IP_ROUTE_SCOPE
10.116.201.0/24 dev eth0  proto kernel  src 10.116.201.76
192.168.5.0/24 dev eth0  proto kernel  src 192.168.5.1
192.168.212.0/24 dev foo:veth0@eth0  proto kernel  src 192.168.212.2
172.16.151.0/24 dev eth0  proto kernel  src 172.16.151.100
192.168.0.0/24 dev eth0  proto kernel  src 192.168.0.2
default via 10.116.201.1 dev eth0 metric 10
default via 10.116.201.254 dev eth0 metric 9
IP_ROUTE_SCOPE

          @linux_ip_route_inet6 = <<-IP_ROUTE_SCOPE
fe80::/64 dev eth0  proto kernel  metric 256
fe80::/64 dev eth0.11  proto kernel  metric 256
1111:2222:3333:4444::/64 dev eth0.11  metric 1024  src 1111:2222:3333:4444::3
default via 1111:2222:3333:4444::1 dev eth0.11  metric 1024
default via 1111:2222:3333:4444::ffff dev eth0.11  metric 1023
IP_ROUTE_SCOPE

          prepare_data
          do_stubs
        end

        it "completes the run" do
          Ohai::Log.should_not_receive(:debug).with(/Plugin linux::network threw exception/)
          @ohai._require_plugin("linux::network")
          @ohai['network'].should_not be_nil
        end

        it "sets default ipv4 interface and gateway" do
          @ohai._require_plugin("linux::network")
          @ohai['network']['default_interface'].should == 'eth0'
          @ohai['network']['default_gateway'].should == '10.116.201.254'
        end

        it "sets default ipv6 interface and gateway" do
          @ohai._require_plugin("linux::network")
          @ohai['network']['default_inet6_interface'].should == 'eth0.11'
          @ohai['network']['default_inet6_gateway'].should == '1111:2222:3333:4444::ffff'
        end
      end

      describe "when there're a mixed setup of routes that could be used to set ipaddress" do
        before do
          @linux_ip_route = <<-IP_ROUTE_SCOPE
10.116.201.0/24 dev eth0  proto kernel  src 10.116.201.76
192.168.5.0/24 dev eth0  proto kernel  src 192.168.5.1
192.168.212.0/24 dev foo:veth0@eth0  proto kernel  src 192.168.212.2
172.16.151.0/24 dev eth0  proto kernel  src 172.16.151.100
192.168.0.0/24 dev eth0  proto kernel  src 192.168.0.2
default via 10.116.201.1 dev eth0 metric 10
default via 10.116.201.254 dev eth0 metric 9 src 10.116.201.74
IP_ROUTE_SCOPE

          @linux_ip_route_inet6 = <<-IP_ROUTE_SCOPE
fe80::/64 dev eth0  proto kernel  metric 256
fe80::/64 dev eth0.11  proto kernel  metric 256
1111:2222:3333:4444::/64 dev eth0.11  metric 1024  src 1111:2222:3333:4444::3
default via 1111:2222:3333:4444::1 dev eth0.11  metric 1024
default via 1111:2222:3333:4444::ffff dev eth0.11  metric 1023 src 1111:2222:3333:4444::2
IP_ROUTE_SCOPE

          prepare_data
          do_stubs
        end

        it "completes the run" do
          Ohai::Log.should_not_receive(:debug).with(/Plugin linux::network threw exception/)
          @ohai._require_plugin("linux::network")
          @ohai['network'].should_not be_nil
        end

        it "sets ipaddress" do
          @ohai._require_plugin("linux::network")
          @ohai["ipaddress"].should == "10.116.201.74"
        end

        it "sets ip6address" do
          @ohai._require_plugin("linux::network")
          @ohai["ip6address"].should == "1111:2222:3333:4444::2"
        end
      end

      describe "when there's a source field in a local route entry " do
        before do
          @linux_ip_route = <<-IP_ROUTE_SCOPE
10.116.201.0/24 dev eth0  proto kernel  src 10.116.201.76
192.168.5.0/24 dev eth0  proto kernel  src 192.168.5.1
192.168.212.0/24 dev foo:veth0@eth0  proto kernel  src 192.168.212.2
172.16.151.0/24 dev eth0  proto kernel  src 172.16.151.100
192.168.0.0/24 dev eth0  proto kernel  src 192.168.0.2
default via 10.116.201.1 dev eth0
IP_ROUTE_SCOPE

          @linux_ip_route_inet6 = <<-IP_ROUTE_SCOPE
fe80::/64 dev eth0  proto kernel  metric 256
fe80::/64 dev eth0.11  proto kernel  metric 256
1111:2222:3333:4444::/64 dev eth0.11  metric 1024  src 1111:2222:3333:4444::3
default via 1111:2222:3333:4444::1 dev eth0.11  metric 1024
IP_ROUTE_SCOPE

          prepare_data
          do_stubs
        end

        it "completes the run" do
          Ohai::Log.should_not_receive(:debug).with(/Plugin linux::network threw exception/)
          @ohai._require_plugin("linux::network")
          @ohai['network'].should_not be_nil
        end

        it "sets ipaddress" do
          @ohai._require_plugin("linux::network")
          @ohai['ipaddress'].should == "10.116.201.76"
        end

        describe "when about to set macaddress" do
          it "sets macaddress" do
            @ohai._require_plugin("linux::network")
            @ohai['macaddress'].should == "12:31:3D:02:BE:A2"
          end

          describe "when then interface has the NOARP flag" do
            before do
              @linux_ip_route = <<-IP_ROUTE
10.118.19.1 dev tun0 proto kernel  src 10.118.19.39
default via 172.16.19.1 dev tun0
IP_ROUTE

              prepare_data
              do_stubs
            end

            it "completes the run" do
              Ohai::Log.should_not_receive(:debug).with(/Plugin linux::network threw exception/)
              @ohai._require_plugin("linux::network")
              @ohai['network'].should_not be_nil
            end

            it "doesn't set macaddress" do
              @ohai._require_plugin("linux::network")
              @ohai['macaddress'].should be_nil
            end
          end
        end

        it "sets ip6address" do
          @ohai._require_plugin("linux::network")
          @ohai['ip6address'].should == "1111:2222:3333:4444::3"
        end
      end

      describe "with a link level default route" do
        before do
          @linux_ip_route = <<-IP_ROUTE
default dev venet0 scope link
IP_ROUTE

          prepare_data
          do_stubs
        end

        it "completes the run" do
          Ohai::Log.should_not_receive(:debug).with(/Plugin linux::network threw exception/)
          @ohai._require_plugin("linux::network")
          @ohai['network'].should_not be_nil
        end

        it "doesn't set ipaddress" do
          @ohai._require_plugin("linux::network")
          @ohai['ipaddress'].should be_nil
        end
      end

      describe "when not having a global scope ipv6 address" do
        before do
          @linux_ip_route_inet6 = <<-IP_ROUTE_SCOPE
fe80::/64 dev eth0  proto kernel  metric 256
default via fe80::21c:eff:fe12:3456 dev eth0.153  src fe80::2e0:81ff:fe2b:48e7  metric 1024
IP_ROUTE_SCOPE

          prepare_data
          do_stubs
        end

        it "completes the run" do
          Ohai::Log.should_not_receive(:debug).with(/Plugin linux::network threw exception/)
          @ohai._require_plugin("linux::network")
          @ohai['network'].should_not be_nil
        end

        it "doesn't set ip6address" do
          @ohai._require_plugin("linux::network")
          @ohai['ip6address'].should be_nil
        end

      end

      describe "with no default route" do
        before do
          @linux_ip_route = <<-IP_ROUTE
10.116.201.0/24 dev eth0  proto kernel  src 10.116.201.76
192.168.5.0/24 dev eth0  proto kernel  src 192.168.5.1
192.168.212.0/24 dev foo:veth0@eth0  proto kernel  src 192.168.212.2
172.16.151.0/24 dev eth0  proto kernel  src 172.16.151.100
192.168.0.0/24 dev eth0  proto kernel  src 192.168.0.2
IP_ROUTE

          @linux_ip_route_inet6 = <<-IP_ROUTE
fe80::/64 dev eth0  proto kernel  metric 256
fe80::/64 dev eth0.11  proto kernel  metric 256
1111:2222:3333:4444::/64 dev eth0.11  metric 1024  src 1111:2222:3333:4444::3
IP_ROUTE

          prepare_data
          do_stubs
        end

        it "completes the run" do
          Ohai::Log.should_not_receive(:debug).with(/Plugin linux::network threw exception/)
          @ohai._require_plugin("linux::network")
          @ohai['network'].should_not be_nil
        end

        it "doesn't set ipaddress" do
          @ohai._require_plugin("linux::network")
          @ohai['ipaddress'].should be_nil
        end

        it "doesn't set ip6address" do
          @ohai._require_plugin("linux::network")
          @ohai['ip6address'].should be_nil
        end
      end

      describe "with irrelevant routes (container setups)" do
        before do
          @linux_ip_route = <<-IP_ROUTE
10.116.201.0/26 dev eth0 proto kernel  src 10.116.201.39
10.116.201.0/26 dev if4 proto kernel  src 10.116.201.45
10.118.19.0/26 dev eth0 proto kernel  src 10.118.19.39
10.118.19.0/26 dev if5 proto kernel  src 10.118.19.45
default via 10.116.201.1 dev eth0  src 10.116.201.99
IP_ROUTE

          @linux_ip_route_inet6 = <<-IP_ROUTE
fe80::/64 dev eth0  proto kernel  metric 256
fe80::/64 dev eth0.11  proto kernel  metric 256
1111:2222:3333:4444::/64 dev eth0.11  metric 1024 src 1111:2222:3333:4444::FFFF:2
default via 1111:2222:3333:4444::1 dev eth0.11  metric 1024
IP_ROUTE

          prepare_data
          do_stubs
        end

        it "completes the run" do
          Ohai::Log.should_not_receive(:debug).with(/Plugin linux::network threw exception/)
          @ohai._require_plugin("linux::network")
          @ohai['network'].should_not be_nil
        end

        it "doesn't add bogus routes" do
          @ohai._require_plugin("linux::network")
          @ohai['network']['interfaces']['eth0']['routes'].should_not include Mash.new( :destination => "10.116.201.0/26", :proto => "kernel", :family => "inet", :via => "10.116.201.39" )
          @ohai['network']['interfaces']['eth0']['routes'].should_not include Mash.new( :destination => "10.118.19.0/26", :proto => "kernel", :family => "inet", :via => "10.118.19.39" )
          @ohai['network']['interfaces']['eth0']['routes'].should_not include Mash.new( :destination => "1111:2222:3333:4444::/64", :family => "inet6", :metric => "1024" )
        end

        it "doesn't set ipaddress" do
          @ohai._require_plugin("linux::network")
          @ohai['ipaddress'].should be_nil
        end

        it "doesn't set ip6address" do
          @ohai._require_plugin("linux::network")
          @ohai['ip6address'].should be_nil
        end
      end

      # This should never happen in the real world.
      describe "when encountering a surprise interface" do
        before do
          @linux_ip_route = <<-IP_ROUTE
192.168.122.0/24 dev virbr0  proto kernel  src 192.168.122.1
IP_ROUTE
          prepare_data
          do_stubs
        end
        
        it "logs a message and skips previously unseen interfaces in 'ip route show'" do
          Ohai::Log.should_receive(:debug).with("Skipping previously unseen interface from 'ip route show': virbr0").once
          Ohai::Log.should_receive(:debug).any_number_of_times # Catches the 'Loading plugin network' type messages
          @ohai._require_plugin("linux::network")
        end
      end
    end
  end

end
