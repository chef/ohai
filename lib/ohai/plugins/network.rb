#
# Author:: Toomas Pelberg (<toomas.pelberg@playtech.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

provides "network", "counters/network"
Ohai::Log.debug("Loaded network plugin")
network Mash.new unless network
network[:interfaces] = Mash.new unless network.has_key?(:interfaces)
counters Mash.new unless counters
counters[:network] = Mash.new unless counters.has_key?(:network)

require_plugin "hostname"
require 'sigar'
sigar = Sigar.new


# http://svn.hyperic.org/projects/sigar/trunk/bindings/java/src/org/hyperic/sigar/NetFlags.java
def _decode_sigar_interface_flags(flag)
  flags=[]
  net_flags = {
  1=>"UP",
  2=>"BROADCAST",
  4=>"DEBUG",
  8=>"LOOPBACK",
  16=>"POINTTOPOINT",
  32=>"NOTRAILERS",
  64=>"RUNNING",
  128=>"NOARP",
  256=>"PROMISCUOUS",
  512=>"ALLMULTI",
  2048=>"MULTICAST",
  4096=>"SLAVE",
  8192=>"MASTER",
  16384=>"DYNAMIC"}
  net_flags.each_pair do |k,v|
    flags.push(v) if ((flag & k) > 0)
  end
  flags
end

%w(default_gateway primary_dns secondary_dns).each do |i|
network[i.to_sym]=sigar.net_info.send(i)
end
network[:default_interface]=sigar.net_info.default_gateway_interface

# Tries to resemble the old linux/network.rb structure as closely as possible
sigar.net_interface_list.each do |interface|
  network[:interfaces][interface]=Mash.new
  tmp_addr=nil
  interface_config=sigar.net_interface_config(interface)
  if interface =~ /^(\w+)(\d+.*)/
    network[:interfaces][interface][:type]=$1
    network[:interfaces][interface][:number]=$2
  end
  network[:interfaces][interface][:flags]=_decode_sigar_interface_flags(interface_config.flags)
  if network[:interfaces][interface][:flags].member?("POINTTOPOINT")
    network[:interfaces][interface][:peer]=interface_config.destination
  end
  network[:interfaces][interface][:mtu]=interface_config.mtu
  network[:interfaces][interface][:encapsulation]=interface_config.type
  network[:interfaces][interface][:addresses] = Mash.new unless network[:interfaces][interface][:addresses]
  if(interface_config.hwaddr)
    network[:interfaces][interface][:addresses][interface_config.hwaddr]={"family" => "lladdr"}
  end
  if(interface_config.address)
    network[:interfaces][interface][:addresses][interface_config.address]={
      "family" => "inet",
      "broadcast" => interface_config.broadcast,
      "netmask" => interface_config.netmask,
    }
  end
  if(interface_config.address6)
    network[:interfaces][interface][:addresses][interface_config.address6]={
      "family" => "inet6",
      "prefixlen" => interface_config.prefix6_length,
      "scope" => interface_config.scope6,
    }
  end
  interface_stats=sigar.net_interface_stat(interface)
  next unless interface_stats
  counters[:network][:interfaces] = Mash.new unless counters[:network].has_key?(:interfaces)
  counters[:network][:interfaces][interface]=Mash.new unless counters[:network][:interfaces][interface]
  counters[:network][:interfaces][interface][:rx]={
    "packets" => interface_stats.rx_bytes,
    "errors" => interface_stats.rx_errors,
    "drop" => interface_stats.rx_dropped,
    "overrun" => interface_stats.rx_overruns,
    "frame" => interface_stats.rx_frame,
    "bytes" => interface_stats.rx_bytes
  }
  counters[:network][:interfaces][interface][:tx]={
    "packets" => interface_stats.tx_bytes,
    "errors" => interface_stats.tx_errors,
    "drop" => interface_stats.tx_dropped,
    "overrun" => interface_stats.tx_overruns,
    "carrier" => interface_stats.tx_carrier,
    "collisions" => interface_stats.tx_collisions,
    "queuelen" => interface_config.tx_queue_len,
    "bytes" => interface_stats.tx_bytes,
  }
end

def find_ip_and_mac(addresses)
  ip = nil; mac = nil
  addresses.keys.each do |addr|
    ip = addr if addresses[addr]["family"].eql?("inet")
    mac = addr if addresses[addr]["family"].eql?("lladdr")
    break if (ip and mac)
  end
  [ip, mac]
end

if network[:default_interface]
  Ohai::Log.debug("Using default interface for default ip and mac address")
  im = find_ip_and_mac(network["interfaces"][network[:default_interface]]["addresses"])
  ipaddress im.shift
  macaddress im.shift
else
  network["interfaces"].keys.sort.each do |iface|
    if network["interfaces"][iface]["encapsulation"].eql?("Ethernet")
      Ohai::Log.debug("Picking ip and mac address from first Ethernet interface")
      im = find_ip_and_mac(network["interfaces"][iface]["addresses"])
      ipaddress im.shift
      macaddress im.shift
      return if (ipaddress and macaddress)
   end
  end
end
