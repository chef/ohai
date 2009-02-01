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

  virtconn = Libvirt::open("#{(virtualization[:system].eql?('kvm') ? 'qemu' : virtualization[:system])}:///system")

  virtualization[:uri] = virtconn.uri
  virtualization[:capabilities] = virtconn.capabilities
  virtualization[:nodeinfo] = Mash.new
  # why doesn't the NodeInfo object respond to attributes?  argh.
  ['cores','cpus','memory','mhz','model','nodes','sockets','threads'].each {|a| virtualization[:nodeinfo][a] = virtconn.node_get_info.send(a)}

  virtualization[:domains] = Mash.new
  virtconn.list_domains.each do |d|
    virtualization[:domains][d] = virtconn.lookup_domain_by_id(d).info.attributes
    virtualization[:domains][d]["xml_desc"] = virtconn.lookup_domain_by_id(d).xml_desc
  end
  
  virtualization[:networks] = Mash.new
  virtconn.list_networks.each do |n|
    virtualization[:networks][n] = Mash.new
    virtualization[:networks][n]["xml_desc"] = virtconn.lookup_network_by_name(n).xml_desc
    virtualization[:networks][n]["bridge"] = virtconn.lookup_network_by_name(n).bridge_name
  end
  
  virtualization[:storage] = Mash.new
  virtconn.list_storage_pools.each do |pool| 
    virtualization[:storage][pool] = Mash.new
    virtualization[:storage][pool][:info] = virtconn.lookup_storage_pool_by_name(pool).info.attributes
  
    virtualization[:storage][pool][:volumes] = Mash.new
    virtconn.list_volumes.each {|v| virtualization[:storage][pool][:volumes][v] = virtconn.list_volume_by_name(pool).info.attributes}
  end
  
  virtconn.close
end
