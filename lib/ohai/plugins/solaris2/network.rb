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

network["interfaces"] = Array.new

iface = Mash.new
popen4("ifconfig -a") do |pid, stdin, stdout, stderr|
  stdin.close
  cint = nil
  stdout.each do |line|
    if line =~ /^([[:alnum:]|\:|\-]+) \S+ mtu (\d+) index (\d+)/
      cint = $1.chop
      network["interfaces"].push(cint)
      iface[cint] = Mash.new
      iface[cint]["mtu"] = $2
      iface[cint]["index"] = $3
      if line =~ /flags\=\d+\<((ADDRCONF|ANYCAST|BROADCAST|CoS|DEPRECATED|DHCP|DUPLICATE|FAILED|FIXEDMTU|INACTIVE|LOOPBACK|MIP|MULTI_BCAST|MULTICAST|NOARP|NOFAILOVER|NOLOCAL|NONUD|NORTEXCH|NOXMIT|OFFLINE|POINTOPOINT|PREFERRED|PRIVATE|ROUTER|RUNNING|STANDBY|TEMPORARY|UNNUMBERED|UP|VIRTUAL|XRESOLV|IPv4|IPv6,)+)\>\s/
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
    if line =~ /^\s+ether (.+?)\s/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "lladdr", "address" => $1 }
      iface[cint]["encapsulation"] = "Ethernet"
    end
    if line =~ /^\s+lladdr (.+?)\s/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "lladdr", "address" => $1 }
    end
    if line =~ /\s+inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) netmask 0x(([0-9]|[a-f]){1,8})(\s|(broadcast (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})))/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "inet", "address" => $1, "netmask" => $2.scanf('%2x'*4)*"."}
      iface[cint]["addresses"].last["broadcast"] = $4 if $4.length > 1
    end
    if line =~ /\s+inet6 ([a-f0-9\:]+)(\s*|(\%[a-z0-9]+)\s*) prefixlen (\d+)\s*$/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "inet6", "address" => $1, "prefixlen" => $4 , "scope" => "Node" }
    end
    if line =~ /\s+inet6 ([a-f0-9\:]+)(\s*|(\%[a-z0-9]+)\s*) prefixlen (\d+)\s*scopeid 0x([a-f0-9]+)/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "inet6", "address" => $1, "prefixlen" => $4 , "scope" => scope_lookup($1) }
    end
    if line =~ /^\s+media: ((\w+)|(\w+ [a-zA-Z0-9\-\<\>]+)) status: (\w+)/
      iface[cint]["media"] = Hash.new unless iface[cint]["media"]
      iface[cint]["media"]["selected"] = parse_media($1)
      iface[cint]["status"] = $4
    end
    if line =~ /^\s+supported media: (.*)/
      iface[cint]["media"] = Hash.new unless iface[cint]["media"]
      iface[cint]["media"]["supported"] = parse_media($1)
    end
  end
end

network["interfaces"] = iface
