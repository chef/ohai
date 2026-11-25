# frozen_string_literal: true
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

  # Query several data types from one system_profiler process. Each run has
  # a fixed startup cost of a few hundred milliseconds, so one call for all
  # of them is much faster than one call per type.
  #
  # @return [Hash] the "_items" of each data type, keyed by data type
  def system_profiler(*datatypes)
    sp_std = shell_out("system_profiler #{datatypes.join(" ")} -xml")
    Plist.parse_xml(sp_std.stdout).to_h { |entry| [entry["_dataType"], entry["_items"]] }
  end

  collect_data(:darwin) do
    unless hardware
      hardware Mash.new
    else
      logger.trace("Plugin Hardware: namespace already exists")
      next
    end

    require "plist"

    profile = system_profiler("SPHardwareDataType", "SPStorageDataType", "SPPowerDataType")

    hw_items = profile["SPHardwareDataType"][0]
    hw_items.delete("_name")
    hardware.merge!(hw_items)

    # ProductName:	Mac OS X
    # ProductVersion:	10.15.6
    # BuildVersion:	19G46c
    shell_out("sw_vers").stdout.lines.each do |line|
      case line
      when /^ProductName:\s*(.*)$/
        hardware["operating_system"] = Regexp.last_match[1].strip
      when /^ProductVersion:\s*(.*)$/
        hardware["operating_system_version"] = Regexp.last_match[1].strip
      when /^BuildVersion:\s*(.*)$/
        hardware["build_version"] = Regexp.last_match[1].strip
      end
    end

    hardware["architecture"] = shell_out("uname -m").stdout.strip

    # Storage queries
    storage = []
    drives = profile["SPStorageDataType"]
    drives.each do |drive_entry|
      drive = Mash.new
      drive[:name] = drive_entry["_name"]
      drive[:bsd_name] = drive_entry["bsd_name"]
      drive[:capacity] = drive_entry["size_in_bytes"]
      if drive_entry.key?("com.apple.corestorage.pv")
        drive[:drive_type] = drive_entry["com.apple.corestorage.pv"][0]["medium_type"]
        drive[:smart_status] = drive_entry["com.apple.corestorage.pv"][0]["smart_status"]
        drive[:partitions] = drive_entry["com.apple.corestorage.pv"].count
      elsif drive_entry.key?("physical_drive")
        # APFS volumes (macOS 10.13 and later) describe their disk here.
        # Disk images and some virtual disks have no medium_type or
        # smart_status, so those keys are only set when present.
        physical_drive = drive_entry["physical_drive"]
        drive[:drive_type] = physical_drive["medium_type"] if physical_drive.key?("medium_type")
        drive[:smart_status] = physical_drive["smart_status"] if physical_drive.key?("smart_status")
      end
      storage << drive
    end

    hardware["storage"] = storage

    # Battery queries
    power_entries = profile["SPPowerDataType"]
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
