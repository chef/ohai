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

# wow, this is ugly!
def parse_medium(medium)
  m_array = medium.split(' ')
  medium = { m_array[0] => { "options" => [] }}
  if m_array.length > 1
    if m_array[1] =~ /^\<([a-zA-Z\-\,]+)\>/
      medium[m_array[0]]["options"] = $1.split(',')
    end
  end

  medium
end

def parse_media(media_string)
  media = Array.new
  line_array = media_string.split(' ')

  0.upto(line_array.length - 1) do |i|
    unless line_array[i].eql?("none")
      if line_array[i + 1] =~ /^\<([a-zA-Z\-\,]+)\>/
        media << parse_medium(line_array[i,i + 1].join(' '))
      else
        media << { "autoselect" => { "options" => [] } } if line_array[i].eql?("autoselect")
        next
      end
    else
      media << { "none" => { "options" => [] } }
    end
  end

  media
end

def encaps_lookup(ifname)
  return "Loopback" if ifname.eql?("lo")
  return "Ethernet" if ifname.eql?("en")
  return "1394" if ifname.eql?("fw")
  return "IPIP" if ifname.eql?("gif")
  return "6to4" if ifname.eql?("stf")
  return "dot1q" if ifname.eql?("vlan")
end

def scope_lookup(scope)
  return "Link" if scope.match(/^fe80\:/)
  return "Global"
end

network_interfaces(Array.new)

iface = Mash.new
popen4("/sbin/ifconfig -a") do |pid, stdin, stdout, stderr|
  stdin.close
  cint = nil
  stdout.each do |line|
    if line =~ /^([[:alnum:]|\:|\-]+) \S+ mtu (\d+)$/
      cint = $1.chop
      network_interfaces.push(cint)
      iface[cint] = Mash.new
      iface[cint]["mtu"] = $2
      if line =~ /flags\=\d+\<((UP|BROADCAST|DEBUG|SMART|SIMPLEX|LOOPBACK|POINTOPOINT|NOTRAILERS|RUNNING|NOARP|PROMISC|ALLMULTI|SLAVE|MASTER|MULTICAST|DYNAMIC|,)+)\>\s/
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
    if line =~ /^\s+ether (.+?)\s/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "lladdr", "address" => $1 }
      iface[cint]["encapsulation"] = "Ethernet"
    end
    if line =~ /^\s+lladdr (.+?)\s/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "lladdr", "address" => $1 }
    end
    if line =~ /\s+inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) netmask 0x(([0-9]|[a-f]){1,8})(\s|(broadcast (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})))/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "inet", "address" => $1, "netmask" => $2.scanf('%2x'*4)*"."}
      iface[cint]["addresses"].last["broadcast"] = $4 if $4.length > 1
    end
    if line =~ /\s+inet6 ([a-f0-9\:]+)(\s*|(\%[a-z0-9]+)\s*) prefixlen (\d+)\s*$/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "inet6", "address" => $1, "prefixlen" => $4 , "scope" => "Node"}
    end
    if line =~ /\s+inet6 ([a-f0-9\:]+)(\s*|(\%[a-z0-9]+)\s*) prefixlen (\d+)\s*scopeid 0x([a-f0-9]+)/
      iface[cint]["addresses"] = Array.new unless iface[cint]["addresses"]
      iface[cint]["addresses"] << { "family" => "inet6", "address" => $1, "prefixlen" => $4 , "scope" => scope_lookup($1) }
    end
    if line =~ /^\s+media: ((\w+)|(\w+ [a-zA-Z0-9\-\<\>]+)) status: (\w+)/
      iface[cint]["media"] = Hash.new unless iface[cint]["media"]
      iface[cint]["media"]["selected"] = parse_medium($1)
      iface[cint]["status"] = $4
    end
    if line =~ /^\s+supported media: (.*)/
      iface[cint]["media"] = Hash.new unless iface[cint]["media"]
      iface[cint]["media"]["supported"] = parse_media($1)
    end
  end
end

network_interface iface
