#
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Copyright:: Copyright (c) 2009 Matthew Kent
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

require 'ohai/mixin/network_constants'

Ohai.plugin(:Network) do
  include Ohai::Mixin::NetworkConstants

  provides "network", "network/interfaces"
  provides "counters/network", "counters/network/interfaces"

  def sigar_encaps_lookup(encap)
    return "Loopback" if encap.eql?("Local Loopback")
    return "PPP" if encap.eql?("Point-to-Point Protocol")
    return "SLIP" if encap.eql?("Serial Line IP")
    return "VJSLIP" if encap.eql?("VJ Serial Line IP")
    return "IPIP" if encap.eql?("IPIP Tunnel")
    return "6to4" if encap.eql?("IPv6-in-IPv4")
    encap
  end

  def fetch_interfaces(sigar)
    iface = Mash.new
    net_counters = Mash.new

    sigar.net_interface_list.each do |cint|
      iface[cint] = Mash.new

      if cint =~ /^(\w+)(\d+.*)/
        iface[cint][:type] = $1
        iface[cint][:number] = $2
      end

      ifconfig = sigar.net_interface_config(cint)
      iface[cint][:encapsulation] = sigar_encaps_lookup(ifconfig.type)

      iface[cint][:addresses] = Mash.new
      # Backwards compat: loopback has no hwaddr
      if (ifconfig.flags & Sigar::IFF_LOOPBACK) == 0
        iface[cint][:addresses][ifconfig.hwaddr] = { "family" => "lladdr" }
      end
      if ifconfig.address != "0.0.0.0"
        iface[cint][:addresses][ifconfig.address] = { "family" => "inet" }
        # Backwards compat: no broadcast on tunnel or loopback dev
        if (((ifconfig.flags & Sigar::IFF_POINTOPOINT) == 0) &&
            ((ifconfig.flags & Sigar::IFF_LOOPBACK) == 0))
          iface[cint][:addresses][ifconfig.address]["broadcast"] = ifconfig.broadcast
        end
        iface[cint][:addresses][ifconfig.address]["netmask"] = ifconfig.netmask
      end

      if ifconfig.prefix6_length != 0
        iface[cint][:addresses][ifconfig.address6] = { "family" => "inet6" }
        iface[cint][:addresses][ifconfig.address6]["prefixlen"] = ifconfig.prefix6_length.to_s
        iface[cint][:addresses][ifconfig.address6]["scope"] = Sigar.net_scope_to_s(ifconfig.scope6)
      end

      iface[cint][:flags] = Sigar.net_interface_flags_to_s(ifconfig.flags).split(' ')
      iface[cint][:mtu] = ifconfig.mtu.to_s
      iface[cint][:queuelen] = ifconfig.tx_queue_len.to_s

      net_counters[cint] = Mash.new unless net_counters[cint]
      if (!cint.include?(":"))
        ifstat = sigar.net_interface_stat(cint)
        net_counters[cint][:rx] = { "packets" => ifstat.rx_packets.to_s, "errors"     => ifstat.rx_errors.to_s,
          "drop"    => ifstat.rx_dropped.to_s, "overrun"    => ifstat.rx_overruns.to_s,
          "frame"   => ifstat.rx_frame.to_s,   "bytes"      => ifstat.rx_bytes.to_s }
        net_counters[cint][:tx] = { "packets" => ifstat.tx_packets.to_s, "errors"     => ifstat.tx_errors.to_s,
          "drop"    => ifstat.tx_dropped.to_s, "overrun"    => ifstat.tx_overruns.to_s,
          "carrier" => ifstat.tx_carrier.to_s, "collisions" => ifstat.tx_collisions.to_s,
          "bytes"   => ifstat.tx_bytes.to_s }
      end
    end

    begin
      sigar.arp_list.each do |arp|
        next unless iface[arp.ifname] # this should never happen
        iface[arp.ifname][:arp] = Mash.new unless iface[arp.ifname][:arp]
        iface[arp.ifname][:arp][arp.address] = arp.hwaddr
      end
    rescue
      #64-bit AIX for example requires 64-bit caller
    end

    [iface, net_counters]
  end

  # sigar-only, from network_route plugin
  def flags(flags)
    f = ""
    if (flags & Sigar::RTF_UP) != 0
      f += "U"
    end
    if (flags & Sigar::RTF_GATEWAY) != 0
      f += "G"
    end
    if (flags & Sigar::RTF_HOST) != 0
      f += "H"
    end
    f
  end

  collect_data(:hpux) do
    require "sigar"
    sigar = Sigar.new

    network Mash.new unless network
    network[:interfaces] = Mash.new unless network[:interfaces]
    counters Mash.new unless counters
    counters[:network] = Mash.new unless counters[:network]

    ninfo = sigar.net_info
    network[:default_interface] = ninfo.default_gateway_interface
    network[:default_gateway] = ninfo.default_gateway

    iface, net_counters = fetch_interfaces(sigar)
    counters[:network][:interfaces] = net_counters
    network["interfaces"] = iface
  end

  collect_data(:default) do
    require "sigar"
    sigar = Sigar.new

    network Mash.new unless network
    network[:interfaces] = Mash.new unless network[:interfaces]
    counters Mash.new unless counters
    counters[:network] = Mash.new unless counters[:network]

    ninfo = sigar.net_info
    network[:default_interface] = ninfo.default_gateway_interface
    network[:default_gateway] = ninfo.default_gateway

    iface, net_counters = fetch_interfaces(sigar)
    counters[:network][:interfaces] = net_counters
    network[:interfaces] = iface

    sigar.net_route_list.each do |route|
      next unless network[:interfaces][route.ifname] # this
      # should never happen
      network[:interfaces][route.ifname][:route] = Mash.new unless network[:interfaces][route.ifname][:route]
      route_data={}
      Ohai::Mixin::NetworkConstants::SIGAR_ROUTE_METHODS.each do |m|
        if(m == :flags)
          route_data[m]=flags(route.send(m))
        else
          route_data[m]=route.send(m)
        end
      end
      network[:interfaces][route.ifname][:route][route.destination] = route_data
    end
  end
end
