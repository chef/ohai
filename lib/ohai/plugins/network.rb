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

ipaddress nil
ip6address
macaddress nil

require_plugin "hostname"
require_plugin "#{os}::network"

# ipaddress and macaddress can be set from the #{os}::network plugin
return unless ipaddress.nil?

def find_ip_and_mac(addresses, match = nil)
  ip = nil; mac = nil; ip6 = nil
  addresses.keys.each do |addr|
    if match.nil?
      ip = addr if addresses[addr]["family"].eql?("inet")
    else
      ip = addr if addresses[addr]["family"].eql?("inet") && network_contains_address(match, addr, addresses[addr])
    end
    ip6 = addr if addresses[addr]["family"].eql?("inet6") && addresses[addr]["scope"].eql?("Global")
    mac = addr if addresses[addr]["family"].eql?("lladdr")
    break if (ip and mac)
  end
  Ohai::Log.debug("Found IPv4 address #{ip} with MAC #{mac} #{match.nil? ? '' : 'matching address ' + match}")
  Ohai::Log.debug("Found IPv6 address #{ip6}") if ip6
  [ip, mac, ip6]
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
if network[:default_interface] and
    network[:default_gateway] and
    network[:default_gateway] != "0.0.0.0" and
    network["interfaces"][network[:default_interface]] and
    network["interfaces"][network[:default_interface]]["addresses"]
  Ohai::Log.debug("Using default interface for default ip and mac address")
  im = find_ip_and_mac(network["interfaces"][network[:default_interface]]["addresses"], network[:default_gateway])
  ipaddress im.shift
  macaddress im.shift
  ip6address im.shift
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
