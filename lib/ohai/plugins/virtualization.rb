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

# Note: despite the name this is really a libvirt plugin.
#       perhaps we'd be better off renaming it? -tsmith

Ohai.plugin(:VirtualizationInfo) do
  %w{ uri capabilities nodeinfo domains networks storage }.each do |info|
    provides "virtualization/#{info}"
  end

  collect_data do
    unless virtualization.nil? || !(virtualization[:role].eql?("host"))
      begin
        require "libvirt" # this is the ruby-libvirt gem not the libvirt gem

        emu = (virtualization[:system].eql?("kvm") ? "qemu" : virtualization[:system])
        virtualization[:libvirt_version] = Libvirt.version(emu)[0].to_s

        virtconn = Libvirt.open_read_only("#{emu}:///system")

        virtualization[:uri] = virtconn.uri
        virtualization[:capabilities] = Mash.new

        virtualization[:nodeinfo] = Mash.new
        ni = virtconn.node_get_info
        %w{cores cpus memory mhz model nodes sockets threads}.each { |a| virtualization[:nodeinfo][a] = ni.send(a) }

        virtualization[:domains] = Mash.new
        virtconn.list_domains.each do |d|
          dv = virtconn.lookup_domain_by_id d
          virtualization[:domains][dv.name] = Mash.new
          virtualization[:domains][dv.name][:id] = d
          %w{os_type uuid}.each { |a| virtualization[:domains][dv.name][a] = dv.send(a) }
          %w{cpu_time max_mem memory nr_virt_cpu state}.each { |a| virtualization[:domains][dv.name][a] = dv.info.send(a) }

        end

        virtualization[:networks] = Mash.new
        virtconn.list_networks.each do |n|
          nv = virtconn.lookup_network_by_name n
          virtualization[:networks][n] = Mash.new
          %w{bridge_name uuid}.each { |a| virtualization[:networks][n][a] = nv.send(a) }
        end

        virtualization[:storage] = Mash.new
        virtconn.list_storage_pools.each do |pool|
          sp = virtconn.lookup_storage_pool_by_name pool
          virtualization[:storage][pool] = Mash.new
          %w{autostart uuid}.each { |a| virtualization[:storage][pool][a] = sp.send(a) }
          %w{allocation available capacity state}.each { |a| virtualization[:storage][pool][a] = sp.info.send(a) }

          virtualization[:storage][pool][:volumes] = Mash.new
          sp.list_volumes.each do |v|
            virtualization[:storage][pool][:volumes][v] = Mash.new
            sv = sp.lookup_volume_by_name v
            %w{key name path}.each { |a| virtualization[:storage][pool][:volumes][v][a] = sv.send(a) }
            %w{allocation capacity type}.each { |a| virtualization[:storage][pool][:volumes][v][a] = sv.info.send(a) }
          end
        end

        virtconn.close
      rescue LoadError => e
        Ohai::Log.debug("Plugin Virtualization: Can't load gem: #{e}. Cannot continue.")
      end
    end
  end
end
