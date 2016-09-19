#
# Author:: Phil Dibowitz <phil@ipom.com>
# Copyright:: Copyright (c) 2016 Facebook, Inc.
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

require 'digest/md5'

Ohai.plugin(:ShardSeed) do
  depends "hostname", "dmi", "machine_id", "machinename"
  provides "shard_seed"

  def get_dmi_thing(dmi, thing)
    %w{system base_board chassis}.each do |section|
      unless dmi[:thing][thing].compact.empty?
        return dmi[:thing][thing]
      end
    end
  end

  def default_sources
    [:machinename, :serial, :uuid]
  end

  collect_data(:darwin) do
    sources = Ohai.config[:plugin][:shard_seed][:sources] || default_sources
    data = ''
    sources.each do |src|
      data << case src
              when :fqdn
                fqdn
              when :hostname
                hostname
              when :serial
                hardware['serial_number']
              when :uuid
                hardware['platform_UUID']
              when :machine_id
                machine_id
              when :machinename
                machinename
              end
    end
    shard_seed Digest::MD5.hexdigest(data)[0...7].to_i(16)
  end

  collect_data(:linux) do
    sources = Ohai.config[:plugin][:shard_seed][:sources] || default_sources
    data = ''
    sources.each do |src|
      data << case src
              when :fqdn
                fqdn
              when :hostname
                hostname
              when :serial
                get_dmi_thing(dmi, :serial_number)
              when :uuid
                get_dmi_thing(dmi, :uuid)
              when :machine_id
                machine_id
              when :machinename
                machinename
              end
    end
    shard_seed Digest::MD5.hexdigest(data)[0...7].to_i(16)
  end
end
