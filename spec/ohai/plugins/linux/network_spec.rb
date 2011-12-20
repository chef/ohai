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

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:16436  Metric:1
          RX packets:524 errors:0 dropped:0 overruns:0 frame:0
          TX packets:524 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:35224 (34.3 KiB)  TX bytes:35224 (34.3 KiB)
ENDIFCONFIG

    linux_netstat_in = <<-NETSTAT_IN
Kernel Interface table
Iface       MTU Met    RX-OK RX-ERR RX-DRP RX-OVR    TX-OK TX-ERR TX-DRP TX-OVR Flg
eth0       1500   0  2659994      0      0      0  1919707      0      0      0 BMRU
lo        16436   0      524      0      0      0      524      0      0      0 LRU
NETSTAT_IN

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

    @stdin_ifconfig = StringIO.new
    @stdin_arp = StringIO.new
    @ifconfig_lines = linux_ifconfig.split("\n")
    @route_lines = linux_route_n.split("\n")
    @arp_lines = linux_arp_an.split("\n")

    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)

    @ohai.stub(:popen4).with("ifconfig -a")
    @ohai.stub(:popen4).with("arp -an")
  end

  describe "gathering IP layer address info" do
    before do
      @ohai.stub!(:from).with("route -n \| grep -m 1 ^0.0.0.0").and_return(@route_lines.last)
      @ohai.stub!(:popen4).with("ifconfig -a").and_yield(nil, @stdin_ifconfig, @ifconfig_lines, nil)
      @ohai.stub!(:popen4).with("arp -an").and_yield(nil, @stdin_arp, @arp_lines, nil)
      @ohai._require_plugin("network")
      @ohai._require_plugin("linux::network")
    end

    it "completes the run" do
      @ohai['network'].should_not be_nil
    end

    it "detects the interfaces" do
      @ohai['network']['interfaces'].keys.sort.should == ["eth0", "lo"]
    end

    it "detects the ipv4 addresses of the ethernet interface" do
      @ohai['network']['interfaces']['eth0']['addresses'].keys.should include('10.116.201.76')
      @ohai['network']['interfaces']['eth0']['addresses']['10.116.201.76']['netmask'].should == '255.255.255.0'
      @ohai['network']['interfaces']['eth0']['addresses']['10.116.201.76']['broadcast'].should == '10.116.201.255'
      @ohai['network']['interfaces']['eth0']['addresses']['10.116.201.76']['family'].should == 'inet'
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
      @ohai['network']['interfaces']['eth0']['flags'].sort.should == ['BROADCAST','MULTICAST','RUNNING','UP']
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

    it "detects the mtu of the loopback interface" do
      @ohai['network']['interfaces']['lo']['mtu'].should == "16436"
    end

  end

 describe "setting the node's default IP address attribute" do
    before do
      @ohai.stub!(:from).with("route -n \| grep -m 1 ^0.0.0.0").and_return(@route_lines.last)
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
end

