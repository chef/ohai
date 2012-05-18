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

def find_ip_and_iface(family = "inet", match = nil)
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
        :scope => addr_v["scope"],
        :iface => iface
      }
    end
  end

  # return if there isn't any #{family} address !
  return [ nil, nil ] if ipaddresses.empty?

  # sort ip addresses by scope, by prefixlen and then by ip address
  # 128 - prefixlen: longest prefixes first
  r = ipaddresses.sort_by do |v|
    [ ( scope_prio.index(v[:scope].downcase) or 999999 ),
      128 - v[:ipaddress].prefix.to_i,
      ( family == "inet" ? v[:ipaddress].to_u32 : v[:ipaddress].to_u128 )
    ]
  end
  if match.nil? or match ~ /^0\.0\.0\.0/ or match ~ /^::$/
    # return the first ip address
    r = r.first
  else
    # use the match argument to select the address
    r = r.select do |v|
      v[:ipaddress].include? IPAddress(match)
    end.first
  end
  returni [ nil, nil ] if r.nil?
  [ r[:ipaddress].to_s, r[:iface] ]
end

def find_mac_from_iface(iface)
  network["interfaces"][iface]["addresses"].select{|k,v| v["family"]=="lladdr"}.first.first
end

def network_contains_address(address_to_match, network_ip, network_opts)
  if network_opts[:peer]
    network_opts[:peer] == address_to_match
  else
    network = IPAddress "#{network_ip}/#{network_opts[:netmask]}"
    host = IPAddress address_to_match
    network.include?(host)
  end
end

# ipaddress, ip6address and macaddress can be set by the #{os}::network plugin
# atm it is expected macaddress is set at the same time than ipaddress
# if ipaddress is set and macaddress is nil, that means the interface
# ipaddress is bound to has the NOARP flag


results = {}

[
 { :name => "inet",
   :prefix => "default" },
 { :name => "inet6",
   :prefix => "default_inet6" }
].each do |f|
  r = {}
  # If we have a default interface that has addresses,
  # populate the short-cut attributes
  # 0.0.0.0 is not a valid gateway address in this case
  if network["#{f[:prefix]}_interface"] and
      network["#{f[:prefix]}_gateway"] and
      network["interfaces"][network["#{f[:prefix]}_interface"]] and
      network["interfaces"][network["#{f[:prefix]}_interface"]]["addresses"]
    Ohai::Log.debug("Using default #{f[:name]} interface '#{network["#{f[:prefix]}_interface"]}' and default #{f[:name]} gateway '#{network["#{f[:prefix]}_gateway"]}' to set the default #{f[:name]} ip")
    ( r["ip"], r["iface"] ) = find_ip_and_iface(f[:name], network["#{f[:prefix]}_gateway"])
  else
    ( r["ip"], r["iface"] ) = find_ip_and_iface(f[:name])
  end
  Ohai::Log.warn("conflict when looking for the default #{f[:name]} ip: network[:#{f[:prefix]}_interface] is set to '#{network["#{f[:prefix]}_interface"]}' ipaddress '#{r["ip"]}' is set on '#{r["iface"]}'") if network["#{f[:prefix]}_interface"] and network["#{f[:prefix]}_interface"] != r["iface"]
  r["mac"] = find_mac_from_iface(r["iface"]) unless r["iface"].nil?
  unless r["ip"].nil?
    # don't overwrite attributes if they've already been set by the "#{os}::network" plugin
    if f[:name] == "inet" and ipaddress.nil?
      ipaddress r["ip"]
      # macaddress is always set from the ipv4 default_route
      macaddress r["mac"]
    elsif f[:name] == "inet6" and ip6address.nil?
      ip6address r["ip"]
    end
    #macaddress r["mac"] unless macaddress # macaddress set from ipv4 otherwise from ipv6

  end
  results[f[:name]] = r
end

if results["inet"]["iface"] and results["inet6"]["iface"] and
    results["inet"]["iface"] != results["inet6"]["iface"]
  Ohai::Log.info("ipaddress and ip6address are set from different interfaces (#{results["inet"]["iface"]} & #{results["inet6"]["iface"]}), macaddress has been set using the ipaddress interface")
end
