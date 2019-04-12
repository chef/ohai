#
# Copyright:: Copyright (c) 2015 Chef Software
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

Ohai.plugin(:Drivers) do
  provides "kernel/pnp_drivers", "kernel/modules"
  depends "kernel"

  collect_data(:windows) do
    if configuration(:enabled)

      kext = Mash.new
      pnp_drivers = Mash.new

      drivers_cmd = 'Get-WmiObject Win32_PnPSignedDriver | ForEach-Object { $adptr = $_ ; $adptr.Properties | ForEach-Object { Write-Host "$($adptr.DeviceID),$($adptr.DeviceName),$($_.Name),$($_.Type),$($_.Value)" } }'
      drivers = shell_out(drivers_cmd).stdout

      drivers.lines.each do |line|
        device_id, device_name, property_name, property_type, property_value = line.strip.split(',',5)
        pnp_drivers[device_id] ||= Mash.new

        property_value = true if property_type == 'Boolean' && property_value == 'True'
        property_value = false if property_type == 'Boolean' && property_value == 'False'
        property_value = property_value.to_i if property_type =~ /UInt(?:64|32|16|8)/ && !property_value.nil?
        property_value = nil if property_type == 'String' && property_value.to_s.strip == ''
        pnp_drivers[device_id][property_name.wmi_underscore.to_sym] = property_value

        if device_name
          kext[device_name] = pnp_drivers[device_id]
          kext[device_name][:version] = pnp_drivers[device_id][:driver_version]
          kext[device_name][:date] = pnp_drivers[device_id][:driver_date] ? pnp_drivers[device_id][:driver_date].to_s[0..7] : nil
        end        
      end

      kernel[:pnp_drivers] = pnp_drivers
      kernel[:modules] = kext

    end
  end

end
