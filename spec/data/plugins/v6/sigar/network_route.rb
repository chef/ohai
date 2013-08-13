#
# Author:: Toomas Pelberg (<toomas.pelberg@playtech.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require "sigar"
require_plugin "network"

provides "network"

def flags(flags)
  f = ""
  if (flags & Sigar::RTF_UP) != 0
    f += "U"
  end
  if (flags & Sigar::RTF_GATEWAY) != 0
    f += "G"
  end
  if (flags & Sigar::RTF_HOST) != 0
    f += "H"
  end
  f
end

# From sigar: include/sigar.h sigar_net_route_t
SIGAR_ROUTE_METHODS = [:destination, :gateway, :mask, :flags, :refcnt, :use, :metric, :mtu, :window, :irtt, :ifname]

sigar=Sigar.new
sigar.net_route_list.each do |route|
  next unless network[:interfaces][route.ifname] # this should never happen
  network[:interfaces][route.ifname][:route] = Mash.new unless network[:interfaces][route.ifname][:route]
  route_data={}
  SIGAR_ROUTE_METHODS.each do |m|
    if(m == :flags)
      route_data[m]=flags(route.send(m))
    else
      route_data[m]=route.send(m)
    end
  end
  network[:interfaces][route.ifname][:route][route.destination] = route_data
end
