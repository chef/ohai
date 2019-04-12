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

  # Returns interface code for an interface
  #
  # Interface Index (if present, Index otherwise) will be converted in hexadecimal format
  #
  # @param int_idx [String or nil] the interface index of interface
  # @param idx [String] the index of interface
  #
  # @return [String]
  #
  # @example Interface Code when interface index is present
  #   plugin.interface_code("1", "1") #=> "ox1"
  # @example Interface Code when interface index is not present
  #   plugin.interface_code(nil, "2") #=> "ox2"
  #
  def interface_code(int_idx, idx)
    sprintf("0x%x", (int_idx || idx)).downcase
  end

  # Returns IPV4 address from list of addresses containing IPV4 and IPV6 formats
  #
  # @param addresses [Array<String>] List of addresses
  #
  # @return [String]
  #
  # @example When list contains both IPV4 and IPV6 formats
  #   plugin.prefer_ipv4([IPV4, IPV6]) #=> "IPV4"
  # @example When list contains only IPV6 format
  #   plugin.prefer_ipv4([IPV6]) #=> "IPV6"
  #
  def prefer_ipv4(addresses)
    return nil unless addresses.is_a?(Array)
    addresses.find { |ip| IPAddress.valid_ipv4?(ip) } ||
      addresses.find { |ip| IPAddress.valid_ipv6?(ip) }
  end

  # Selects default interface and returns its information
  #
  # @note Interface with least metric value should be prefered as default_route
  #
  # @param configuration [Mash] Configuration of interfaces as iface_config
  #   [<interface_index> => {<interface_configurations>}]
  #
  # @return [Hash<:index, :interface_index, :default_ip_gateway, :ip_connection_metric>]
  #
  def favored_default_route_windows(configuration)
    return nil unless configuration.is_a?(Hash)
    config = configuration.dup

    config.inject([]) do |arr, (k, v)|
      if v["default_ip_gateway"]
        arr << { index: v["index"],
                 interface_index: v["interface_index"],
                 default_ip_gateway: prefer_ipv4(v["default_ip_gateway"]),
                 ip_connection_metric: v["ip_connection_metric"] } unless v["ip_connection_metric"].nil?
      end
      arr
    end.min_by { |r| r[:ip_connection_metric] }
  end

  collect_data(:windows) do
    iface = Mash.new
    iface_config = Mash.new
    iface_instance = Mash.new
    network Mash.new unless network
    network[:interfaces] = Mash.new unless network[:interfaces]
    counters Mash.new unless counters
    counters[:network] = Mash.new unless counters[:network]

    # @see https://docs.microsoft.com/en-us/windows/desktop/cimwin32prov/win32-networkadapterconfiguration
    adptr_config_cmd = 'Get-WmiObject Win32_NetworkAdapterConfiguration | ForEach-Object { $adptr = $_ ; $adptr.Properties | ForEach-Object { Write-Host "$($adptr.Index),$($adptr.InterfaceIndex),$($_.Name),$($_.Type),$($_.IsArray),$($_.Value)" } }'
    adapter_config_properties = shell_out(adptr_config_cmd).stdout.strip

    adapter_config_properties.lines.each do |line|
      index, interface_index, property_name, property_type, is_array, property_value = line.strip.split(',',6)
      true_index = index || interface_index
      iface_config[true_index] ||= Mash.new
      is_array = (is_array == 'True' ? true : false)

      if is_array
        property_value = property_value.to_s.split(" ").map do |subvalue|
          if property_type == 'Boolean'
            subvalue == 'True' ? true : false
          elsif property_type =~ /UInt(?:64|32|16|8)/
            subvalue.to_i
          else
            subvalue
          end
        end
      else
        property_value = true if property_type == 'Boolean' && property_value == 'True'
        property_value = false if property_type == 'Boolean' && property_value == 'False'
        if property_type =~ /UInt(?:64|32|16|8)/
          if property_value.to_s != ''
            property_value = property_value.to_i
          else
            property_value = nil
          end
        end
        property_value = nil if property_type == 'String' && property_value.to_s == ''
      end

      iface_config[true_index][property_name.wmi_underscore.to_sym] ||= property_value
    end
  
    # @see https://docs.microsoft.com/en-us/windows/desktop/cimwin32prov/win32-networkadapter
    adpter_cmd = 'Get-WmiObject Win32_NetworkAdapter | ForEach-Object { $adptr = $_ ; $adptr.Properties | ForEach-Object { Write-Host "$($adptr.Index),$($adptr.InterfaceIndex),$($adptr.Name),$($_.Name),$($_.Type),$($_.IsArray),$($_.Value)" } }'
    adapter_properties = shell_out(adpter_cmd).stdout.strip

    adapter_properties.lines.each do |line|
      index, interface_index, adapter_name, property_name, property_type, is_array, property_value = line.strip.split(',',7)
      is_array = (is_array == 'True' ? true : false)

      true_index = index || interface_index
      iface_instance[true_index] ||= Mash.new

      if is_array
        property_value = property_value.to_s.split(" ").map do |subvalue|
          if property_type == 'Boolean'
            subvalue == 'True' ? true : false
          elsif property_type =~ /UInt(?:64|32|16|8)/
            subvalue.to_i
          else
            subvalue
          end
        end
      else
        property_value = true if property_type == 'Boolean' && property_value == 'True'
        property_value = false if property_type == 'Boolean' && property_value == 'False'
        if property_type =~ /UInt(?:64|32|16|8)/
          if property_value.to_s != ''
            property_value = property_value.to_i
          else
            property_value = nil
          end
        end
        property_value = nil if property_type == 'String' && property_value.to_s == ''
      end
  
      # TODO: check to see if this is even necessary
      next if %w{creation_class_name system_creation_class_name}.include?(property_name.wmi_underscore)
      iface_instance[true_index][property_name.wmi_underscore.to_sym] = property_value
    end

    iface_instance.each_key do |i|
      if iface_instance[i][:name] && iface_config[i] && iface_config[i][:ip_address][0]
        cint = interface_code(iface_instance[i][:interface_index], iface_instance[i][:index])
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
          iface[cint][:addresses][ip] = Mash.new(prefixlen: ip2.prefix)
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
        iface[cint][:mtu] = iface[cint][:configuration][:mtu] if iface[cint][:configuration].key?(:mtu)
        iface[cint][:type] = iface[cint][:instance][:adapter_type] if iface[cint][:instance][:adapter_type]
        iface[cint][:arp] = {}
        iface[cint][:encapsulation] = windows_encaps_lookup(iface[cint][:instance][:adapter_type]) if iface[cint][:instance][:adapter_type]
      end
    end

    if (route = favored_default_route_windows(iface_config))
      network[:default_gateway] = route[:default_ip_gateway]
      network[:default_interface] = interface_code(route[:interface_index], route[:index])
    end

    cint = nil
    so = shell_out("arp -a")
    if so.exit_status == 0
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
