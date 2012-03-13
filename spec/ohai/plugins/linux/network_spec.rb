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

describe Ohai::System, "Linux Network Plugin" do

  before do
    linux_ifconfig = <<-ENDIFCONFIG
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

    linux_ip_addr = <<-IP_ADDR
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
3: eth0.11@eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP 
    link/ether 00:aa:bb:cc:dd:ee brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.16/24 brd 192.168.0.255 scope global eth0.11
    inet6 fe80::2e0:81ff:fe2b:48e7/64 scope link 
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
IP_ADDR

    linux_ip_link_s = <<-IP_LINK_S
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
IP_LINK_S

    linux_route_n = <<-ROUTE_N
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
10.116.201.0    0.0.0.0         255.255.255.0   U     0      0        0 eth0
169.254.0.0     0.0.0.0         255.255.0.0     U     1002   0        0 eth0
0.0.0.0         10.116.201.1    0.0.0.0         UG    0      0        0 eth0
ROUTE_N

    linux_arp_an = <<-ARP_AN
? (10.116.201.1) at fe:ff:ff:ff:ff:ff [ether] on eth0
ARP_AN

    linux_ip_neighbor_show = <<-NEIGHBOR_SHOW
10.116.201.1 dev eth0 lladdr fe:ff:ff:ff:ff:ff REACHABLE
NEIGHBOR_SHOW

    linux_ip_route_show_exact = <<-IP_ROUTE
default via 10.116.201.1 dev eth0
IP_ROUTE

    @stdin_ifconfig = StringIO.new
    @stdin_arp = StringIO.new
    @stdin_ipaddr = StringIO.new
    @stdin_iplink = StringIO.new
    @stdin_ipneighbor = StringIO.new

    @ifconfig_lines = linux_ifconfig.split("\n")
    @route_lines = linux_route_n.split("\n")
    @arp_lines = linux_arp_an.split("\n")
    @ipaddr_lines = linux_ip_addr.split("\n")
    @iplink_lines = linux_ip_link_s.split("\n")
    @ipneighbor_lines = linux_ip_neighbor_show.split("\n")
    @iproute_lines = linux_ip_route_show_exact

    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)

    @ohai.stub(:popen4).with("ifconfig -a")
    @ohai.stub(:popen4).with("arp -an")
  end

  ["ifconfig","iproute2"].each do |network_method|

    describe "gathering IP layer address info via #{network_method}" do
      before do
        File.stub!(:exist?).with("/sbin/ip").and_return( network_method == "iproute2" )
        @ohai.stub!(:from).with("route -n \| grep -m 1 ^0.0.0.0").and_return(@route_lines.last)
        @ohai.stub!(:from).with("ip route show exact 0.0.0.0/0").and_return(@iproute_lines)
        @ohai.stub!(:popen4).with("ifconfig -a").and_yield(nil, @stdin_ifconfig, @ifconfig_lines, nil)
        @ohai.stub!(:popen4).with("arp -an").and_yield(nil, @stdin_arp, @arp_lines, nil)
        @ohai.stub!(:popen4).with("ip neighbor show").and_yield(nil, @stdin_ipneighbor, @ipneighbor_lines, nil)
        @ohai.stub!(:popen4).with("ip addr").and_yield(nil, @stdin_ipaddr, @ipaddr_lines, nil)
        @ohai.stub!(:popen4).with("ip -s link").and_yield(nil, @stdin_iplink, @iplink_lines, nil)
        @ohai._require_plugin("network")
        @ohai._require_plugin("linux::network")
      end

      it "completes the run" do
        @ohai['network'].should_not be_nil
      end

      it "detects the interfaces" do
        @ohai['network']['interfaces'].keys.sort.should == ["eth0", "eth0.11", "eth0.151", "eth0.152", "eth0.153", "eth0:5", "foo:veth0@eth0", "lo"]
      end

      it "detects the ipv4 addresses of the ethernet interface" do
        @ohai['network']['interfaces']['eth0']['addresses'].keys.should include('10.116.201.76')
        @ohai['network']['interfaces']['eth0']['addresses']['10.116.201.76']['netmask'].should == '255.255.255.0'
        @ohai['network']['interfaces']['eth0']['addresses']['10.116.201.76']['broadcast'].should == '10.116.201.255'
        @ohai['network']['interfaces']['eth0']['addresses']['10.116.201.76']['family'].should == 'inet'
      end

      it "detects the ipv4 addresses of an ethernet subinterface" do
        @ohai['network']['interfaces']['eth0.11']['addresses'].keys.should include('192.168.0.16')
        @ohai['network']['interfaces']['eth0.11']['addresses']['192.168.0.16']['netmask'].should == '255.255.255.0'
        @ohai['network']['interfaces']['eth0.11']['addresses']['192.168.0.16']['broadcast'].should == '192.168.0.255'
        @ohai['network']['interfaces']['eth0.11']['addresses']['192.168.0.16']['family'].should == 'inet'
      end

      it "detects the ipv6 addresses of the ethernet interface" do
        @ohai['network']['interfaces']['eth0']['addresses'].keys.should include('fe80::1031:3dff:fe02:bea2')
        @ohai['network']['interfaces']['eth0']['addresses']['fe80::1031:3dff:fe02:bea2']['scope'].should == 'Link'
        @ohai['network']['interfaces']['eth0']['addresses']['fe80::1031:3dff:fe02:bea2']['prefixlen'].should == '64'
        @ohai['network']['interfaces']['eth0']['addresses']['fe80::1031:3dff:fe02:bea2']['family'].should == 'inet6'
      end

      it "detects the mac addresses of the ethernet interface" do
        @ohai['network']['interfaces']['eth0']['addresses'].keys.should include('12:31:3D:02:BE:A2')
        @ohai['network']['interfaces']['eth0']['addresses']['12:31:3D:02:BE:A2']['family'].should == 'lladdr'
      end

      it "detects the encapsulation type of the ethernet interface" do
        @ohai['network']['interfaces']['eth0']['encapsulation'].should == 'Ethernet'
      end

      it "detects the flags of the ethernet interface" do
        if network_method == "ifconfig"
          @ohai['network']['interfaces']['eth0']['flags'].sort.should == ['BROADCAST','MULTICAST','RUNNING','UP']
        else
          @ohai['network']['interfaces']['eth0']['flags'].sort.should == ['BROADCAST','LOWER_UP','MULTICAST','UP']
        end
      end

      it "detects the number of the ethernet interface" do
        @ohai['network']['interfaces']['eth0']['number'].should == "0"
      end

      it "detects the mtu of the ethernet interface" do
        @ohai['network']['interfaces']['eth0']['mtu'].should == "1500"
      end
    
      it "detects the ipv4 addresses of the loopback interface" do
        @ohai['network']['interfaces']['lo']['addresses'].keys.should include('127.0.0.1')
        @ohai['network']['interfaces']['lo']['addresses']['127.0.0.1']['netmask'].should == '255.0.0.0'
        @ohai['network']['interfaces']['lo']['addresses']['127.0.0.1']['family'].should == 'inet'
      end

      it "detects the ipv6 addresses of the loopback interface" do
        @ohai['network']['interfaces']['lo']['addresses'].keys.should include('::1')
        @ohai['network']['interfaces']['lo']['addresses']['::1']['scope'].should == 'Node'
        @ohai['network']['interfaces']['lo']['addresses']['::1']['prefixlen'].should == '128'
        @ohai['network']['interfaces']['lo']['addresses']['::1']['family'].should == 'inet6'
      end

      it "detects the encapsulation type of the loopback interface" do
        @ohai['network']['interfaces']['lo']['encapsulation'].should == 'Loopback'
      end

      it "detects the flags of the ethernet interface" do
        if network_method == "ifconfig"
          @ohai['network']['interfaces']['lo']['flags'].sort.should == ['LOOPBACK','RUNNING','UP']
        else
          @ohai['network']['interfaces']['lo']['flags'].sort.should == ['LOOPBACK','LOWER_UP','UP']
        end
      end


      it "detects the mtu of the loopback interface" do
        @ohai['network']['interfaces']['lo']['mtu'].should == "16436"
      end

      it "detects the arp entries" do
        @ohai['network']['interfaces']['eth0']['arp']['10.116.201.1'].should == 'fe:ff:ff:ff:ff:ff'
      end

    end
  
    describe "gathering interface counters via #{network_method}" do
      before do
        File.stub!(:exist?).with("/sbin/ip").and_return( network_method == "iproute2" )
        @ohai.stub!(:from).with("route -n \| grep -m 1 ^0.0.0.0").and_return(@route_lines.last)
        @ohai.stub!(:from).with("ip route show exact 0.0.0.0/0").and_return(@iproute_lines)
        @ohai.stub!(:popen4).with("ifconfig -a").and_yield(nil, @stdin_ifconfig, @ifconfig_lines, nil)
        @ohai.stub!(:popen4).with("arp -an").and_yield(nil, @stdin_arp, @arp_lines, nil)
        @ohai.stub!(:popen4).with("ip neighbor show").and_yield(nil, @stdin_ipneighbor, @ipneighbor_lines, nil)
        @ohai.stub!(:popen4).with("ip addr").and_yield(nil, @stdin_ipaddr, @ipaddr_lines, nil)
        @ohai.stub!(:popen4).with("ip -s link").and_yield(nil, @stdin_iplink, @iplink_lines, nil)
        @ohai._require_plugin("network")
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
        @ohai.stub!(:from).with("route -n \| grep -m 1 ^0.0.0.0").and_return(@route_lines.last)
        @ohai.stub!(:from).with("ip route show exact 0.0.0.0/0").and_return(@iproute_lines)
        @ohai.stub!(:popen4).with("ifconfig -a").and_yield(nil, @stdin_ifconfig, @ifconfig_lines, nil)
        @ohai.stub!(:popen4).with("arp -an").and_yield(nil, @stdin_arp, @arp_lines, nil)
        @ohai.stub!(:popen4).with("ip neighbor show").and_yield(nil, @stdin_ipneighbor, @ipneighbor_lines, nil)
        @ohai.stub!(:popen4).with("ip addr").and_yield(nil, @stdin_ipaddr, @ipaddr_lines, nil)
        @ohai.stub!(:popen4).with("ip -s link").and_yield(nil, @stdin_iplink, @iplink_lines, nil)
      end

      describe "without a subinterface" do
        before do
          @ohai._require_plugin("network")
          @ohai._require_plugin("linux::network")
        end
  
        it "finds the default interface by asking which iface has the default route" do
          @ohai['network'][:default_interface].should == 'eth0'
        end
  
        it "finds the default interface by asking which iface has the default route" do
          @ohai['network'][:default_gateway].should == '10.116.201.1'
        end
      end
  
      describe "with a subinterface" do
        before do
          linux_ip_route_show_exact = <<-IP_ROUTE
default via 192.168.0.15 dev eth0.11
IP_ROUTE
          linux_route_n = <<-ROUTE_N
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
192.168.0.0    0.0.0.0         255.255.255.0   U     0      0        0 eth0.11
10.151.0.0      0.0.0.0         255.255.255.0   U     0      0        0 eth0.151
10.151.1.0      0.0.0.0         255.255.255.0   U     0      0        0 eth0.151
10.152.0.0      0.0.0.0         255.255.252.0   U     0      0        0 eth0.152
10.153.0.0      0.0.0.0         255.255.252.0   U     0      0        0 eth0.153
0.0.0.0         192.168.0.15   0.0.0.0         UG    0      0        0 eth0.11
ROUTE_N

          @iproute_lines = linux_ip_route_show_exact
          @route_lines = linux_route_n.split("\n")
          @ohai.stub!(:from).with("route -n \| grep -m 1 ^0.0.0.0").and_return(@route_lines.last)
          @ohai.stub!(:from).with("ip route show exact 0.0.0.0/0").and_return(@iproute_lines)
          @ohai._require_plugin("network")
          @ohai._require_plugin("linux::network")
        end
  
        it "finds the default interface by asking which iface has the default route" do
          @ohai['network'][:default_interface].should == 'eth0.11'
        end
  
        it "finds the default interface by asking which iface has the default route" do
          @ohai['network'][:default_gateway].should == '192.168.0.15'
        end
      end
    end
  end

  describe "for newer network features using iproute2 only" do
    before do
      File.stub!(:exist?).with("/sbin/ip").and_return(true) # iproute2 only
      @ohai.stub!(:from).with("route -n \| grep -m 1 ^0.0.0.0").and_return(@route_lines.last)
      @ohai.stub!(:from).with("ip route show exact 0.0.0.0/0").and_return(@iproute_lines)
      @ohai.stub!(:popen4).with("ifconfig -a").and_yield(nil, @stdin_ifconfig, @ifconfig_lines, nil)
      @ohai.stub!(:popen4).with("arp -an").and_yield(nil, @stdin_arp, @arp_lines, nil)
      @ohai.stub!(:popen4).with("ip neighbor show").and_yield(nil, @stdin_ipneighbor, @ipneighbor_lines, nil)
      @ohai.stub!(:popen4).with("ip addr").and_yield(nil, @stdin_ipaddr, @ipaddr_lines, nil)
      @ohai.stub!(:popen4).with("ip -s link").and_yield(nil, @stdin_iplink, @iplink_lines, nil)
      @ohai._require_plugin("network")
      @ohai._require_plugin("linux::network")
    end

    it "detects the ipv4 addresses of an ethernet interface with a crazy name" do
      @ohai['network']['interfaces']['foo:veth0@eth0']['addresses'].keys.should include('192.168.212.2')
      @ohai['network']['interfaces']['foo:veth0@eth0']['addresses']['192.168.212.2']['netmask'].should == '255.255.255.0'
      @ohai['network']['interfaces']['foo:veth0@eth0']['addresses']['192.168.212.2']['family'].should == 'inet'
    end

    it "generates a fake interface for ip aliases for backward compatibility" do
      @ohai['network']['interfaces']['eth0:5']['addresses'].keys.should include('192.168.5.1')
      @ohai['network']['interfaces']['eth0:5']['addresses']['192.168.5.1']['netmask'].should == '255.255.255.0'
      @ohai['network']['interfaces']['eth0:5']['addresses']['192.168.5.1']['family'].should == 'inet'
    end
  end 
end

