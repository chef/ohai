#
# Author:: Benjamin Black (<bb@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require_plugin "#{os}::virtualization"

unless virtualization.nil? || !(virtualization[:role].eql?("host"))
  require 'libvirt'
  
  virtconn = Libvirt::open() # connect to default hypervisor
  virtualization[:capabilities] = virtconn.capabilities
  virtualization[:nodeinfo] = virtconn.nodeinfo
  virtualization[:domains] = virtconn.list_domains.collect {|d| virtconn.lookup_domain_by_id(d)}
  virtualization[:networks] = virtconn.list_networks.collect {|n| virtconn.lookup_network_by_name(n)}
  virtualization[:storage] = Mash.new; virtualization[:storage][:pools] = Mash.new
  virtconn.list_storage_pools.each do |pool| 
    virtualization[:storage][:pools][pool] = Mash.new
    virtualization[:storage][:pools][pool][:info] = virtconn.lookup_storage_pool_by_name(pool).info
    virtualization[:storage][:pools][pool][:volumes] = virtconn.list_volumes.collect {|v| virtconn.list_volume_by_name(pool).info}
  end
  virtconn.close
end
