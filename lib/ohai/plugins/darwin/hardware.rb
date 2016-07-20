#
# Author:: Nate Walck (<nate.walck@gmail.com>)
# Copyright:: Copyright (c) 2016-present Facebook, Inc.
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

Ohai.plugin(:Hardware) do
  provides "hardware"

  def system_profiler(datatype)
    sp_cmd = "system_profiler #{datatype} -xml"
    # Hardware queries
    sp_std = shell_out(sp_cmd)
    sp_hash = Plist.parse_xml(sp_std.stdout)
  end

  collect_data(:darwin) do
    unless hardware
      hardware Mash.new
    else
      Ohai::Log.debug("Plugin Darwin Hardware: namespace already exists")
      next
    end

    begin
      require "plist"
    rescue LoadError => e
      # In case the plist gem isn't present, skip this plugin.
      Ohai::Log.debug("Plugin Hardware: Can't load gem: #{e}. Cannot continue.")
      next
    end

    hw_hash = system_profiler("SPHardwareDataType")
    hw_hash[0]["_items"][0].delete("_name")
    hardware.merge!(hw_hash[0]["_items"][0])

    {
      "operating_system" => "sw_vers -productName",
      "operating_system_version" => "sw_vers -productVersion",
      "build_version" => "sw_vers -buildVersion",
      "architecture" => "uname -m",
    }.each do |var, cmd|
      os_info = shell_out(cmd).stdout
      hardware[var] = os_info.strip unless os_info.nil?
    end

    # Storage queries
    storage = []
    storage_hash = system_profiler("SPStorageDataType")
    drives = storage_hash[0]["_items"]
    drives.each do |drive_entry|
      drive = Mash.new
      drive[:name] = drive_entry["_name"]
      drive[:bsd_name] = drive_entry["bsd_name"]
      drive[:capacity] = drive_entry["size_in_bytes"]
      if drive_entry.has_key?("com.apple.corestorage.pv")
        drive[:drive_type] = drive_entry["com.apple.corestorage.pv"][0]["medium_type"]
        drive[:smart_status] = drive_entry["com.apple.corestorage.pv"][0]["smart_status"]
        drive[:partitions] = drive_entry["com.apple.corestorage.pv"].count
      end
      storage << drive
    end

    hardware["storage"] = storage

    # Battery queries
    battery_hash = system_profiler("SPPowerDataType")
    power_entries = battery_hash[0]["_items"]
    battery = Mash.new
    power_entries.each do |entry|
      if entry.value?("spbattery_information")
        charge = entry["sppower_battery_charge_info"]
        health = entry["sppower_battery_health_info"]
        battery[:current_capacity] = charge["sppower_battery_current_capacity"]
        battery[:max_capacity] = charge["sppower_battery_max_capacity"]
        battery[:fully_charged] = charge["sppower_battery_fully_charged"].eql?("TRUE")
        battery[:is_charging] = charge["sppower_battery_is_charging"].eql?("TRUE")
        battery[:charge_cycle_count] = health["sppower_battery_cycle_count"]
        battery[:health] = health["sppower_battery_health"]
        battery[:serial] = entry["sppower_battery_model_info"]["sppower_battery_serial_number"]
        battery[:remaining] = (battery["current_capacity"].to_f / battery["max_capacity"].to_f * 100).to_i
      end
    end
    hardware[:battery] = battery
  end
end
