#
# Author:: Benjamin Black (<nostromo@gmail.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

#lo0:3: flags=2001000849<UP,LOOPBACK,RUNNING,MULTICAST,IPv4,VIRTUAL> mtu 8232 index 1
#        inet 127.0.0.1 netmask ff000000
#e1000g0:3: flags=201000843<UP,BROADCAST,RUNNING,MULTICAST,IPv4,CoS> mtu 1500 index 3
#        inet 72.2.115.28 netmask ffffff80 broadcast 72.2.115.127
#e1000g2:1: flags=201000843<UP,BROADCAST,RUNNING,MULTICAST,IPv4,CoS> mtu 1500 index 4
#        inet 10.2.115.28 netmask ffffff80 broadcast 10.2.115.127
#        inet6 2001:0db8:3c4d:55:a00:20ff:fe8e:f3ad/64
#ip.tun0: flags=2200851<UP,POINTOPOINT,RUNNING,MULTICAST,NONUD,IPv6> mtu 1480 index 3
#       inet tunnel src 109.146.85.57   tunnel dst 109.146.85.212
#       tunnel security settings  -->  use 'ipsecconf -ln -i ip.tun1'
#       tunnel hop limit 60
#       inet6 fe80::6d92:5539/10 --> fe80::6d92:55d4
#ip.tun0:1: flags=2200851<UP,POINTOPOINT,RUNNING,MULTICAST,NONUD,IPv6> mtu 1480 index 3
#       inet6 2::45/128 --> 2::46
#lo0: flags=1000849<UP,LOOPBACK,RUNNING,MULTICAST,IPv4> mtu 8232 index 1
#    inet 127.0.0.1 netmask ff000000
#eri0: flags=1004843<UP,BROADCAST,RUNNING,MULTICAST,DHCP,IPv4> mtu 1500 \
#index 2
#    inet 172.17.128.208 netmask ffffff00 broadcast 172.17.128.255
#ip6.tun0: flags=10008d1<UP,POINTOPOINT,RUNNING,NOARP,MULTICAST,IPv4> \
#mtu 1460
#    index 3
#    inet6 tunnel src fe80::1 tunnel dst fe80::2
#    tunnel security settings  -->  use 'ipsecconf -ln -i ip.tun1'
#    tunnel hop limit 60 tunnel encapsulation limit 4
#    inet 10.0.0.208 --> 10.0.0.210 netmask ff000000
#qfe1: flags=2000841<UP,RUNNING,MULTICAST,IPv6> mtu 1500 index 3
# usesrc vni0
# inet6 fe80::203:baff:fe17:4be0/10
# ether 0:3:ba:17:4b:e0
#vni0: flags=2002210041<UP,RUNNING,NOXMIT,NONUD,IPv6,VIRTUAL> mtu 0
# index 5
# srcof qfe1
# inet6 fe80::203:baff:fe17:4444/128

require 'scanf'

def encaps_lookup(ifname)
  return "Ethernet" if ifname.eql?("e1000g")
  return "Ethernet" if ifname.eql?("eri")
  return "Loopback" if ifname.eql?("lo")
  "Unknown"
end

iface = Mash.new
popen4("ifconfig -a") do |pid, stdin, stdout, stderr|
  stdin.close
  cint = nil
  stdout.each do |line|
    if line =~ /^([0-9a-zA-Z\.\:\-]+): \S+ mtu (\d+) index (\d+)/
      cint = $1
      iface[cint] = Mash.new
      iface[cint]["mtu"] = $2
      iface[cint]["index"] = $3
      if line =~ / flags\=\d+\<((ADDRCONF|ANYCAST|BROADCAST|CoS|DEPRECATED|DHCP|DUPLICATE|FAILED|FIXEDMTU|INACTIVE|LOOPBACK|MIP|MULTI_BCAST|MULTICAST|NOARP|NOFAILOVER|NOLOCAL|NONUD|NORTEXCH|NOXMIT|OFFLINE|POINTOPOINT|PREFERRED|PRIVATE|ROUTER|RUNNING|STANDBY|TEMPORARY|UNNUMBERED|UP|VIRTUAL|XRESOLV|IPv4|IPv6|,)+)\>\s/
        flags = $1.split(',')
      else
        flags = Array.new
      end
      iface[cint]["flags"] = flags.flatten
      if cint =~ /^(\w+)(\d+.*)/
        iface[cint]["type"] = $1
        iface[cint]["number"] = $2
        iface[cint]["encapsulation"] = encaps_lookup($1)
      end
    end
    if line =~ /\s+inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) netmask (([0-9a-f]){1,8})\s*$/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "inet", "address" => $1, "netmask" => $2.scanf('%2x'*4)*"."}
    end
    if line =~ /\s+inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) netmask (([0-9a-f]){1,8}) broadcast (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "inet", "address" => $1, "netmask" => $2.scanf('%2x'*4)*".", "broadcast" => $4 }
    end
    if line =~ /\s+inet6 ([a-f0-9\:]+)(\s*|(\%[a-z0-9]+)\s*)\/(\d+)\s*$/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "inet6", "address" => $1, "prefixlen" => $4 }
    end
  end
end

#e1000g0 72.2.115.49          255.255.255.255 SPLA     00:15:17:74:52:04
#bnx0   10.0.70.70           255.255.255.255 o        00:14:4f:8d:bb:5b
#e1000g0 72.2.115.55          255.255.255.255 SPLA     00:15:17:74:52:04
#e1000g0 72.2.115.54          255.255.255.255 o        00:15:17:74:50:24
#e1000g0 72.2.115.43          255.255.255.255 SPLA     00:15:17:74:52:04
#e1000g0 72.2.115.42          255.255.255.255 SPLA     00:15:17:74:52:04
#e1000g0 72.2.115.45          255.255.255.255 SPLA     00:15:17:74:52:04
#e1000g0 72.2.115.44          255.255.255.255 SPLA     00:15:17:74:52:04
#e1000g0 72.2.115.27          255.255.255.255 SPLA     00:15:17:74:52:04
#e1000g0 72.2.115.29          255.255.255.255 SPLA     00:15:17:74:52:04
def arpname_to_ifname(arpname)
  network[:interfaces].keys.each do |ifn|
    STDERR.puts "COMPARING " + ifn + " TO " + arpname
    return ifn if ifn.split(':')[0].eql?(arpname)
  end

  nil
end

popen4("arp -an") do |pid, stdin, stdout, stderr|
  stdin.close
  stdout.each do |line|
    if line =~ /^([0-9a-zA-Z\.\:\-]+)\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\s+\w+\s+([a-zA-Z0-9\.\:\-]+)/
      # MAC addr really should be normalized to include all the zeroes.
      next unless iface[arpname_to_ifname($1)] # this should never happen
      iface[arpname_to_ifname($1)][:arp] = Mash.new unless iface[arpname_to_ifname($1)][:arp]
      iface[arpname_to_ifname($1)][:arp][$2] = $3
    end
  end
end

network[:interfaces] = iface
