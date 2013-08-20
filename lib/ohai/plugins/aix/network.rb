#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

# Loads following information.
# :default_interface, :default_gateway - route -n get 0
# :interfaces
# => routes(netstat -nr | grep en0)
# => addresses (ifconfig en0 or lsattr -El en0), macaddress (entstat -d en0 = Hardware Address: be:42:80:00:b0:05)
# => flags (ifconfig en0)
# => state up/down (ifconfig/lsattr)
# => arp (arp -an)

iface = Mash.new


# :default_interface, :default_gateway - route -n get 0
popen4("route -n get 0") do |pid, stdin, stdout, stderr|
  stdin.close
  stdout.each do |line|
    case line
    when /gateway: (\S+)/
      network[:default_gateway] = $1
    when /interface: (\S+)/
      network[:default_interface] = $1
    end
  end
end

# Helpers
def hex_to_dec_netmask(netmask)
  # example '0xffff0000' -> '255.255.0.0'
  dec = netmask[2..3].to_i(16).to_s(10)
  [4,6,8].each { |n| dec = dec + "." + netmask[n..n+1].to_i(16).to_s(10) }
  dec
end

# List the interfaces in system.
popen4("lsdev -Cc if") do |pid, stdin, stdout, stderr|
  stdin.close
  stdout.each do |line|
    if line =~ /(\S+) (\S+)\s+(.+)/
      interface = $1
      iface[interface] = Mash.new unless iface[interface]
      iface[interface][:state] = ($2 == 'Available' ? 'up' : 'down')
      iface[interface][:description] = $3

      # Query the interface information
      popen4("ifconfig #{interface}") do |if_pid, if_stdin, if_stdout, if_stderr|
        if_stdin.close
        if_stdout.each do |line|
          case line
          when /^#{interface}:\sflags=\S+<(\S+)>/
            iface[interface][:flags] = $1.split(',')
            iface[interface][:metric] = $1 if line =~ /metric\s(\S+)/
          else
            # We have key value pairs.
            if line =~ /inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(\/(\d{1,2}))?/
              tmp_addr, tmp_prefix = $1, $3
              if tmp_prefix.nil?
                netmask = hex_to_dec_netmask($1) if line =~ /netmask\s(\S+)\s/
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

              if line =~ /broadcast\s(\S+)\s/
                iface[interface][:addresses][tmp_addr][:broadcast] = $1
              end
            elsif line =~ /inet6 ([a-f0-9\:%]+)\/(\d+)/
              # TODO do we have more properties on inet6 in aix? broadcast
              iface[interface][:addresses] = Mash.new unless iface[interface][:addresses]
              iface[interface][:addresses][$1] = { "family" => "inet6", "prefixlen" => $2 }
            else
              # load all key-values, example "tcp_sendspace 131072 tcp_recvspace 131072 rfc1323 1"
              properties = line.split
              n = properties.length/2 - 1
              (0..n).each do |i|
                iface[interface][properties[i*2]] = properties[(i*2+1)]
              end
            end
          end
        end
      end  #ifconfig stdout

      # Query macaddress
      popen4("entstat -d #{interface} | grep \"Hardware Address\"") do |e_pid, e_stdin, e_stdout, e_stderr|
        e_stdin.close
        iface[interface][:addresses] = Mash.new unless iface[interface][:addresses]
        e_stdout.each do |line|
          iface[interface][:addresses][$1.upcase] = { "family" => "lladdr" } if line =~ /Hardware Address: (\S+)/
        end
      end
    end
  end  #lsdev stdout
end

# Query routes information
%w{inet inet6}.each do |family|
  popen4("netstat -nrf #{family}") do |n_pid, n_stdin, n_stdout, n_stderr|
    n_stdin.close
    n_stdout.each do |line|
      if line =~ /(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\S+)/
        interface = $6
        iface[interface][:routes] = Array.new unless iface[interface][:routes]
        iface[interface][:routes] << Mash.new( :destination => $1, :family => family,
                                :via => $2, :flags => $3)
      end
    end
  end
end

# List the arp entries in system.
popen4("arp -an") do |pid, stdin, stdout, stderr|
  stdin.close
  count = 0
  stdout.each do |line|
    network[:arp] = Mash.new unless network[:arp]
    if line =~ /\s*(\S+) \((\S+)\) at ([a-fA-F0-9\:]+) \[(\w+)\] stored in bucket/
      network[:arp][count] = Mash.new unless network[:arp][count]
      network[:arp][count][:remote_host] = $1
      network[:arp][count][:remote_ip] = $2
      network[:arp][count][:remote_mac] = $3.downcase
      count += 1
    end
  end
end

network["interfaces"] = iface

