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

require 'ipaddr'
provides "network", "counters/network"

def encaps_lookup(encap)
  return "Loopback" if encap.eql?("Local Loopback") || encap.eql?("loopback")
  return "PPP" if encap.eql?("Point-to-Point Protocol")
  return "SLIP" if encap.eql?("Serial Line IP")
  return "VJSLIP" if encap.eql?("VJ Serial Line IP")
  return "IPIP" if encap.eql?("IPIP Tunnel")
  return "6to4" if encap.eql?("IPv6-in-IPv4")
  return "Ethernet" if encap.eql?("ether")
  encap
end

iface = Mash.new
net_counters = Mash.new

# Match the lead line for an interface from iproute2
# 3: eth0.11@eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP 
# The '@eth0:' portion doesn't exist on primary interfaces and thus is optional in the regex
IPROUTE_INT_REGEX = /^(\d+): ([0-9a-zA-Z@:\.\-_]*?)(@[0-9a-zA-Z]+|):\s/

if File.exist?("/sbin/ip")

  # families to get default routes from
  families = [
              {
                :name => "inet",
                :default_route => "0.0.0.0/0",
                :default_prefix => :default,
                :neighbour_attribute => :arp
              },
              {
                :name => "inet6",
                :default_route => "::/0",
                :default_prefix => :default_inet6,
                :neighbour_attribute => :neighbour_inet6
              }
             ]

  popen4("ip addr") do |pid, stdin, stdout, stderr|
    stdin.close
    cint = nil
    stdout.each do |line|
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
      if line =~ /link\/(\w+) ([\da-f\:]+) /
        iface[cint][:encapsulation] = encaps_lookup($1)
        unless $2 == "00:00:00:00:00:00"
          iface[cint][:addresses] = Mash.new unless iface[cint][:addresses]
          iface[cint][:addresses][$2.upcase] = { "family" => "lladdr" }
        end
      end
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

        # If we found we were an an alias interface, restore cint to its original value
        cint = original_int unless original_int.nil?
      end
      if line =~ /inet6 ([a-f0-9\:]+)\/(\d+) scope (\w+)/
        iface[cint][:addresses] = Mash.new unless iface[cint][:addresses]
        tmp_addr = $1
        iface[cint][:addresses][tmp_addr] = { "family" => "inet6", "prefixlen" => $2, "scope" => ($3.eql?("host") ? "Node" : $3.capitalize) }
      end
    end
  end

  popen4("ip -d -s link") do |pid, stdin, stdout, stderr|
    stdin.close
    tmp_int = nil
    on_rx = true
    stdout.each do |line|
      if line =~ IPROUTE_INT_REGEX
        tmp_int = $2
        net_counters[tmp_int] = Mash.new unless net_counters[tmp_int]
      end

      if line =~ /(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/
        int = on_rx ? :rx : :tx
        net_counters[tmp_int][int] = Mash.new unless net_counters[tmp_int][int]
        net_counters[tmp_int][int][:bytes] = $1
        net_counters[tmp_int][int][:packets] = $2
        net_counters[tmp_int][int][:errors] = $3
        net_counters[tmp_int][int][:drop] = $4
        if(int == :rx)
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
       
      if line =~ /vlan id (\d+)/
        tmp_id = $1
        iface[tmp_int][:vlan] = Mash.new unless iface[tmp_int][:vlan]
        iface[tmp_int][:vlan][:id] = tmp_id

        vlan_flags = line.scan(/(REORDER_HDR|GVRP|LOOSE_BINDING)/)
        if vlan_flags.length > 0
          iface[tmp_int][:vlan][:flags] = vlan_flags.flatten.uniq
        end
      end

      if line =~ /state (\w+)/
        iface[tmp_int]['state'] = $1.downcase
      end


    end
  end

  families.each do |family|
    neigh_attr = family[:neighbour_attribute]
    default_prefix = family[:default_prefix]

    popen4("ip -f #{family[:name]} neigh show") do |pid, stdin, stdout, stderr|
      stdin.close
      stdout.each do |line|
        if line =~ /^([a-f0-9\:\.]+)\s+dev\s+([^\s]+)\s+lladdr\s+([a-fA-F0-9\:]+)/
          unless iface[$2]
            Ohai::Log.warn("neighbour list has entries for unknown interface #{iface[$2]}")
            next
          end
          iface[$2][neigh_attr] = Mash.new unless iface[$2][neigh_attr]
          iface[$2][neigh_attr][$1] = $3.downcase
        end
      end
    end

    # checking the routing tables
    # why ?
    # 1) to set the default gateway and default interfaces attributes
    # 2) on some occasions, the best way to select node[:ipaddress] is to look at
    #    the routing table source field.
    # 3) and since we're at it, let's populate some :routes attributes
    # (going to do that for both inet and inet6 addresses)
    popen4("ip -f #{family[:name]} route show") do |pid, stdin, stdout, stderr|
      stdin.close
      stdout.each do |line|
        if line =~ /^([^\s]+)\s(.*)$/
          route_dest = $1
          route_ending = $2
          #
          if route_ending =~ /\bdev\s+([^\s]+)\b/
            route_int = $1
          else
            Ohai::Log.debug("Skipping route entry without a device: '#{line}'")
            next
          end

          unless iface[route_int]
            Ohai::Log.debug("Skipping previously unseen interface from 'ip route show': #{route_int}")
            next
          end

          route_entry = Mash.new( :destination => route_dest,
                                  :family => family[:name] )
          %w[via scope metric proto src].each do |k|
            route_entry[k] = $1 if route_ending =~ /\b#{k}\s+([^\s]+)\b/
          end

          # a sanity check, especially for Linux-VServer, OpenVZ and LXC:
          # don't report the route entry if the src address isn't set on the node
          next if route_entry[:src] and not iface[route_int][:addresses].has_key? route_entry[:src]

          iface[route_int][:routes] = Array.new unless iface[route_int][:routes]
          iface[route_int][:routes] << route_entry
        end
      end
    end
    # now looking at the routes to set the default attributes
    # for information, default routes can be of this form :
    # - default via 10.0.2.4 dev br0
    # - default dev br0  scope link
    # - default via 10.0.3.1 dev eth1  src 10.0.3.2  metric 10
    # - default via 10.0.4.1 dev eth2  src 10.0.4.2  metric 20

    # using a temporary var to hold routes and their interface name
    routes = iface.collect do |i,iv|
      iv[:routes].collect do |r|
        r.merge(:dev=>i) if r[:family] == family[:name]
      end.compact if iv[:routes]
    end.compact.flatten

    # using a temporary var to hold the default route
    # in case there are more than 1 default route, sort it by its metric
    # and return the first one
    # (metric value when unspecified is 0)
    default_route = routes.select do |r|
      r[:destination] == "default"
    end.sort do |x,y|
      (x[:metric].nil? ? 0 : x[:metric].to_i) <=> (y[:metric].nil? ? 0 : y[:metric].to_i)
    end.first

    if default_route.nil? or default_route.empty?
      Ohai::Log.debug("Unable to determine default #{family[:name]} interface")
    else
      network["#{default_prefix}_interface"] = default_route[:dev]
      Ohai::Log.debug("#{default_prefix}_interface set to #{default_route[:dev]}")

      # setting gateway to 0.0.0.0 or :: if the default route is a link level one
      network["#{default_prefix}_gateway"] = default_route[:via] ? default_route[:via] : family[:default_route].chomp("/0")
      Ohai::Log.debug("#{default_prefix}_gateway set to #{network["#{default_prefix}_gateway"]}")

      # since we're at it, let's populate {ip,mac,ip6}address with the best values
      # using the source field when it's specified :
      # 1) in the default route
      # 2) in the route entry used to reach the default gateway
      route = routes.select do |r|
        # selecting routes
        r[:src] and # it has a src field
          iface[r[:dev]] and # the iface exists
          iface[r[:dev]][:addresses].has_key? r[:src] and # the src ip is set on the node
          iface[r[:dev]][:addresses][r[:src]][:scope].downcase != "link" and # this isn't a link level addresse
          ( r[:destination] == "default" or
            ( default_route[:via] and # the default route has a gateway
              IPAddress(r[:destination]).include? IPAddress(default_route[:via]) # the route matches the gateway
              )
            )
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
         end
        ]
      end.first

      unless route.nil? or route.empty?
        if family[:name] == "inet"
          ipaddress route[:src]
          macaddress iface[route[:dev]][:addresses].select{|k,v| v["family"]=="lladdr"}.first.first unless iface[route[:dev]][:flags].include? "NOARP"
        else
          ip6address route[:src]
        end
      end
    end
  end

else

  begin
    route_result = from("route -n \| grep -m 1 ^0.0.0.0").split(/[ \t]+/)
    network[:default_gateway], network[:default_interface] = route_result.values_at(1,7)
  rescue Ohai::Exceptions::Exec
    Ohai::Log.debug("Unable to determine default interface")
  end

  popen4("ifconfig -a") do |pid, stdin, stdout, stderr|
    stdin.close
    cint = nil
    stdout.each do |line|
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
        iface[cint][:encapsulation] = encaps_lookup($1)
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
  end


  popen4("arp -an") do |pid, stdin, stdout, stderr|
    stdin.close
    stdout.each do |line|
      if line =~ /^\S+ \((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\) at ([a-fA-F0-9\:]+) \[(\w+)\] on ([0-9a-zA-Z\.\:\-]+)/
        next unless iface[$4] # this should never happen
        iface[$4][:arp] = Mash.new unless iface[$4][:arp]
        iface[$4][:arp][$1] = $2.downcase
      end
    end
  end

end


counters[:network][:interfaces] = net_counters

network["interfaces"] = iface

