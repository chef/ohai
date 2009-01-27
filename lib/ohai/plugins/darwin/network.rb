#
# Author:: Benjamin Black (<nostromo@gmail.com>)
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

require 'scanf'

def parse_media(media_string)
  media = Array.new
  line_array = media_string.split(' ')

  0.upto(line_array.length - 1) do |i|
    unless line_array[i].eql?("none")
      if line_array[i + 1] =~ /^\<([a-zA-Z\-\,]+)\>$/
        media << { line_array[i] => { "options" => $1.split(',') }}
      else
        media << { "autoselect" => { "options" => [] } } if line_array[i].eql?("autoselect")
      end
    else
      media << { "none" => { "options" => [] } }
    end
  end

  media
end

def encaps_lookup(ifname)
  return "Loopback" if ifname.eql?("lo")
  return "1394" if ifname.eql?("fw")
  return "IPIP" if ifname.eql?("gif")
  return "6to4" if ifname.eql?("stf")
  return "dot1q" if ifname.eql?("vlan")
  "Unknown"
end

def scope_lookup(scope)
  return "Link" if scope.match(/^fe80\:/)
  return "Site" if scope.match(/^fec0\:/)
  "Global"
end

def excluded_setting?(setting)
  setting.match('_sw_cksum')
end

iface = Mash.new
popen4("ifconfig -a") do |pid, stdin, stdout, stderr|
  stdin.close
  cint = nil
  stdout.each do |line|
    if line =~ /^([0-9a-zA-Z\.\:\-]+): \S+ mtu (\d+)$/
      cint = $1
      iface[cint] = Mash.new
      iface[cint]["mtu"] = $2
      if line =~ /\sflags\=\d+\<((UP|BROADCAST|DEBUG|SMART|SIMPLEX|LOOPBACK|POINTOPOINT|NOTRAILERS|RUNNING|NOARP|PROMISC|ALLMULTI|SLAVE|MASTER|MULTICAST|DYNAMIC|,)+)\>\s/
        flags = $1.split(',')
      else
        flags = Array.new
      end
      iface[cint]["flags"] = flags.flatten
      if cint =~ /^(\w+)(\d+.*)/
        iface[cint]["type"] = $1
        iface[cint]["number"] = $2
        iface[cint]["encapsulation"] = encaps_lookup($1)
      end
    end
    if line =~ /^\s+ether ([0-9a-f\:]+)\s/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "lladdr", "address" => $1 }
      iface[cint]["encapsulation"] = "Ethernet"
    end
    if line =~ /^\s+lladdr ([0-9a-f\:]+)\s/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "lladdr", "address" => $1 }
    end
    if line =~ /\s+inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) netmask 0x(([0-9a-f]){1,8})\s*$/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "inet", "address" => $1, "netmask" => $2.scanf('%2x'*4)*"."}
    end
    if line =~ /\s+inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) netmask 0x(([0-9a-f]){1,8}) broadcast (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "inet", "address" => $1, "netmask" => $2.scanf('%2x'*4)*".", "broadcast" => $4 }
    end
    if line =~ /\s+inet6 ([a-f0-9\:]+)(\s*|(\%[a-z0-9]+)\s*) prefixlen (\d+)\s*$/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "inet6", "address" => $1, "prefixlen" => $4 , "scope" => "Node" }
    end
    if line =~ /\s+inet6 ([a-f0-9\:]+)(\s*|(\%[a-z0-9]+)\s*) prefixlen (\d+) scopeid 0x([a-f0-9]+)/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "inet6", "address" => $1, "prefixlen" => $4 , "scope" => scope_lookup($1) }
    end
    if line =~ /^\s+media: ((\w+)|(\w+ [a-zA-Z0-9\-\<\>]+)) status: (\w+)/
      iface[cint]["media"] = Mash.new unless iface[cint]["media"]
      iface[cint]["media"]["selected"] = parse_media($1)
      iface[cint]["status"] = $4
    end
    if line =~ /^\s+supported media: (.*)/
      iface[cint]["media"] = Mash.new unless iface[cint]["media"]
      iface[cint]["media"]["supported"] = parse_media($1)
    end
  end
end

popen4("/usr/sbin/arp -an") do |pid, stdin, stdout, stderr|
  stdin.close
  stdout.each do |line|
    if line =~ /^\S+ \((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\) at ([a-fA-F0-9\:]+) on ([a-zA-Z0-9\.\:\-]+) \[(\w+)\]/
      # MAC addr really should be normalized to include all the zeroes.
      next unless iface[$3] # this should never happen
      iface[$3][:arp] = Mash.new unless iface[$3][:arp]
      iface[$3][:arp][$1] = $2
    end
  end
end

settings = Mash.new
popen4("/usr/sbin/sysctl net") do |pid, stdin, stdout, stderr|
  stdin.close
  stdout.each do |line|
    if line =~ /^([a-zA-Z0-9\.\_]+)\: (.*)/
      # should normalize names between platforms for the same settings.
      settings[$1] = $2 unless excluded_setting?($1)
    end
  end
end

popen4("/usr/sbin/netstat -i -d -l -b") do |pid, stdin, stdout, stderr|
  stdin.close
  stdout.each do |line|
    if line =~ /^([a-zA-Z0-9\.\:\-]+)\s+\d+\s+\<[a-zA-Z0-9\#]+\>\s+[a-f0-9\:]+\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/
      iface[$1] = Mash.new unless iface[$1]
      iface[$1][:counters] = Mash.new unless iface[$1][:counters]
      iface[$1][:counters] = { :rx => { :bytes => $4, :packets => $2, :errors => $3, :drop => 0, :overrun => 0, :frame => 0, :compressed => 0, :multicast => 0 },
                               :tx => { :bytes => $7, :packets => $5, :errors => $6, :drop => 0, :overrun => 0, :collisions => $8, :carrier => 0, :compressed => 0 }
                             }
    end
  end
end

network[:settings] = settings
network[:interfaces] = iface
