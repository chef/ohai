#
# Author:: Adam Jacob (<adam@opscode.com>)
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

require 'ipaddress'

provides "network", "counters/network"

network Mash.new unless network
network[:interfaces] = Mash.new unless network[:interfaces]
counters Mash.new unless counters
counters[:network] = Mash.new unless counters[:network]

require_plugin "hostname"
require_plugin "#{os}::network"

FAMILIES = {
  "inet" => "default",
  "inet6" => "default_inet6"
}

def sorted_ips(family = "inet")
  raise "bad family #{family}" unless [ "inet", "inet6" ].include? family

  # going to use that later to sort by scope
  scope_prio = [ "global", "site", "link", "host", "node", nil ]

  ipaddresses = []
  # ipaddresses going to hold #{family} ipaddresses and their scope
  Mash[network['interfaces']].each do |iface, iface_v|
    iface_v['addresses'].each do |addr, addr_v|
      next if addr_v.nil? or not addr_v.has_key? "family" or addr_v['family'] != family
      ipaddresses <<  {
        :ipaddress => addr_v["prefixlen"] ? IPAddress("#{addr}/#{addr_v["prefixlen"]}") : IPAddress("#{addr}/#{addr_v["netmask"]}"),
        :scope => addr_v["scope"].nil? ? nil : addr_v["scope"].downcase,
        :iface => iface
      }
    end
  end

  # sort ip addresses by scope, by prefixlen and then by ip address
  # 128 - prefixlen: longest prefixes first
  ipaddresses.sort_by do |v|
    [ ( scope_prio.index(v[:scope]) or 999999 ),
      128 - v[:ipaddress].prefix.to_i,
      ( family == "inet" ? v[:ipaddress].to_u32 : v[:ipaddress].to_u128 )
    ]
  end
end

def find_ip(family = "inet")
  ips=sorted_ips(family)

  # return if there isn't any #{family} address !
  return [ nil, nil ] if ips.empty?

  # shortcuts to access default #{family} interface and gateway
  int_attr = FAMILIES[family] +"_interface"
  gw_attr = FAMILIES[family] + "_gateway"

  # If we have a default interface that has addresses,
  # populate the short-cut attributes ipaddress, ip6address and macaddress
  if network[int_attr]

    # working with the address(es) of the default network interface
    gw_if_ips = ips.select do |v|
      v[:iface] == network[int_attr]
    end
    if gw_if_ips.empty?
      Ohai::Log.warn("[#{family}] no ip address on #{network[int_attr]}")
    elsif network[gw_attr] and
        network["interfaces"][network[int_attr]] and
        network["interfaces"][network[int_attr]]["addresses"]
      if [ "0.0.0.0", "::" ].include? network[gw_attr]
        # link level default route
        Ohai::Log.debug("link level default #{family} route, picking ip from #{network[gw_attr]}")
        r = gw_if_ips.first
      else
        # checking network masks
        r = gw_if_ips.select do |v|
          network_contains_address(network[gw_attr], v[:ipaddress], v[:iface])
        end.first
        if r.nil?
          r = gw_if_ips.first
          Ohai::Log.warn("[#{family}] no ipaddress/mask on #{network[int_attr]} matching the gateway #{network[gw_attr]}, picking one anyway")
        else
          Ohai::Log.debug("[#{family}] Using default interface #{network[int_attr]} and default gateway #{network[gw_attr]} to set the default ip to #{r[:ipaddress]}")
        end
      end
    else
      # return the first ip address on network[int_attr]
      r = gw_if_ips.first
    end
  else
    r = ips.first
    Ohai::Log.debug("[#{family}] no default interface, picking the first ipaddress")
  end

  return [ nil, nil ] if r.nil? or r.empty?

  [ r[:ipaddress].to_s, r[:iface] ]
end

def find_mac_from_iface(iface)
  r = network["interfaces"][iface]["addresses"].select{|k,v| v["family"]=="lladdr"}
  r.nil? or r.first.nil? ? nil : r.first.first
end

def network_contains_address(address_to_match, ipaddress, iface)
  # address_to_match: String
  # ipaddress: IPAddress
  # iface: String
  if peer = network["interfaces"][iface]["addresses"][ipaddress.to_s][:peer]
    IPAddress(peer) == IPAddress(address_to_match)
  else
    ipaddress.include? IPAddress(address_to_match)
  end
end

# ipaddress, ip6address and macaddress can be set by the #{os}::network plugin
# atm it is expected macaddress is set at the same time than ipaddress
# if ipaddress is set and macaddress is nil, that means the interface
# ipaddress is bound to has the NOARP flag


results = {}

# inet family is treated before inet6
FAMILIES.keys.sort.each do |family|
  r = {}
  ( r["ip"], r["iface"] ) = find_ip(family)
  r["mac"] = find_mac_from_iface(r["iface"]) unless r["iface"].nil?
  # don't overwrite attributes if they've already been set by the "#{os}::network" plugin
  if family == "inet" and ipaddress.nil?
    if r["ip"].nil?
      Ohai::Log.warn("unable to detect ipaddress")
      # i don't issue this warning if r["ip"] exists and r["mac"].nil?
      # as it could be a valid setup with a NOARP default_interface
      Ohai::Log.warn("unable to detect macaddress")
    else
      ipaddress r["ip"]
      macaddress r["mac"]
    end
  elsif family == "inet6" and ip6address.nil?
    if r["ip"].nil?
      Ohai::Log.warn("unable to detect ip6address")
    else
      ip6address r["ip"]
      if r["mac"] and macaddress.nil? and ipaddress.nil?
        Ohai::Log.debug("macaddress set to #{r["mac"]} from the ipv6 setup")
        macaddress r["mac"]
      end
    end
  end
  results[family] = r
end

if results["inet"]["iface"] and results["inet6"]["iface"] and
    results["inet"]["iface"] != results["inet6"]["iface"]
  Ohai::Log.debug("ipaddress and ip6address are set from different interfaces (#{results["inet"]["iface"]} & #{results["inet6"]["iface"]}), macaddress has been set using the ipaddress interface")
end
