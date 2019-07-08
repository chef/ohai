#
# Author:: Joerg Herzinger <joerg.herzinger@oiml.at>
# Author:: Phil Dibowitz <phil@ipom.com>
# Copyright:: Copyright (c) 2011 GLOBAL 2000/Friends of the Earth Austria
# Copyright:: Copyright (c) 2017 Facebook, Inc.
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

Ohai.plugin(:Lspci) do
  depends "platform"
  provides "pci"
  optional true

  collect_data(:linux) do
    devices = Mash.new
    lspci = shell_out("lspci -vnnmk")

    h = /[0-9a-fA-F]/ # any hex digit
    hh = /#{h}#{h}/ # any 2 hex digits
    hhhh = /#{h}#{h}#{h}#{h}/ # any 4 hex digits

    d_id = "" # This identifies our pci devices

    def standard_form(devices, d_id, hhhh, tag, line)
      tmp = line.scan(/(.*)\s\[(#{hhhh})\]/)[0]
      devices[d_id]["#{tag}_name"] = tmp[0]
      devices[d_id]["#{tag}_id"] = tmp[1]
    end

    def standard_array(devices, d_id, tag, line)
      if !devices[d_id][tag].is_a?(Array)
        devices[d_id][tag] = [line]
      else
        devices[d_id][tag].push(line)
      end
    end

    lspci.stdout.split("\n").each do |line|
      dev = line.scan(/^(.*):\s(.*)$/)[0]
      next if dev.nil?

      case dev[0]
      when "Device" # There are two different Device tags
        if ( tmp = dev[1].match(/(#{hh}:#{hh}.#{h})/) )
          # We have a device id
          d_id = tmp[0] # From now on we will need this id
          devices[d_id] = Mash.new
        else
          standard_form(devices, d_id, hhhh, "device", dev[1])
        end
      when "Class"
        standard_form(devices, d_id, hhhh, "class", dev[1])
      when "Vendor"
        standard_form(devices, d_id, hhhh, "vendor", dev[1])
      when "Driver"
        standard_array(devices, d_id, "driver", dev[1])
      when "Module"
        standard_array(devices, d_id, "module", dev[1])
      when "SDevice"
        standard_form(devices, d_id, hhhh, "sdevice", dev[1])
      end
    end

    pci devices
  end
end
