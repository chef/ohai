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
                :attribute_prefix => :default,
                :neighbour_attribute => :arp
              },
              {
                :name => "inet6",
                :default_route => "::/0",
                :attribute_prefix => :default_inet6,
                :neighbour_attribute => :neighbour_inet6
              }
             ]

  families.each do |family|
    begin
      route_result = from("ip -f #{family[:name]} route show exact #{family[:default_route]}").chomp

      prefix = family[:attribute_prefix]
      # expected results:
      # - default via 10.0.2.4 dev br0
      # - default dev br0  scope link
      if route_result_match = route_result.match(/\svia\s+([^\s+]+)\s+dev\s([^\s+]+)\b/)
        network["#{prefix}_interface"] = route_result_match[2]
        network["#{prefix}_gateway"] = route_result_match[1]
      elsif route_result_match = route_result.match(/\sdev\s([^\s+]+)\s+scope\s+link/)
        network["#{prefix}_interface"] = route_result_match[1]
        network["#{prefix}_gateway"] = family[:default_route].chomp("/0") # backward compatible result
      else
        # should nodes always have a default route ? i don't think so
        # anyway, backward compatible raise for inet4 only ! :-)
        raise unless family[:name] == "inet"
      end
    rescue
      Ohai::Log.debug("Unable to determine default interface")
    end
  end

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
    key = family[:neighbour_attribute]
    popen4("ip -f #{family[:name]} neigh show") do |pid, stdin, stdout, stderr|
      stdin.close
      stdout.each do |line|
        if line =~ /^([a-f0-9\:\.]+)\s+dev\s+([^\s]+)\s+lladdr\s+([a-fA-F0-9\:]+)/
          unless iface[$2]
            Ohai::Log.warn("neighbour list has entries for unknown interface #{iface[$2]}")
            next
          end
          iface[$2][key] = Mash.new unless iface[$2][key]
          iface[$2][key][$1] = $3.downcase
        end
      end
    end
  end

  popen4("ip route show scope link") do |pid, stdin, stdout, stderr|
    stdin.close
    stdout.each do |line|
      if line =~ /^([^\s]+)\s+dev\s+([^\s]+).*\s+src\s+([^\s]+)\b/
        tmp_route_cidr = $1
        tmp_int = $2
        tmp_source_addr = $3
        unless iface[tmp_int]
          Ohai::Log.debug("Skipping previously unseen interface from 'ip route show scope link': #{tmp_int}")
          next
        end
        iface[tmp_int][:routes] = Mash.new unless iface[tmp_int][:routes]
        iface[tmp_int][:routes][tmp_route_cidr] = Mash.new( :scope => "Link", :src => tmp_source_addr )
        # while looping through the link level scope routes we will set ipaddress from the source address if
        # 1) there's a default route,
        #    the interface is the default_interface
        #    the ip source address from the routing table is really set on the node,
        #    the route entry matches the default_gateway
        # macaddress is then set from this interface
        # for now the ip6address is brutaly associated with ipaddress' iface
        if (network.has_key? "default_interface") &&
            (network[:default_interface] == tmp_int) &&
            (iface[tmp_int][:addresses].has_key? tmp_source_addr) &&
            (IPAddr.new(tmp_route_cidr).include? network[:default_gateway])
          ipaddress tmp_source_addr
          macaddress iface[tmp_int][:addresses].select{|k,v| v["family"]=="lladdr"}.first.first unless iface[tmp_int][:flags].include? "NOARP"
          ip6address iface[tmp_int][:addresses].reject{|address, hash| hash['family'] != "inet6" || hash['scope'] != 'Global'}.first.first
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

