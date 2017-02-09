#
# Author:: James Gartrell (<jgartrel@gmail.com>)
# Copyright:: Copyright (c) 2008-2017, Chef Software Inc.
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

Ohai.plugin(:Network) do
  provides "network", "network/interfaces"
  provides "counters/network", "counters/network/interfaces"

  def windows_encaps_lookup(encap)
    return "Ethernet" if encap.eql?("Ethernet 802.3")
    encap
  end

  def mac_addresses(iface)
    prop = iface[:configuration][:mac_address] || iface[:instance][:network_addresses]
    [prop].flatten.map { |addr| addr.include?(":") ? addr : addr.scan(/.{1,2}/).join(":") }
  end

  def network_data
    @network_data ||= begin
      data = {}
      wmi = WmiLite::Wmi.new
      data[:addresses] = wmi.instances_of("Win32_NetworkAdapterConfiguration")

      # If we are running on windows nano or anothe roperating system from the future
      # that does not populate the deprecated win32_* WMI classes, then we should
      # grab data from the newer MSFT_* classes
      return msft_adapter_data if data[:addresses].count == 0
      data[:adapters] = wmi.instances_of("Win32_NetworkAdapter")
      data
    end
  end

  def msft_adapter_data
    data = {}
    wmi = WmiLite::Wmi.new("ROOT/StandardCimv2")
    data[:addresses] = wmi.instances_of("MSFT_NetIPAddress")
    data[:adapters] = wmi.instances_of("MSFT_NetAdapter")
    data
  end

  collect_data(:windows) do

    require "wmi-lite/wmi"

    iface = Mash.new
    iface_config = Mash.new
    iface_instance = Mash.new
    network Mash.new unless network
    network[:interfaces] = Mash.new unless network[:interfaces]
    counters Mash.new unless counters
    counters[:network] = Mash.new unless counters[:network]

    network_data[:addresses].each do |adapter|
      i = adapter["index"] || adapter["InterfaceIndex"]
      iface_config[i] = Mash.new unless iface_config[i]
      iface_config[i][:ip_address] ||= []
      iface_config[i][:ip_address] << adapter["IPAddress"]
      adapter.wmi_ole_object.properties_.each do |p|
        if iface_config[i][p.name.wmi_underscore.to_sym].nil?
          iface_config[i][p.name.wmi_underscore.to_sym] = adapter[p.name.downcase]
        end
      end
    end

    network_data[:adapters].each do |adapter|
      i = adapter["index"] || adapter["InterfaceIndex"]
      iface_instance[i] = Mash.new
      adapter.wmi_ole_object.properties_.each do |p|
        iface_instance[i][p.name.wmi_underscore.to_sym] = adapter[p.name.downcase]
      end
    end

    iface_instance.keys.each do |i|
      if iface_instance[i][:name] && iface_config[i] && iface_config[i][:ip_address][0]
        cint = sprintf("0x%x", (iface_instance[i][:interface_index] || iface_instance[i][:index]) ).downcase
        iface[cint] = Mash.new
        iface[cint][:configuration] = iface_config[i]
        iface[cint][:instance] = iface_instance[i]

        iface[cint][:counters] = Mash.new
        iface[cint][:addresses] = Mash.new
        iface[cint][:configuration][:ip_address] = iface[cint][:configuration][:ip_address].flatten
        iface[cint][:configuration][:ip_address].each_index do |ip_index|
          ip = iface[cint][:configuration][:ip_address][ip_index]
          ip_and_subnet = ip.dup
          ip_and_subnet << "/#{iface[cint][:configuration][:ip_subnet][ip_index]}" if iface[cint][:configuration][:ip_subnet]
          ip2 = IPAddress(ip_and_subnet)
          iface[cint][:addresses][ip] = Mash.new(:prefixlen => ip2.prefix)
          if ip2.ipv6?
            iface[cint][:addresses][ip][:family] = "inet6"
            iface[cint][:addresses][ip][:scope] = "Link" if ip =~ /^fe80/i
          else
            if iface[cint][:configuration][:ip_subnet]
              iface[cint][:addresses][ip][:netmask] = ip2.netmask.to_s
              if iface[cint][:configuration][:ip_use_zero_broadcast]
                iface[cint][:addresses][ip][:broadcast] = ip2.network.to_s
              else
                iface[cint][:addresses][ip][:broadcast] = ip2.broadcast.to_s
              end
            end
            iface[cint][:addresses][ip][:family] = "inet"
          end
        end
        mac_addresses(iface[cint]).each do |mac_addr|
          iface[cint][:addresses][mac_addr] = {
            "family" => "lladdr",
          }
        end
        iface[cint][:mtu] = iface[cint][:configuration][:mtu] if iface[cint][:configuration].has_key?(:mtu)
        iface[cint][:type] = iface[cint][:instance][:adapter_type] if iface[cint][:instance][:adapter_type]
        iface[cint][:arp] = {}
        iface[cint][:encapsulation] = windows_encaps_lookup(iface[cint][:instance][:adapter_type]) if iface[cint][:instance][:adapter_type]
        if !iface[cint][:configuration][:default_ip_gateway].nil? && iface[cint][:configuration][:default_ip_gateway].size > 0
          network[:default_gateway] = iface[cint][:configuration][:default_ip_gateway].first
          network[:default_interface] = cint
        end
      end
    end

    cint = nil
    so = shell_out("arp -a")
    if so.exitstatus == 0
      so.stdout.lines do |line|
        if line =~ /^Interface:\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+[-]+\s+(0x\S+)/
          cint = $2.downcase
        end
        next unless iface[cint]
        if line =~ /^\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+([a-fA-F0-9\:-]+)/
          iface[cint][:arp][$1] = $2.tr("-", ":").downcase
        end
      end
    end

    network["interfaces"] = iface
  end
end
