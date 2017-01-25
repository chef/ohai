#
#  Author:: Daniel DeLeo <dan@chef.io>
#  Copyright:: Copyright (c) 2010-2016 Chef Software, Inc.
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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "Solaris2.X network plugin" do

  before do
    @solaris_arp_rn = <<-ARP_RN
Net to Media Table: IPv4
Device   IP Address               Mask      Flags   Phys Addr
------ -------------------- --------------- ----- ---------------
rtls0  172.31.4.1           255.255.255.255       00:14:69:81:0b:c0
rtls0  172.31.4.44          255.255.255.255       00:0c:29:c4:9a:11
rtls0  172.31.5.16          255.255.255.255       de:ad:be:ef:3b:ba
rtls0  172.31.4.16          255.255.255.255       d8:d3:85:65:39:40
rtls0  172.31.4.12          255.255.255.255       d8:d3:85:bb:43:b0
rtls0  172.31.4.115         255.255.255.255       52:54:00:0d:b7:5b
rtls0  172.31.4.126         255.255.255.255       52:54:00:2d:93:0c
rtls0  172.31.4.125         255.255.255.255       02:08:20:2e:29:8d
rtls0  172.31.4.121         255.255.255.255       52:54:00:25:8a:3f
rtls0  172.31.4.103         255.255.255.255 SP    52:54:00:7f:22:e7
rtls0  172.31.4.102         255.255.255.255       02:08:20:88:38:18
rtls0  172.31.4.106         255.255.255.255       02:08:20:6d:cc:aa
rtls0  172.31.4.83          255.255.255.255       02:08:20:05:8e:75
rtls0  172.31.4.82          255.255.255.255       52:54:00:2d:93:0c
rtls0  172.31.4.81          255.255.255.255       02:08:20:37:80:87
rtls0  224.0.0.0            240.0.0.0       SM    01:00:5e:00:00:00
ARP_RN

    @solaris_ifconfig = <<-ENDIFCONFIG
lo0:3: flags=2001000849<UP,LOOPBACK,RUNNING,MULTICAST,IPv4,VIRTUAL> mtu 8232 index 1
        inet 127.0.0.1 netmask ff000000
e1000g0:3: flags=201000843<UP,BROADCAST,RUNNING,MULTICAST,IPv4,CoS> mtu 1500 index 3
        inet 72.2.115.28 netmask ffffff80 broadcast 72.2.115.127
e1000g2:1: flags=201000843<UP,BROADCAST,RUNNING,MULTICAST,IPv4,CoS> mtu 1500 index 4
        inet 10.2.115.28 netmask ffffff80 broadcast 10.2.115.127
        inet6 2001:0db8:3c4d:55:a00:20ff:fe8e:f3ad/64
net0: flags=40201000843<UP,BROADCAST,RUNNING,MULTICAST,IPv4,CoS,L3PROTECT> mtu 1500 index 2
        inet 37.153.96.148 netmask fffffe00 broadcast 37.153.97.255
        ether 90:b8:d0:16:9b:97
net1:1: flags=100001000843<UP,BROADCAST,RUNNING,MULTICAST,IPv4,PHYSRUNNING> mtu 1500 index 2
        inet 10.16.125.36 netmask fffffe00 broadcast 10.16.125.255
        ether 90:b8:d0:16:9b:97
ip.tun0: flags=2200851<UP,POINTOPOINT,RUNNING,MULTICAST,NONUD,IPv6> mtu 1480 index 3
       inet tunnel src 109.146.85.57   tunnel dst 109.146.85.212
       tunnel security settings  -->  use 'ipsecconf -ln -i ip.tun1'
       tunnel hop limit 60
       inet6 fe80::6d92:5539/10 --> fe80::6d92:55d4
ip.tun0:1: flags=2200851<UP,POINTOPOINT,RUNNING,MULTICAST,NONUD,IPv6> mtu 1480 index 3
       inet6 2::45/128 --> 2::46
lo0: flags=1000849<UP,LOOPBACK,RUNNING,MULTICAST,IPv4> mtu 8232 index 1
    inet 127.0.0.1 netmask ff000000
eri0: flags=1004843<UP,BROADCAST,RUNNING,MULTICAST,DHCP,IPv4> mtu 1500 \
index 2
    inet 172.17.128.208 netmask ffffff00 broadcast 172.17.128.255
ip6.tun0: flags=10008d1<UP,POINTOPOINT,RUNNING,NOARP,MULTICAST,IPv4> \
mtu 1460
    index 3
    inet6 tunnel src fe80::1 tunnel dst fe80::2
    tunnel security settings  -->  use 'ipsecconf -ln -i ip.tun1'
    tunnel hop limit 60 tunnel encapsulation limit 4
    inet 10.0.0.208 --> 10.0.0.210 netmask ff000000
qfe1: flags=2000841<UP,RUNNING,MULTICAST,IPv6> mtu 1500 index 3
 usesrc vni0
 inet6 fe80::203:baff:fe17:4be0/10
 ether 0:3:ba:17:4b:e0
vni0: flags=2002210041<UP,RUNNING,NOXMIT,NONUD,IPv6,VIRTUAL> mtu 0
 index 5
 srcof qfe1
 inet6 fe80::203:baff:fe17:4444/128
ENDIFCONFIG

    @solaris_netstat_rn = <<-NETSTAT_RN
Routing Table: IPv4
  Destination           Gateway           Flags  Ref     Use     Interface
-------------------- -------------------- ----- ----- ---------- ---------
default              10.13.37.1           UG        1          0 e1000g0
10.13.37.0           10.13.37.157         U         1          2 e1000g0
127.0.0.1            127.0.0.1            UH        1         35 lo0

Routing Table: IPv6
  Destination/Mask            Gateway                   Flags Ref   Use    If
--------------------------- --------------------------- ----- --- ------- -----
fe80::/10                   fe80::250:56ff:fe13:3757    U       1       0 e1000g0
::1                         ::1                         UH      1       0 lo0
NETSTAT_RN

    @solaris_route_get = <<-ROUTE_GET
   route to: default
destination: default
       mask: default
    gateway: 10.13.37.1
  interface: e1000g0 index 3
      flags: <UP,GATEWAY,DONE,STATIC>
 recvpipe  sendpipe  ssthresh    rtt,ms rttvar,ms  hopcount      mtu     expire
       0         0         0         0         0         0      1500         0
ROUTE_GET

    @solaris11_route_get = <<-ROUTE_GET
   route to: default
destination: default
       mask: default
    gateway: 10.13.37.1
  interface: net1 index 2
      flags: <UP,GATEWAY,DONE,STATIC>
 recvpipe  sendpipe  ssthresh    rtt,ms rttvar,ms  hopcount      mtu     expire
       0         0         0         0         0         0      1500         0
ROUTE_GET

    @ifconfig_lines = @solaris_ifconfig.split("\n")

    @plugin = get_plugin("solaris2/network")
    allow(@plugin).to receive(:collect_os).and_return(:solaris2)
    @plugin[:network] = Mash.new

    allow(@plugin).to receive(:shell_out).with("ifconfig -a").and_return(mock_shell_out(0, @solaris_route_get, ""))
    allow(@plugin).to receive(:shell_out).with("arp -an").and_return(mock_shell_out(0, @solaris_arp_rn, ""))
    allow(@plugin).to receive(:shell_out).with("route -v -n get default").and_return(mock_shell_out(0, @solaris_route_get, ""))
  end

  describe "gathering IP layer address info" do
    before do
      @stdout = double("Pipe, stdout, cmd=`route get default`", :read => @solaris_route_get)
      allow(@plugin).to receive(:shell_out).with("route -v -n get default").and_return(mock_shell_out(0, @solaris_route_get, ""))
      allow(@plugin).to receive(:shell_out).with("ifconfig -a").and_return(mock_shell_out(0, @solaris_ifconfig, ""))
      @plugin.run
    end

    it "completes the run" do
      expect(@plugin["network"]).not_to be_nil
    end

    it "detects the interfaces" do
      expect(@plugin["network"]["interfaces"].keys.sort).to eq(["e1000g0:3", "e1000g2:1", "eri0", "ip.tun0", "ip.tun0:1", "ip6.tun0", "lo0", "lo0:3", "net0", "net1:1", "qfe1", "vni0"])
    end

    it "detects the ip addresses of the interfaces" do
      expect(@plugin["network"]["interfaces"]["e1000g0:3"]["addresses"].keys).to include("72.2.115.28")
    end

    it "detects the encapsulation type of the interfaces" do
      expect(@plugin["network"]["interfaces"]["e1000g0:3"]["encapsulation"]).to eq("Ethernet")
    end

    it "detects the L3PROTECT network flag" do
      expect(@plugin["network"]["interfaces"]["net0"]["flags"]).to include("L3PROTECT")
    end
  end

  describe "gathering solaris 11 zone IP layer address info" do
    before do
      @stdout = double("Pipe, stdout, cmd=`route get default`", :read => @solaris11_route_get)
      allow(@plugin).to receive(:shell_out).with("route -v -n get default").and_return(mock_shell_out(0, @solaris11_route_get, ""))
      allow(@plugin).to receive(:shell_out).with("ifconfig -a").and_return(mock_shell_out(0, @solaris_ifconfig, ""))
      @plugin.run
    end

    it "finds the flags for a PHYSRUNNING interface" do
      expect(@plugin[:network][:interfaces]["net1:1"][:flags]).to eq(%w{ UP BROADCAST RUNNING MULTICAST IPv4 PHYSRUNNING })
    end

    it "finds the default interface for a solaris 11 zone" do
      expect(@plugin[:network][:default_interface]).to eq("net1")
    end
  end

  # TODO: specs for the arp -an stuff, check that it correctly adds the MAC addr to the right iface, etc.

  describe "setting the node's default IP address attribute" do
    before do
      @stdout = double("Pipe, stdout, cmd=`route get default`", :read => @solaris_route_get)
      allow(@plugin).to receive(:shell_out).with("route -v -n get default").and_return(mock_shell_out(0, @solaris_route_get, ""))
      @plugin.run
    end

    it "finds the default interface by asking which iface has the default route" do
      expect(@plugin[:network][:default_interface]).to eq("e1000g0")
    end
  end
end
