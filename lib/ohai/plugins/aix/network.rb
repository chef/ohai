#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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
  require "ipaddr"

  provides "network", "counters/network", "macaddress"

  # Helpers
  def hex_to_dec_netmask(netmask)
    # example '0xffff0000' -> '255.255.0.0'
    dec = netmask[2..3].to_i(16).to_s(10)
    [4, 6, 8].each { |n| dec = dec + "." + netmask[n..n + 1].to_i(16).to_s(10) }
    dec
  end

  collect_data(:aix) do
    # Loads following information.
    # :default_interface, :default_gateway - route -n get 0
    # :interfaces
    # => routes(netstat -nr | grep en0)
    # => addresses (ifconfig en0 or lsattr -El en0), macaddress (entstat -d en0 = Hardware Address: be:42:80:00:b0:05)
    # => flags (ifconfig en0)
    # => state up/down (ifconfig/lsattr)
    # => arp (arp -an)

    iface = Mash.new

    network Mash.new unless network
    network[:interfaces] = Mash.new unless network[:interfaces]

    # We unfortunately have to do things a bit different here, if ohai is running
    # within a WPAR. For instance, the WPAR isn't aware of some of its own networking
    # minutia such as default gateway/route.
    unless shell_out("uname -W").stdout.to_i > 0
      # :default_interface, :default_gateway - route -n get 0
      so = shell_out("netstat -rn |grep default")
      so.stdout.lines.each do |line|
        items = line.split(" ")
        if items[0] == "default"
          network[:default_gateway] = items[1]
          network[:default_interface] = items[5]
        end
      end
    end

    # Splits the ifconfig output to 1 line per interface
    if_so = shell_out("ifconfig -a")
    if_so.stdout.gsub(/\n(\w+\d+)/, '___\1').split("___").each do |intraface|
      splat = intraface.split(":")
      interface = splat[0]
      line = splat[1..-1][0]
      iface[interface] = Mash.new
      iface[interface][:state] = (line.include?("<UP,") ? "up" : "down")

      intraface.lines.each do |lin|
        case lin
        when /flags=\S+<(\S+)>/
          iface[interface][:flags] = $1.split(",")
          iface[interface][:metric] = $1 if lin =~ /metric\s(\S+)/
        else
          # We have key value pairs.
          if lin =~ /inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(\/(\d{1,2}))?/
            tmp_addr, tmp_prefix = $1, $3
            if tmp_prefix.nil?
              netmask = hex_to_dec_netmask($1) if lin =~ /netmask\s(\S+)\s/
              unless netmask
                tmp_prefix ||= "32"
                netmask = IPAddr.new("255.255.255.255").mask(tmp_prefix.to_i).to_s
              end
            else
              netmask = IPAddr.new("255.255.255.255").mask(tmp_prefix.to_i).to_s
            end

            iface[interface][:addresses] = Mash.new unless iface[interface][:addresses]
            iface[interface][:addresses][tmp_addr] = { "family" => "inet", "prefixlen" => tmp_prefix }
            iface[interface][:addresses][tmp_addr][:netmask] = netmask

            if lin =~ /broadcast\s(\S+)\s/
              iface[interface][:addresses][tmp_addr][:broadcast] = $1
            end
          elsif lin =~ /inet6 ([a-f0-9\:]+)%?([\d]*)\/?(\d*)?/
            # TODO do we have more properties on inet6 in aix? broadcast
            iface[interface][:addresses] = Mash.new unless iface[interface][:addresses]
            iface[interface][:addresses][$1] = { "family" => "inet6", "zone_index" => $2, "prefixlen" => $3 }
          else
            # load all key-values, example "tcp_sendspace 131072 tcp_recvspace 131072 rfc1323 1"
            properties = lin.split
            n = properties.length / 2 - 1
            (0..n).each do |i|
              iface[interface][properties[i * 2]] = properties[(i * 2 + 1)]
            end
          end
        end
      end

      # Query macaddress
      e_so = shell_out("entstat -d #{interface} | grep \"Hardware Address\"")
      iface[interface][:addresses] = Mash.new unless iface[interface][:addresses]
      e_so.stdout.lines.each do |line|
        if line =~ /Hardware Address: (\S+)/
          iface[interface][:addresses][$1.upcase] = { "family" => "lladdr" }
          macaddress $1.upcase unless shell_out("uname -W").stdout.to_i > 0
        end
      end
    end #ifconfig stdout

    # Query routes information
    %w{inet inet6}.each do |family|
      so_n = shell_out("netstat -nrf #{family}")
      so_n.stdout.lines.each do |line|
        if line =~ /(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\S+)/
          interface = $6
          iface[interface][:routes] = Array.new unless iface[interface][:routes]
          iface[interface][:routes] << Mash.new( :destination => $1, :family => family,
                                                 :via => $2, :flags => $3)
        end
      end
    end

    # List the arp entries in system.
    so = shell_out("arp -an")
    count = 0
    so.stdout.lines.each do |line|
      network[:arp] = Mash.new unless network[:arp]
      if line =~ /\s*(\S+) \((\S+)\) at ([a-fA-F0-9\:]+) \[(\w+)\] stored in bucket/
        network[:arp][count] = Mash.new unless network[:arp][count]
        network[:arp][count][:remote_host] = $1
        network[:arp][count][:remote_ip] = $2
        network[:arp][count][:remote_mac] = $3.downcase
        count += 1
      end
    end
    network["interfaces"] = iface
  end
end
