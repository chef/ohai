# frozen_string_literal: true
#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
  require_relative "../../mixin/network_helper"

  provides "network", "network/interfaces", "counters/network", "macaddress"

  include Ohai::Mixin::NetworkHelper

  collect_data(:aix) do
    require "ipaddr" unless defined?(IPAddr)

    # Loads following information.
    # :default_interface, :default_gateway - route -n get 0
    # :interfaces
    # => routes(netstat -nr | grep en0)
    # => addresses (ifconfig en0 or lsattr -El en0), macaddress (entstat -d en0 = Hardware Address: be:42:80:00:b0:05)
    # => flags (ifconfig en0)
    # => state up/down (ifconfig/lsattr)
    # => arp (arp -an)

    ifaces = Mash.new

    network Mash.new unless network

    # We unfortunately have to do things a bit different here, if ohai is running
    # within a WPAR. For instance, the WPAR isn't aware of some of its own networking
    # minutia such as default gateway/route. lpars return 0 here. wpars return > 0
    unless shell_out("uname -W").stdout.to_i > 0
      # :default_interface, :default_gateway - route -n get 0
      default_line = shell_out("netstat -rn")
        .stdout
        .each_line
        .detect { |l| l.start_with?("default") }
        .split
      network[:default_gateway] = default_line[1]
      network[:default_interface] = default_line[5]
    end

    # Splits the ifconfig output into arrays of interface strings
    shell_out("ifconfig -a").stdout.split(/\n(?=\w)/).each do |int_lines|
      int_name, int_data = int_lines.split(":", 2)

      ifaces[int_name] = Mash.new
      ifaces[int_name][:addresses] ||= Mash.new
      ifaces[int_name][:state] = (int_data.include?("<UP,") ? "up" : "down")

      int_data.each_line do |line|
        case line
        when /flags=\S+<(\S+)>/
          ifaces[int_name][:flags] = $1.split(",")
          ifaces[int_name][:metric] = $1 if line =~ /metric\s(\S+)/
        else
          # We have key value pairs.
          if line =~ %r{inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(/(\d{1,2}))?}
            tmp_addr = $1
            tmp_prefix = $3
            if tmp_prefix.nil?
              netmask = hex_to_dec_netmask($1) if line =~ /netmask\s0x(\S+)\s/
              unless netmask
                tmp_prefix ||= "32"
                netmask = IPAddr.new("255.255.255.255").mask(tmp_prefix.to_i).to_s
              end
            else
              netmask = IPAddr.new("255.255.255.255").mask(tmp_prefix.to_i).to_s
            end

            ifaces[int_name][:addresses][tmp_addr] = { "family" => "inet", "prefixlen" => tmp_prefix }
            ifaces[int_name][:addresses][tmp_addr][:netmask] = netmask

            if line =~ /broadcast\s(\S+)\s/
              ifaces[int_name][:addresses][tmp_addr][:broadcast] = $1
            end
          elsif line =~ %r{inet6 ([a-f0-9\:]+)%?(\d*)/?(\d*)?}
            # TODO: do we have more properties on inet6 in aix? broadcast
            ifaces[int_name][:addresses] ||= Mash.new
            ifaces[int_name][:addresses][$1] = { "family" => "inet6", "zone_index" => $2, "prefixlen" => $3 }
          else
            # add all key value data into the interface mash
            # for example "tcp_sendspace 131072 tcp_recvspace 131072 rfc1323 1"
            # has keys tcp_sendspace, tcp_recvspace, and rfc1323
            line.split.each_slice(2) do |key, value|
              ifaces[int_name][key] = value
            end
          end
        end
      end

      # Query macaddress
      shell_out("entstat -d #{int_name}").stdout =~ /Hardware Address: (\S+)/
      if $1
        ifaces[int_name][:addresses][$1.upcase] = { "family" => "lladdr" }
        macaddress $1.upcase unless shell_out("uname -W").stdout.to_i > 0
      end
    end # ifconfig stdout

    # Query routes information
    %w{inet inet6}.each do |family|
      shell_out("netstat -nrf #{family}").stdout.each_line do |line|
        if line =~ /(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\S+)/
          interface = $6
          ifaces[interface][:routes] ||= []
          ifaces[interface][:routes] << Mash.new( destination: $1, family: family,
                                                  via: $2, flags: $3)
        end
      end
    end

    # List the arp entries in system.
    count = 0
    network[:arp] ||= Mash.new
    shell_out("arp -an").stdout.each_line do |line|
      if line =~ /\s*(\S+) \((\S+)\) at ([a-fA-F0-9\:]+) \[(\w+)\] stored in bucket/
        network[:arp][count] ||= Mash.new
        network[:arp][count][:remote_host] = $1
        network[:arp][count][:remote_ip] = $2
        network[:arp][count][:remote_mac] = $3.downcase
        count += 1
      end
    end
    network["interfaces"] = ifaces
  end
end
