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

provides "network", "counters/network"

network Mash.new unless network
network[:interfaces] = Mash.new unless network[:interfaces]
counters Mash.new unless counters
counters[:network] = Mash.new unless counters[:network]

require_plugin "hostname"
require_plugin "#{os}::network"

def find_ip_and_mac(addresses)
  ip = nil; mac = nil
  addresses.keys.each do |addr|
    ip = addr if addresses[addr]["family"].eql?("inet")
    mac = addr if addresses[addr]["family"].eql?("lladdr")
    break if (ip and mac)
  end
  [ip, mac]
end

# If we have a default interface that has addresses, populate the short-cut attributes
if network[:default_interface] and
    network["interfaces"][network[:default_interface]] and
    network["interfaces"][network[:default_interface]]["addresses"]
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
