#
# Author:: James Gartrell (<jgartrel@gmail.com>)
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

provides "network"

require 'ruby-wmi'

def encaps_lookup(encap)
  return "Ethernet" if encap.eql?("Ethernet 802.3")
  encap
end

iface = Mash.new
iface_config = Mash.new
iface_instance = Mash.new

# http://msdn.microsoft.com/en-us/library/windows/desktop/aa394217%28v=vs.85%29.aspx
adapters = WMI::Win32_NetworkAdapterConfiguration.find(:all)
adapters.each do |adapter|
    i = adapter.Index
    iface_config[i] = Mash.new
    adapter.properties_.each do |p|
      iface_config[i][p.name.wmi_underscore.to_sym] = adapter.invoke(p.name)
    end
end

# http://msdn.microsoft.com/en-us/library/windows/desktop/aa394216(v=vs.85).aspx
adapters = WMI::Win32_NetworkAdapter.find(:all)
adapters.each do |adapter|
    i = adapter.Index
    iface_instance[i] = Mash.new
     adapter.properties_.each do |p|
      iface_instance[i][p.name.wmi_underscore.to_sym] = adapter.invoke(p.name)
    end
end

iface_instance.keys.each do |i|
  if iface_config[i][:ip_enabled] and iface_instance[i][:net_connection_id]
    cint = sprintf("0x%x", iface_instance[i][:interface_index] ? iface_instance[i][:interface_index] : iface_instance[i][:index] ).downcase
    iface[cint] = Mash.new
    iface[cint][:configuration] = iface_config[i]
    iface[cint][:instance] = iface_instance[i]

    iface[cint][:counters] = Mash.new
    iface[cint][:addresses] = Mash.new
    iface[cint][:configuration][:ip_address].each_index do |i|
      ip = iface[cint][:configuration][:ip_address][i]
      _ip = IPAddress("#{ip}/#{iface[cint][:configuration][:ip_subnet][i]}")
      iface[cint][:addresses][ip] = Mash.new(
        :prefixlen => _ip.prefix
      )
      if _ip.ipv6?
        # inet6 address
        iface[cint][:addresses][ip][:family] = "inet6"
        iface[cint][:addresses][ip][:scope] = "Link" if ip =~ /^fe80/i
      else
        # should be an inet4 address
        iface[cint][:addresses][ip][:netmask] =  _ip.netmask.to_s
        if iface[cint][:configuration][:ip_use_zero_broadcast]
          iface[cint][:addresses][ip][:broadcast] = _ip.network.to_s
        else
          iface[cint][:addresses][ip][:broadcast] = _ip.broadcast.to_s
        end
        iface[cint][:addresses][ip][:family] = "inet"
      end
    end
    # Apparently you can have more than one mac_address? Odd.
    [iface[cint][:configuration][:mac_address]].flatten.each do |mac_addr|
      iface[cint][:addresses][mac_addr] = {
        "family"    => "lladdr"
      }
    end
    iface[cint][:mtu] = iface[cint][:configuration][:mtu]
    iface[cint][:type] = iface[cint][:instance][:adapter_type]
    iface[cint][:arp] = {}
    iface[cint][:encapsulation] = encaps_lookup(iface[cint][:instance][:adapter_type])
    if iface[cint][:configuration][:default_ip_gateway] != nil and iface[cint][:configuration][:default_ip_gateway].size > 0
      network[:default_gateway] = iface[cint][:configuration][:default_ip_gateway].first
      network[:default_interface] = cint
    end
  end
end

cint=nil
status, stdout, stderr = run_command(:command => "arp -a")
if status == 0
  stdout.split("\n").each do |line|
    if line =~ /^Interface:\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+[-]+\s+(0x\S+)/
      cint = $2.downcase
    end
    next unless iface[cint]
    if line =~ /^\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+([a-fA-F0-9\:-]+)/
      iface[cint][:arp][$1] = $2.gsub("-",":").downcase
    end
  end
end

network["interfaces"] = iface
