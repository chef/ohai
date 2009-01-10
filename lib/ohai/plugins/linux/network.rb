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

def encaps_lookup(encap)
  return "Loopback" if encap.eql?("Local Loopback")
  return "PPP" if encap.eql?("Point-to-Point Protocol")
  return "SLIP" if encap.eql?("Serial Line IP")
  return "VJSLIP" if encap.eql?("VJ Serial Line IP")
  return "IPIP" if encap.eql?("IPIP Tunnel")
  return "6to4" if encap.eql?("IPv6-in-IPv4")
  encap
end

network["interfaces"] = Array.new

iface = Mash.new
popen4("/sbin/ifconfig -a") do |pid, stdin, stdout, stderr|
  stdin.close
  cint = nil
  stdout.each do |line|
    if line =~ /^([[:alnum:]|\:|\-]+)/
      cint = $1
      network["interfaces"].push(cint)
      iface[cint] = Mash.new
      if cint =~ /^(\w+)(\d+.*)/
        iface[cint]["type"] = $1
        iface[cint]["number"] = $2
      end
    end
    if line =~ /Link encap:(Local Loopback)/ || line =~ /Link encap:(.+?)\s/
      iface[cint]["encapsulation"] = encaps_lookup($1)
    end
    if line =~ /HWaddr (.+?)\s/
      iface[cint]["addresses"] << { "family" => "lladdr", "address" => $1 }
    end
    if line =~ /inet addr:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
      iface[cint]["addresses"] << { "family" => "inet", "address" => $1 }
    end
    if line =~ /inet6 addr: ([a-f0-9\:]+)\/(\d+) Scope:(\w+)/
      iface[cint]["addresses"] << { "family" => "inet6", "address" => $1, "prefixlen" => $2, "scope" => ("Node" if $3.eql?("Host") else $3) }
    end
    if line =~ /Bcast:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
      iface[cint]["addresses"].last["broadcast"] = $1
    end
    if line =~ /Mask:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
      iface[cint]["addresses"].last["netmask"] = $1
    end
    flags = line.scan(/(UP|BROADCAST|DEBUG|LOOPBACK|POINTTOPOINT|NOTRAILERS|RUNNING|NOARP|PROMISC|ALLMULTI|SLAVE|MASTER|MULTICAST|DYNAMIC)\s/)
    if flags.length > 1
      iface[cint]["flags"] = flags.flatten
    end
    if line =~ /MTU:(\d+)/
      iface[cint]["mtu"] = $1
    end
    if line =~ /RX packets:(\d+) errors:(\d+) dropped:(\d+) overruns:(\d+) frame:(\d+)/
      iface[cint]["counters"]["rx_packets"] = $1
      iface[cint]["counters"]["rx_errors"] = $2
      iface[cint]["counters"]["rx_dropped"] = $3
      iface[cint]["counters"]["rx_overruns"] = $4
      iface[cint]["counters"]["rx_frame"] = $5
    end
    if line =~ /TX packets:(\d+) errors:(\d+) dropped:(\d+) overruns:(\d+) carrier:(\d+)/
      iface[cint]["counters"]["tx_packets"] = $1
      iface[cint]["counters"]["tx_errors"] = $2
      iface[cint]["counters"]["tx_dropped"] = $3
      iface[cint]["counters"]["tx_overruns"] = $4
      iface[cint]["counters"]["tx_carrier"] = $5
    end
    if line =~ /collisions:(\d+)/
      iface[cint]["counters"]['collisions'] = $1
    end
    if line =~ /txqueuelen:(\d+)/
      iface[cint]["counters"]['txqueuelen'] = $1
    end
    if line =~ /RX bytes:(\d+) \((\d+?\.\d+ .+?)\)/
      iface[cint]["counters"]["rx_bytes"] = $1
      iface[cint]["counters"]["rx_bytes_human"] = $2
    end
    if line =~ /TX bytes:(\d+) \((\d+?\.\d+ .+?)\)/
      iface[cint]["counters"]["rx_bytes"] = $1
      iface[cint]["counters"]["rx_bytes_human"] = $2
    end
  end
end

network["interfaces"] = iface
