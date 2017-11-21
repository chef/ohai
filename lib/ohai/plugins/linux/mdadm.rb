#
# Author:: Tim Smith <tsmith@limelight.com>
# Author:: Phil Dibowitz <phild@ipomc.com>
# Copyright:: Copyright (c) 2013-2014, Limelight Networks, Inc.
# Copyright:: Copyright (c) 2017 Facebook, Inc.
# Plugin:: mdadm
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

Ohai.plugin(:Mdadm) do
  provides "mdadm"

  def create_raid_device_mash(stdout)
    device_mash = Mash.new
    device_mash[:device_counts] = Mash.new
    stdout.lines.each do |line|
      case line
      when /Version\s+: ([0-9.]+)/
        device_mash[:version] = Regexp.last_match[1].to_f
      when /Raid Level\s+: raid([0-9]+)/
        device_mash[:level] = Regexp.last_match[1].to_i
      when /Array Size.*\(([0-9.]+)/
        device_mash[:size] = Regexp.last_match[1].to_f
      when /State\s+: ([a-z]+)/
        device_mash[:state] = Regexp.last_match[1]
      when /Total Devices\s+: ([0-9]+)/
        device_mash[:device_counts][:total] = Regexp.last_match[1].to_i
      when /Raid Devices\s+: ([0-9]+)/
        device_mash[:device_counts][:raid] = Regexp.last_match[1].to_i
      when /Working Devices\s+: ([0-9]+)/
        device_mash[:device_counts][:working] = Regexp.last_match[1].to_i
      when /Failed Devices\s+: ([0-9]+)/
        device_mash[:device_counts][:failed] = Regexp.last_match[1].to_i
      when /Active Devices\s+: ([0-9]+)/
        device_mash[:device_counts][:active] = Regexp.last_match[1].to_i
      when /Spare Devices\s+: ([0-9]+)/
        device_mash[:device_counts][:spare] = Regexp.last_match[1].to_i
      end
    end
    device_mash
  end

  collect_data(:linux) do
    # gather a list of all raid arrays
    if File.exist?("/proc/mdstat")
      devices = {}
      File.open("/proc/mdstat").each do |line|
        if line =~ /(md[0-9]+)/
          device = Regexp.last_match[1]
          pieces = line.split(/\s+/)
          # there are variable numbers of fields until you hit the raid level
          # everything after that is members...
          # unless the array is inactive, in which case you don't get a raid
          # level.
          members = pieces.drop_while { |x| !x.start_with?("raid", "inactive") }
          # and drop that too
          members.shift unless members.empty?
          devices[device] = {
            "active" => [],
            "spare" => [],
            "journal" => nil,
          }
          members.each do |member|
            # We want to match the device, and optionally the type
            # most entries will look like:
            #   sdc1[5]
            # but some will look like:
            #   sdc1[5](J)
            # where the format is:
            #   <device>[<number in array>](<type>)
            # Type can be things like "J" for a journal device, or "S" for
            # a spare device.
            m = member.match(/(.+)\[\d+\](?:\((\w)\))?/)
            member_device = m[1]
            member_type = m[2]
            case member_type
            when "J"
              devices[device]["journal"] = member_device
            when "S"
              devices[device]["spare"] << member_device
            else
              devices[device]["active"] << member_device
            end
          end
        end
      end

      # create the mdadm mash and gather individual information if devices are present
      unless devices.empty?
        mdadm Mash.new
        devices.keys.sort.each do |device|
          mdadm[device] = Mash.new

          # gather detailed information on the array
          so = shell_out("mdadm --detail /dev/#{device}")

          # if the mdadm command was sucessful pass so.stdout to create_raid_device_mash to grab the tidbits we want
          mdadm[device] = create_raid_device_mash(so.stdout) if so.stdout
          mdadm[device]["members"] = devices[device]["active"]
          mdadm[device]["spares"] = devices[device]["spare"]
          mdadm[device]["journal"] = devices[device]["journal"]
        end
      end
    end
  end
end
