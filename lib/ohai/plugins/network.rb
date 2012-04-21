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

# ipaddress and macaddress can be set from the #{os}::network plugin
return unless ipaddress.nil?

def find_ip_and_iface(family = "inet", match = nil)
  raise "bad family #{family}" unless [ "inet", "inet6" ].include? family

  # going to use that later to sort by scope
  scope_prio = [ "global", "site", "link", "host", "node", nil ]

  ipaddresses = []
  # trying to write it as readable as possible (iow it's not a kick-ass optimised one-liner)
  # ipaddresses going to hold #{family} ipaddresses and their scope
  Mash[network['interfaces']].each do |iface, iface_v|
    iface_v['addresses'].each do |addr, addr_v|
      next if addr_v.nil? or not addr_v.has_key? "family" or addr_v['family'] != family
      ipaddresses <<  {
        :ipaddress => IPAddress("#{addr}/#{addr_v["netmask"]}"),
        :scope => addr_v["scope"],
        :iface => iface
      }
    end
  end

  # return if there isn't any #{family} address !
  return [ nil, nil ] if ipaddresses.empty?

  if match.nil?
    # sort ip addresses by scope, by prefixlen and then by ip address
    # then return the first ip address
    r = ipaddresses.sort_by do |v|
      [ ( scope_prio.index(v[:scope].downcase) or 999999 ),
        v[:ipaddress].prefix,
        ( family == "inet" ? v[:ipaddress].to_u32 : v[:ipaddress].to_u128 )
      ]
    end.first
  else
    # sort by prefixlen
    # return the first matching ip address
    r = ipaddresses.sort do |a,b|
      a[:ipaddress].prefix <=> b[:ipaddress].prefix
    end
    r = r.select do |v|
      v[:ipaddress].include? IPAddress(match)
    end.first
  end
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

# If we have a default interface that has addresses, populate the short-cut attributes
# 0.0.0.0 is not a valid gateway address in this case
iface=nil
if network[:default_interface] and
    network[:default_gateway] and
    network[:default_gateway] != "0.0.0.0" and
    network["interfaces"][network[:default_interface]] and
    network["interfaces"][network[:default_interface]]["addresses"]
  Ohai::Log.debug("Using default interface '#{network[:default_interface]}' and default gateway '#{network[:default_gateway]}' to set the default ip")
  ( ip, iface ) = find_ip_and_iface("inet", network[:default_gateway])
  raise "error: looking for the default ip on '#{network[:default_interface]}' gives an ip '#{ip}' on '#{iface}'" if network[:default_interface] != iface
  ipaddress ip
else
  ( ip, iface ) = find_ip_and_iface("inet")
  ipaddress ip
end
macaddress find_mac_from_iface(iface) unless iface.nil?
( ip6, iface6 ) = find_ip_and_iface("inet6")
ip6address ip6
Ohai::Log.warn("ipaddress and ip6address are set from different interfaces (#{iface} & #{iface6}), macaddress has been set using the ipaddress interface") if iface and iface6 and iface != iface6
