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

Ohai.plugin(:LibVirt) do
  %w{ uri capabilities nodeinfo domains networks storage }.each do |info|
    provides "libvirt/#{info}"
  end

  collect_data do
    if virtualization[:role].eql?("host")
      begin
        require "libvirt" # this is the ruby-libvirt gem not the libvirt gem

        libvirt Mash.new
        emu = (virtualization[:system].eql?("kvm") ? "qemu" : libvirt[:system])
        libvirt[:libvirt_version] = Libvirt.version(emu)[0].to_s

        virtconn = Libvirt.open_read_only("#{emu}:///system")

        libvirt[:uri] = virtconn.uri
        libvirt[:capabilities] = Mash.new

        libvirt[:nodeinfo] = Mash.new
        ni = virtconn.node_get_info
        %w{cores cpus memory mhz model nodes sockets threads}.each { |a| libvirt[:nodeinfo][a] = ni.send(a) }

        libvirt[:domains] = Mash.new
        virtconn.list_domains.each do |d|
          dv = virtconn.lookup_domain_by_id d
          libvirt[:domains][dv.name] = Mash.new
          libvirt[:domains][dv.name][:id] = d
          %w{os_type uuid}.each { |a| libvirt[:domains][dv.name][a] = dv.send(a) }
          %w{cpu_time max_mem memory nr_virt_cpu state}.each { |a| libvirt[:domains][dv.name][a] = dv.info.send(a) }

        end

        libvirt[:networks] = Mash.new
        virtconn.list_networks.each do |n|
          nv = virtconn.lookup_network_by_name n
          libvirt[:networks][n] = Mash.new
          %w{bridge_name uuid}.each { |a| libvirt[:networks][n][a] = nv.send(a) }
        end

        libvirt[:storage] = Mash.new
        virtconn.list_storage_pools.each do |pool|
          sp = virtconn.lookup_storage_pool_by_name pool
          libvirt[:storage][pool] = Mash.new
          %w{autostart uuid}.each { |a| libvirt[:storage][pool][a] = sp.send(a) }
          %w{allocation available capacity state}.each { |a| libvirt[:storage][pool][a] = sp.info.send(a) }

          libvirt[:storage][pool][:volumes] = Mash.new
          sp.list_volumes.each do |v|
            libvirt[:storage][pool][:volumes][v] = Mash.new
            sv = sp.lookup_volume_by_name v
            %w{key name path}.each { |a| libvirt[:storage][pool][:volumes][v][a] = sv.send(a) }
            %w{allocation capacity type}.each { |a| libvirt[:storage][pool][:volumes][v][a] = sv.info.send(a) }
          end
        end

        virtconn.close
      rescue LoadError => e
        Ohai::Log.debug("Plugin LibVirt: Can't load gem ruby-libvirt. Cannot continue.")
      end
    end
  end
end
