#
# Author:: Benjamin Black (<bb@chef.io>)
# Copyright:: Copyright (c) 2009-2016 Chef Software, Inc.
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

# Note: This plugin requires libvirt-bin/libvirt-dev as well as the ruby-libvirt
#       gem to be installed before it will properly parse data

Ohai.plugin(:Libvirt) do
  %w{ uri capabilities nodeinfo domains networks storage }.each do |info|
    provides "libvirt/#{info}"
    depends "virtualization"
  end

  def emu
    @emu ||= (virtualization[:system].eql?("kvm") ? "qemu" : virtualization[:system])
  end

  def load_libvirt
    require "libvirt" # this is the ruby-libvirt gem not the libvirt gem
    logger.trace("Plugin Libvirt: Successfully loaded ruby-libvirt gem")
  rescue LoadError
    logger.trace("Plugin Libvirt: Can't load gem ruby-libvirt.")
  end

  def virtconn
    @virt_connect ||= Libvirt.open_read_only("#{emu}:///system")
  end

  def get_node_data
    node_data = Mash.new
    ni = virtconn.node_get_info
    %w{cores cpus memory mhz model nodes sockets threads}.each { |a| node_data[a] = ni.send(a) }
    node_data
  end

  def get_domain_data
    domain_data = Mash.new
    virtconn.list_domains.each do |d|
      dv = virtconn.lookup_domain_by_id d
      domain_data[dv.name] = Mash.new
      domain_data[dv.name][:id] = d
      %w{os_type uuid}.each { |a| domain_data[dv.name][a] = dv.send(a) }
      %w{cpu_time max_mem memory nr_virt_cpu state}.each { |a| domain_data[dv.name][a] = dv.info.send(a) }
    end
    domain_data
  end

  def get_network_data
    network_data = Mash.new
    virtconn.list_networks.each do |n|
      nv = virtconn.lookup_network_by_name n
      network_data[n] = Mash.new
      %w{bridge_name uuid}.each { |a| network_data[n][a] = nv.send(a) }
    end
    network_data
  end

  def get_storage_data
    storage_data = Mash.new
    virtconn.list_storage_pools.each do |pool|
      sp = virtconn.lookup_storage_pool_by_name pool
      storage_data[pool] = Mash.new
      %w{autostart uuid}.each { |a| storage_data[pool][a] = sp.send(a) }
      %w{allocation available capacity state}.each { |a| storage_data[pool][a] = sp.info.send(a) }

      storage_data[pool][:volumes] = Mash.new
      sp.list_volumes.each do |v|
        storage_data[pool][:volumes][v] = Mash.new
        sv = sp.lookup_volume_by_name v
        %w{key name path}.each { |a| storage_data[pool][:volumes][v][a] = sv.send(a) }
        %w{allocation capacity type}.each { |a| storage_data[pool][:volumes][v][a] = sv.info.send(a) }
      end
    end
    storage_data
  end

  collect_data do
    if virtualization[:role].eql?("host")
      load_libvirt
      begin
        libvirt_data = Mash.new
        libvirt_data[:uri] = virtconn.uri
        libvirt_data[:libvirt_version] = Libvirt.version(emu)[0].to_s
        libvirt_data[:nodeinfo] = get_node_data
        libvirt_data[:domains] = get_domain_data
        libvirt_data[:networks] = get_network_data
        libvirt_data[:storage] = get_storage_data
        virtconn.close
        libvirt libvirt_data
      rescue NameError
        logger.trace("Plugin Libvirt: Cannot load ruby-libvirt gem. Skipping...")
      rescue Libvirt::ConnectionError
        logger.trace("Plugin Libvirt: Failed to connect to #{emu}:///system. Skipping...")
      end
    else
      logger.trace("Plugin Libvirt: Node is not a virtualization host. Skipping...")
    end
  end
end
