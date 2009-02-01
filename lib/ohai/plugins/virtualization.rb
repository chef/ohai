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

  system = (virtualization[:system].eql?('kvm') ? 'qemu' : virtualization[:system])
  virtualization[:libvirt_version] = Libvirt::version(system)[0].to_s
  
  virtconn = Libvirt::open("#{system}:///system")

  virtualization[:uri] = virtconn.uri
  virtualization[:capabilities] = virtconn.capabilities
  virtualization[:nodeinfo] = Mash.new
  ni = virtconn.node_get_info
  ['cores','cpus','memory','mhz','model','nodes','sockets','threads'].each {|a| virtualization[:nodeinfo][a] = ni.send(a)}

  virtualization[:domains] = Mash.new
  virtconn.list_domains.each do |d|
    dv = virtconn.lookup_domain_by_id(d)
    virtualization[:domains][dv.name] = Mash.new
    virtualization[:domains][dv.name][:id] = d
    ['os_type','uuid','xml_spec'].each {|a| virtualization[:domains][dv.name][a] = dv.send(a)}
    ['cpu_time','max_mem','memory','nr_virt_cpu','state'].each {|a| virtualization[:domains][dv.name][a] = dv.info.send(a)}
  end
  
  virtualization[:networks] = Mash.new
  virtconn.list_networks.each do |n|
    nv = virtconn.lookup_network_by_name(n)
    virtualization[:networks][n] = Mash.new
    virtualization[:networks][n][:bridge] = nv.bridge_name
    virtualization[:networks][n][:xml_desc] = nv.xml_desc
  end
  
  virtualization[:storage] = Mash.new
  virtconn.list_storage_pools.each do |pool|
    sp = virtconn.lookup_storage_pool_by_name(pool)
    virtualization[:storage][pool] = Mash.new
    ['autostart','uuid','xml_desc'].each {|a| virtualization[:storage][pool][a] = sp.send(a)}
    ['allocation','available','capacity','state'].each {|a| virtualization[:storage][pool][a] = sp.info.send(a)}
    
    virtualization[:storage][pool][:volumes] = Mash.new
    sp.list_volumes.each do |v|
      virtualization[:storage][pool][:volumes][v] = Mash.new
      sv = virtconn.lookup_volume_by_name(pool)
      ['key','name','path'].each {|a| virtualization[:storage][pool][:volumes][v][a] = sv.send(a)}
      ['allocation','capacity','type'].each {|a| virtualization[:storage][pool][:volumes][v][a] = sv.info.send(a)}
    end
  end
  
  virtconn.close
end
