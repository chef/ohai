#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

iface = Mash.new
popen4("/sbin/ifconfig -a") do |pid, stdin, stdout, stderr|
  stdin.close
  cint = nil
  stdout.each do |line|
    if line =~ /^([[:alnum:]|\:|\-]+)/
      cint = $1
      network_interfaces.push(cint)
      iface[cint] = Mash.new
    end
    if line =~ /Link encap:(Local Loopback)/ || line =~ /Link encap:(.+?)\s/
      iface[cint]["link_encap"] = $1
    end
    if line =~ /HWaddr (.+?)\s/
      iface[cint]["macaddress"] = $1
    end
    if line =~ /inet addr:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
      iface[cint]["ipaddress"] = $1
    end
    if line =~ /Bcast:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
      iface[cint]["broadcast"] = $1
    end
    if line =~ /Mask:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
      iface[cint]["netmask"] = $1
    end
    flags = line.scan(/(UP|BROADCAST|DEBUG|LOOPBACK|POINTTOPOINT|NOTRAILERS|RUNNING|NOARP|PROMISC|ALLMULTI|SLAVE|MASTER|MULTICAST|DYNAMIC)\s/)
    if flags.length > 1
      iface[cint]["flags"] = flags.flatten
    end
    if line =~ /MTU:(\d+)/
      iface[cint]["mtu"] = $1
    end
    if line =~ /Metric:(\d+)/
      iface[cint]["metric"] = $1
    end
    if line =~ /RX packets:(\d+) errors:(\d+) dropped:(\d+) overruns:(\d+) frame:(\d+)/
      iface[cint]["rx_packets"] = $1
      iface[cint]["rx_errors"] = $2
      iface[cint]["rx_dropped"] = $3
      iface[cint]["rx_overruns"] = $4
      iface[cint]["rx_frame"] = $5
    end
    if line =~ /TX packets:(\d+) errors:(\d+) dropped:(\d+) overruns:(\d+) carrier:(\d+)/
      iface[cint]["tx_packets"] = $1
      iface[cint]["tx_errors"] = $2
      iface[cint]["tx_dropped"] = $3
      iface[cint]["tx_overruns"] = $4
      iface[cint]["tx_carrier"] = $5
    end
    if line =~ /collisions:(\d+)/
      iface[cint]['collisions'] = $1
    end
    if line =~ /txqueuelen:(\d+)/
      iface[cint]['txqueuelen'] = $1
    end
    if line =~ /RX bytes:(\d+) \((\d+?\.\d+ .+?)\)/
      iface[cint]["rx_bytes"] = $1
      iface[cint]["rx_bytes_human"] = $2
    end
    if line =~ /TX bytes:(\d+) \((\d+?\.\d+ .+?)\)/
      iface[cint]["rx_bytes"] = $1
      iface[cint]["rx_bytes_human"] = $2
    end
  end
end

network_interface iface
