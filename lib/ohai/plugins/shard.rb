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

Ohai.plugin(:ShardSeed) do
  depends "hostname", "dmi", "machine_id", "machinename", "fips", "hardware", "kernel"
  provides "shard_seed"

  def get_dmi_property(dmi, thing)
    %w{system base_board chassis}.each do |section|
      unless dmi[section][thing].strip.empty?
        return dmi[section][thing]
      end
    end
  end

  def default_sources
    case collect_os
    when "linux", "darwin", "windows"
      %i{machinename serial uuid}
    else
      [:machinename]
    end
  end

  def default_digest_algorithm
    if fips && fips["kernel"]["enabled"]
      # Even though it is being used safely, FIPS-mode will still blow up on
      # any use of MD5 so default to SHA2 instead.
      "sha256"
    else
      "md5"
    end
  end

  def digest_algorithm
    case Ohai.config[:plugin][:shard_seed][:digest_algorithm] || default_digest_algorithm
    when "md5"
      require "digest/md5"
      Digest::MD5
    when "sha256"
      require "openssl/digest"
      OpenSSL::Digest::SHA256
    end
  end

  # Common sources go here. Put sources that need to be different per-platform
  # under their collect_data block.
  def create_seed(&block)
    sources = Ohai.config[:plugin][:shard_seed][:sources] || default_sources
    data = ""
    sources.each do |src|
      data << case src
              when :fqdn
                fqdn
              when :hostname
                hostname
              when :machine_id
                machine_id
              when :machinename
                machinename
              else
                yield(src)
              end
    end
    shard_seed digest_algorithm.hexdigest(data)[0...7].to_i(16)
  end

  collect_data do
    create_seed do |src|
      raise "No such shard_seed source: #{src}"
    end
  end

  collect_data(:windows) do
    require "wmi-lite/wmi"
    wmi = WmiLite::Wmi.new

    create_seed do |src|
      case src
      when :serial
        wmi.first_of("Win32_BIOS")["SerialNumber"]
      when :os_serial
        kernel["os_info"]["serial_number"]
      when :uuid
        wmi.first_of("Win32_ComputerSystemProduct")["UUID"]
      else
        raise "No such shard_seed source: #{src}"
      end
    end
  end

  collect_data(:darwin) do
    create_seed do |src|
      case src
      when :serial
        hardware["serial_number"]
      when :uuid
        hardware["platform_UUID"]
      else
        raise "No such shard_seed source: #{src}"
      end
    end
  end

  collect_data(:linux) do
    create_seed do |src|
      case src
      when :serial
        get_dmi_property(dmi, :serial_number)
      when :uuid
        get_dmi_property(dmi, :uuid)
      else
        raise "No such shard_seed source: #{src}"
      end
    end
  end
end
