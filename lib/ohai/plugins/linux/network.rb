#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Chris Read <chris.read@gmail.com>
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
  provides "ipaddress", "ip6address", "macaddress"

  def linux_encaps_lookup(encap)
    return "Loopback" if encap.eql?("Local Loopback") || encap.eql?("loopback")
    return "PPP" if encap.eql?("Point-to-Point Protocol")
    return "SLIP" if encap.eql?("Serial Line IP")
    return "VJSLIP" if encap.eql?("VJ Serial Line IP")
    return "IPIP" if encap.eql?("IPIP Tunnel")
    return "6to4" if encap.eql?("IPv6-in-IPv4")
    return "Ethernet" if encap.eql?("ether")
    encap
  end

  def ipv6_enabled?
    File.exist? "/proc/net/if_inet6"
  end

  def iproute2_binary_available?
    ["/sbin/ip", "/usr/bin/ip", "/bin/ip"].any? { |path| File.exist?(path) }
  end

  def find_ethtool_binary
    ["/sbin/ethtool", "/usr/sbin/ethtool"].find { |path| File.exist?(path) }
  end

  def is_openvz?
    ::File.directory?("/proc/vz")
  end

  def is_openvz_host?
    is_openvz? && ::File.directory?("/proc/bc")
  end

  def extract_neighbors(family, iface, neigh_attr)
    so = shell_out("ip -f #{family[:name]} neigh show")
    so.stdout.lines do |line|
      if line =~ /^([a-f0-9\:\.]+)\s+dev\s+([^\s]+)\s+lladdr\s+([a-fA-F0-9\:]+)/
        interface = iface[$2]
        unless interface
          Ohai::Log.warn("neighbor list has entries for unknown interface #{interface}")
          next
        end
        interface[neigh_attr] = Mash.new unless interface[neigh_attr]
        interface[neigh_attr][$1] = $3.downcase
      end
    end
    iface
  end

  # checking the routing tables
  # why ?
  # 1) to set the default gateway and default interfaces attributes
  # 2) on some occasions, the best way to select node[:ipaddress] is to look at
  #    the routing table source field.
  # 3) and since we're at it, let's populate some :routes attributes
  # (going to do that for both inet and inet6 addresses)
  def check_routing_table(family, iface, default_route_table)
    so = shell_out("ip -o -f #{family[:name]} route show table #{default_route_table}")
    so.stdout.lines do |line|
      line.strip!
      Ohai::Log.debug("Plugin Network: Parsing #{line}")
      if line =~ /\\/
        parts = line.split('\\')
        route_dest = parts.shift.strip
        route_endings = parts
      elsif line =~ /^([^\s]+)\s(.*)$/
        route_dest = $1
        route_endings = [$2]
      else
        next
      end
      route_endings.each do |route_ending|
        if route_ending =~ /\bdev\s+([^\s]+)\b/
          route_int = $1
        else
          Ohai::Log.debug("Plugin Network: Skipping route entry without a device: '#{line}'")
          next
        end
        route_int = "venet0:0" if is_openvz? && !is_openvz_host? && route_int == "venet0" && iface["venet0:0"]

        unless iface[route_int]
          Ohai::Log.debug("Plugin Network: Skipping previously unseen interface from 'ip route show': #{route_int}")
          next
        end

        route_entry = Mash.new(:destination => route_dest,
                               :family => family[:name])
        %w{via scope metric proto src}.each do |k|
          route_entry[k] = $1 if route_ending =~ /\b#{k}\s+([^\s]+)\b/
        end

        # a sanity check, especially for Linux-VServer, OpenVZ and LXC:
        # don't report the route entry if the src address isn't set on the node
        # unless the interface has no addresses of this type at all
        if route_entry[:src]
          addr = iface[route_int][:addresses]
          unless addr.nil? || addr.has_key?(route_entry[:src]) ||
              addr.values.all? { |a| a["family"] != family[:name] }
            Ohai::Log.debug("Plugin Network: Skipping route entry whose src does not match the interface IP")
            next
          end
        end

        iface[route_int][:routes] = Array.new unless iface[route_int][:routes]
        iface[route_int][:routes] << route_entry
      end
    end
    iface
  end

  # now looking at the routes to set the default attributes
  # for information, default routes can be of this form :
  # - default via 10.0.2.4 dev br0
  # - default dev br0  scope link
  # - default dev eth0  scope link src 1.1.1.1
  # - default via 10.0.3.1 dev eth1  src 10.0.3.2  metric 10
  # - default via 10.0.4.1 dev eth2  src 10.0.4.2  metric 20

  # using a temporary var to hold routes and their interface name
  def parse_routes(family, iface)
    iface.collect do |i, iv|
      if iv[:routes]
        iv[:routes].collect do |r|
          r.merge(:dev => i) if r[:family] == family[:name]
        end.compact
      end
    end.compact.flatten
  end

  # determine layer 1 details for the interface using ethtool
  def ethernet_layer_one(iface)
    return iface unless ethtool_binary = find_ethtool_binary
    keys = %w{ Speed Duplex Port Transceiver Auto-negotiation MDI-X }
    iface.each_key do |tmp_int|
      next unless iface[tmp_int][:encapsulation] == "Ethernet"
      so = shell_out("#{ethtool_binary} #{tmp_int}")
      so.stdout.lines do |line|
        line.chomp!
        Ohai::Log.debug("Plugin Network: Parsing ethtool output: #{line}")
        line.lstrip!
        k, v = line.split(": ")
        next unless keys.include? k
        k.downcase!.tr!("-", "_")
        if k == "speed"
          k = "link_speed" # This is not necessarily the maximum speed the NIC supports
          v = v[/\d+/].to_i
        end
        iface[tmp_int][k] = v
      end
    end
    iface
  end

  # determine ring parameters for the interface using ethtool
  def ethernet_ring_parameters(iface)
    return iface unless ethtool_binary = find_ethtool_binary
    iface.each_key do |tmp_int|
      next unless iface[tmp_int][:encapsulation] == "Ethernet"
      so = shell_out("#{ethtool_binary} -g #{tmp_int}")
      Ohai::Log.debug("Plugin Network: Parsing ethtool output: #{so.stdout}")
      type = nil
      iface[tmp_int]["ring_params"] = {}
      so.stdout.lines.each do |line|
        next if line.start_with?("Ring parameters for")
        next if line.strip.nil?
        if line =~ /Pre-set maximums/
          type = "max"
          next
        end
        if line =~ /Current hardware settings/
          type = "current"
          next
        end
        key, val = line.split(/:\s+/)
        if type && val
          ring_key = "#{type}_#{key.downcase.tr(' ', '_')}"
          iface[tmp_int]["ring_params"][ring_key] = val.to_i
        end
      end
    end
    iface
  end

  # determine link stats, vlans, queue length, and state for an interface using ip
  def link_statistics(iface, net_counters)
    so = shell_out("ip -d -s link")
    tmp_int = nil
    on_rx = true
    so.stdout.lines do |line|
      if line =~ IPROUTE_INT_REGEX
        tmp_int = $2
        iface[tmp_int] = Mash.new unless iface[tmp_int]
        net_counters[tmp_int] = Mash.new unless net_counters[tmp_int]
      end

      if line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/
        int = on_rx ? :rx : :tx
        net_counters[tmp_int][int] = Mash.new unless net_counters[tmp_int][int]
        net_counters[tmp_int][int][:bytes] = $1
        net_counters[tmp_int][int][:packets] = $2
        net_counters[tmp_int][int][:errors] = $3
        net_counters[tmp_int][int][:drop] = $4
        if int == :rx
          net_counters[tmp_int][int][:overrun] = $5
        else
          net_counters[tmp_int][int][:carrier] = $5
          net_counters[tmp_int][int][:collisions] = $6
        end

        on_rx = !on_rx
      end

      if line =~ /qlen (\d+)/
        net_counters[tmp_int][:tx] = Mash.new unless net_counters[tmp_int][:tx]
        net_counters[tmp_int][:tx][:queuelen] = $1
      end

      if line =~ /vlan id (\d+)/ || line =~ /vlan protocol ([\w\.]+) id (\d+)/
        if $2
          tmp_prot = $1
          tmp_id = $2
        else
          tmp_id = $1
        end
        iface[tmp_int][:vlan] = Mash.new unless iface[tmp_int][:vlan]
        iface[tmp_int][:vlan][:id] = tmp_id
        iface[tmp_int][:vlan][:protocol] = tmp_prot if tmp_prot

        vlan_flags = line.scan(/(REORDER_HDR|GVRP|LOOSE_BINDING)/)
        if vlan_flags.length > 0
          iface[tmp_int][:vlan][:flags] = vlan_flags.flatten.uniq
        end
      end

      if line =~ /state (\w+)/
        iface[tmp_int]["state"] = $1.downcase
      end
    end
    iface
  end

  def match_iproute(iface, line, cint)
    if line =~ IPROUTE_INT_REGEX
      cint = $2
      iface[cint] = Mash.new
      if cint =~ /^(\w+)(\d+.*)/
        iface[cint][:type] = $1
        iface[cint][:number] = $2
      end

      if line =~ /mtu (\d+)/
        iface[cint][:mtu] = $1
      end

      flags = line.scan(/(UP|BROADCAST|DEBUG|LOOPBACK|POINTTOPOINT|NOTRAILERS|LOWER_UP|NOARP|PROMISC|ALLMULTI|SLAVE|MASTER|MULTICAST|DYNAMIC)/)
      if flags.length > 1
        iface[cint][:flags] = flags.flatten.uniq
      end
    end
    cint
  end

  def parse_ip_addr(iface)
    so = shell_out("ip addr")
    cint = nil
    so.stdout.lines do |line|
      cint = match_iproute(iface, line, cint)

      parse_ip_addr_link_line(cint, iface, line)
      cint = parse_ip_addr_inet_line(cint, iface, line)
      parse_ip_addr_inet6_line(cint, iface, line)
    end
  end

  def parse_ip_addr_link_line(cint, iface, line)
    if line =~ /link\/(\w+) ([\da-f\:]+) /
      iface[cint][:encapsulation] = linux_encaps_lookup($1)
      unless $2 == "00:00:00:00:00:00"
        iface[cint][:addresses] = Mash.new unless iface[cint][:addresses]
        iface[cint][:addresses][$2.upcase] = { "family" => "lladdr" }
      end
    end
  end

  def parse_ip_addr_inet_line(cint, iface, line)
    if line =~ /inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(\/(\d{1,2}))?/
      tmp_addr, tmp_prefix = $1, $3
      tmp_prefix ||= "32"
      original_int = nil

      # Are we a formerly aliased interface?
      if line =~ /#{cint}:(\d+)$/
        sub_int = $1
        alias_int = "#{cint}:#{sub_int}"
        original_int = cint
        cint = alias_int
      end

      iface[cint] = Mash.new unless iface[cint] # Create the fake alias interface if needed
      iface[cint][:addresses] = Mash.new unless iface[cint][:addresses]
      iface[cint][:addresses][tmp_addr] = { "family" => "inet", "prefixlen" => tmp_prefix }
      iface[cint][:addresses][tmp_addr][:netmask] = IPAddr.new("255.255.255.255").mask(tmp_prefix.to_i).to_s

      if line =~ /peer (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
        iface[cint][:addresses][tmp_addr][:peer] = $1
      end

      if line =~ /brd (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
        iface[cint][:addresses][tmp_addr][:broadcast] = $1
      end

      if line =~ /scope (\w+)/
        iface[cint][:addresses][tmp_addr][:scope] = ($1.eql?("host") ? "Node" : $1.capitalize)
      end

      # If we found we were an alias interface, restore cint to its original value
      cint = original_int unless original_int.nil?
    end
    cint
  end

  def parse_ip_addr_inet6_line(cint, iface, line)
    if line =~ /inet6 ([a-f0-9\:]+)\/(\d+) scope (\w+)( .*)?/
      iface[cint][:addresses] = Mash.new unless iface[cint][:addresses]
      tmp_addr = $1
      tags = $4 || ""
      tags = tags.split(" ")

      iface[cint][:addresses][tmp_addr] = {
        "family" => "inet6",
        "prefixlen" => $2,
        "scope" => ($3.eql?("host") ? "Node" : $3.capitalize),
        "tags" => tags,
      }
    end
  end

  # returns the macaddress for interface from a hash of interfaces (iface elsewhere in this file)
  def get_mac_for_interface(interfaces, interface)
    interfaces[interface][:addresses].select { |k, v| v["family"] == "lladdr" }.first.first unless interfaces[interface][:addresses].nil? || interfaces[interface][:flags].include?("NOARP")
  end

  # returns the default route with the lowest metric (unspecified metric is 0)
  def choose_default_route(routes)
    routes.select do |r|
      r[:destination] == "default"
    end.sort do |x, y|
      (x[:metric].nil? ? 0 : x[:metric].to_i) <=> (y[:metric].nil? ? 0 : y[:metric].to_i)
    end.first
  end

  def interface_has_no_addresses_in_family?(iface, family)
    return true if iface[:addresses].nil?
    iface[:addresses].values.all? { |addr| addr["family"] != family }
  end

  def interface_have_address?(iface, address)
    return false if iface[:addresses].nil?
    iface[:addresses].key?(address)
  end

  def interface_address_not_link_level?(iface, address)
    !(iface[:addresses][address][:scope].casecmp("link") == 0)
  end

  def interface_valid_for_route?(iface, address, family)
    return true if interface_has_no_addresses_in_family?(iface, family)

    interface_have_address?(iface, address) && interface_address_not_link_level?(iface, address)
  end

  def route_is_valid_default_route?(route, default_route)
    # if the route destination is a default route, it's good
    return true if route[:destination] == "default"

    # the default route has a gateway and the route matches the gateway
    !default_route[:via].nil? && IPAddress(route[:destination]).include?(IPAddress(default_route[:via]))
  end

  # ipv4/ipv6 routes are different enough that having a single algorithm to select the favored route for both creates unnecessary complexity
  # this method attempts to deduce the route that is most important to the user, which is later used to deduce the favored values for {ip,mac,ip6}address
  # we only consider routes that are default routes, or those routes that get us to the gateway for a default route
  def favored_default_route(routes, iface, default_route, family)
    routes.select do |r|
      if family[:name] == "inet"
        # the route must have a source address
        next if r[:src].nil? || r[:src].empty?

        # the interface specified in the route must exist
        route_interface = iface[r[:dev]]
        next if route_interface.nil? # the interface specified in the route must exist

        # the interface must have no addresses, or if it has the source address, the address must not
        # be a link-level address
        next unless interface_valid_for_route?(route_interface, r[:src], "inet")

        # the route must either be a default route, or it must have a gateway which is accessible via the route
        next unless route_is_valid_default_route?(r, default_route)

        true
      elsif family[:name] == "inet6"
        iface[r[:dev]] &&
          iface[r[:dev]][:state] == "up" &&
          route_is_valid_default_route?(r, default_route)
      end
    end.sort_by do |r|
      # sorting the selected routes:
      # - getting default routes first
      # - then sort by metric
      # - then by prefixlen
      [
       r[:destination] == "default" ? 0 : 1,
       r[:metric].nil? ? 0 : r[:metric].to_i,
       # for some reason IPAddress doesn't accept "::/0", it doesn't like prefix==0
       # just a quick workaround: use 0 if IPAddress fails
       begin
         IPAddress( r[:destination] == "default" ? family[:default_route] : r[:destination] ).prefix
       rescue
         0
       end,
      ]
    end.first
  end

  # Both the network plugin and this plugin (linux/network) are run on linux. This plugin runs first.
  # If the 'ip' binary is available, this plugin may set {ip,mac,ip6}address. The network plugin should not overwrite these.
  # The older code section below that relies on the deprecated net-tools, e.g. netstat and ifconfig, provides less functionality.
  collect_data(:linux) do
    require "ipaddr"

    iface = Mash.new
    net_counters = Mash.new

    network Mash.new unless network
    network[:interfaces] = Mash.new unless network[:interfaces]
    counters Mash.new unless counters
    counters[:network] = Mash.new unless counters[:network]

    # ohai.plugin[:network][:default_route_table] = 'default'
    if configuration(:default_route_table).nil? || configuration(:default_route_table).empty?
      default_route_table = "main"
    else
      default_route_table = configuration(:default_route_table)
    end
    Ohai::Log.debug("Plugin Network: default route table is '#{default_route_table}'")

    # Match the lead line for an interface from iproute2
    # 3: eth0.11@eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
    # The '@eth0:' portion doesn't exist on primary interfaces and thus is optional in the regex
    IPROUTE_INT_REGEX = /^(\d+): ([0-9a-zA-Z@:\.\-_]*?)(@[0-9a-zA-Z]+|):\s/ unless defined? IPROUTE_INT_REGEX

    if iproute2_binary_available?
      # families to get default routes from
      families = [{
                    :name => "inet",
                    :default_route => "0.0.0.0/0",
                    :default_prefix => :default,
                    :neighbour_attribute => :arp,
                  }]

      if ipv6_enabled?
        families << {
                      :name => "inet6",
                      :default_route => "::/0",
                      :default_prefix => :default_inet6,
                      :neighbour_attribute => :neighbour_inet6,
                    }
      end

      parse_ip_addr(iface)

      iface = link_statistics(iface, net_counters)

      families.each do |family|
        neigh_attr = family[:neighbour_attribute]
        default_prefix = family[:default_prefix]

        iface = extract_neighbors(family, iface, neigh_attr)

        iface = check_routing_table(family, iface, default_route_table)

        routes = parse_routes(family, iface)

        default_route = choose_default_route(routes)

        if default_route.nil? || default_route.empty?
          attribute_name = if family[:name] == "inet"
                             "default_interface"
                           else
                             "default_#{family[:name]}_interface"
                           end
          Ohai::Log.debug("Plugin Network: Unable to determine '#{attribute_name}' as no default routes were found for that interface family")
        else
          network["#{default_prefix}_interface"] = default_route[:dev]
          Ohai::Log.debug("Plugin Network: #{default_prefix}_interface set to #{default_route[:dev]}")

          # setting gateway to 0.0.0.0 or :: if the default route is a link level one
          network["#{default_prefix}_gateway"] = default_route[:via] ? default_route[:via] : family[:default_route].chomp("/0")
          Ohai::Log.debug("Plugin Network: #{default_prefix}_gateway set to #{network["#{default_prefix}_gateway"]}")

          # deduce the default route the user most likely cares about to pick {ip,mac,ip6}address below
          favored_route = favored_default_route(routes, iface, default_route, family)

          # FIXME: This entire block should go away, and the network plugin should be the sole source of {ip,ip6,mac}address

          # since we're at it, let's populate {ip,mac,ip6}address with the best values
          # if we don't set these, the network plugin may set them afterwards
          if favored_route && !favored_route.empty?
            if family[:name] == "inet"
              ipaddress favored_route[:src]
              m = get_mac_for_interface(iface, favored_route[:dev])
              Ohai::Log.debug("Plugin Network: Overwriting macaddress #{macaddress} with #{m} from interface #{favored_route[:dev]}") if macaddress
              macaddress m
            elsif family[:name] == "inet6"
              # this rarely does anything since we rarely have src for ipv6, so this usually falls back on the network plugin
              ip6address favored_route[:src]
              if macaddress
                Ohai::Log.debug("Plugin Network: Not setting macaddress from ipv6 interface #{favored_route[:dev]} because macaddress is already set")
              else
                macaddress get_mac_for_interface(iface, favored_route[:dev])
              end
            end
          else
            Ohai::Log.debug("Plugin Network: Unable to deduce the favored default route for family '#{family[:name]}' despite finding a default route, and is not setting ipaddress/ip6address/macaddress. the network plugin may provide fallbacks.")
            Ohai::Log.debug("Plugin Network: This potential default route was excluded: #{default_route}")
          end
        end
      end # end families.each
    else # ip binary not available, falling back to net-tools, e.g. route, ifconfig
      begin
        so = shell_out("route -n")
        route_result = so.stdout.split($/).grep( /^0.0.0.0/ )[0].split( /[ \t]+/ )
        network[:default_gateway], network[:default_interface] = route_result.values_at(1, 7)
      rescue Ohai::Exceptions::Exec
        Ohai::Log.debug("Plugin Network: Unable to determine default interface")
      end

      so = shell_out("ifconfig -a")
      cint = nil
      so.stdout.lines do |line|
        tmp_addr = nil
        # dev_valid_name in the kernel only excludes slashes, nulls, spaces
        # http://git.kernel.org/?p=linux/kernel/git/stable/linux-stable.git;a=blob;f=net/core/dev.c#l851
        if line =~ /^([0-9a-zA-Z@\.\:\-_]+)\s+/
          cint = $1
          iface[cint] = Mash.new
          if cint =~ /^(\w+)(\d+.*)/
            iface[cint][:type] = $1
            iface[cint][:number] = $2
          end
        end
        if line =~ /Link encap:(Local Loopback)/ || line =~ /Link encap:(.+?)\s/
          iface[cint][:encapsulation] = linux_encaps_lookup($1)
        end
        if line =~ /HWaddr (.+?)\s/
          iface[cint][:addresses] = Mash.new unless iface[cint][:addresses]
          iface[cint][:addresses][$1] = { "family" => "lladdr" }
        end
        if line =~ /inet addr:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
          iface[cint][:addresses] = Mash.new unless iface[cint][:addresses]
          iface[cint][:addresses][$1] = { "family" => "inet" }
          tmp_addr = $1
        end
        if line =~ /inet6 addr: ([a-f0-9\:]+)\/(\d+) Scope:(\w+)/
          iface[cint][:addresses] = Mash.new unless iface[cint][:addresses]
          iface[cint][:addresses][$1] = { "family" => "inet6", "prefixlen" => $2, "scope" => ($3.eql?("Host") ? "Node" : $3) }
        end
        if line =~ /Bcast:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
          iface[cint][:addresses][tmp_addr]["broadcast"] = $1
        end
        if line =~ /Mask:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
          iface[cint][:addresses][tmp_addr]["netmask"] = $1
        end
        flags = line.scan(/(UP|BROADCAST|DEBUG|LOOPBACK|POINTTOPOINT|NOTRAILERS|RUNNING|NOARP|PROMISC|ALLMULTI|SLAVE|MASTER|MULTICAST|DYNAMIC)\s/)
        if flags.length > 1
          iface[cint][:flags] = flags.flatten
        end
        if line =~ /MTU:(\d+)/
          iface[cint][:mtu] = $1
        end
        if line =~ /P-t-P:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
          iface[cint][:peer] = $1
        end
        if line =~ /RX packets:(\d+) errors:(\d+) dropped:(\d+) overruns:(\d+) frame:(\d+)/
          net_counters[cint] = Mash.new unless net_counters[cint]
          net_counters[cint][:rx] = { "packets" => $1, "errors" => $2, "drop" => $3, "overrun" => $4, "frame" => $5 }
        end
        if line =~ /TX packets:(\d+) errors:(\d+) dropped:(\d+) overruns:(\d+) carrier:(\d+)/
          net_counters[cint][:tx] = { "packets" => $1, "errors" => $2, "drop" => $3, "overrun" => $4, "carrier" => $5 }
        end
        if line =~ /collisions:(\d+)/
          net_counters[cint][:tx]["collisions"] = $1
        end
        if line =~ /txqueuelen:(\d+)/
          net_counters[cint][:tx]["queuelen"] = $1
        end
        if line =~ /RX bytes:(\d+) \((\d+?\.\d+ .+?)\)/
          net_counters[cint][:rx]["bytes"] = $1
        end
        if line =~ /TX bytes:(\d+) \((\d+?\.\d+ .+?)\)/
          net_counters[cint][:tx]["bytes"] = $1
        end
      end

      so = shell_out("arp -an")
      so.stdout.lines do |line|
        if line =~ /^\S+ \((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\) at ([a-fA-F0-9\:]+) \[(\w+)\] on ([0-9a-zA-Z\.\:\-]+)/
          next unless iface[$4] # this should never happen
          iface[$4][:arp] = Mash.new unless iface[$4][:arp]
          iface[$4][:arp][$1] = $2.downcase
        end
      end
    end # end "ip else net-tools" block

    iface = ethernet_layer_one(iface)
    iface = ethernet_ring_parameters(iface)
    counters[:network][:interfaces] = net_counters
    network["interfaces"] = iface
  end
end
