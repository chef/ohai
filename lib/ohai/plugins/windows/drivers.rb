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

      require "wmi-lite/wmi"

      kext = Mash.new
      pnp_drivers = Mash.new

      wmi = WmiLite::Wmi.new

      drivers = wmi.instances_of("Win32_PnPSignedDriver")
      drivers.each do |driver|
        pnp_drivers[driver["deviceid"]] = Mash.new
        driver.wmi_ole_object.properties_.each do |p|
          pnp_drivers[driver["deviceid"]][p.name.wmi_underscore.to_sym] = driver[p.name.downcase]
        end
        if driver["devicename"]
          kext[driver["devicename"]] = pnp_drivers[driver["deviceid"]]
          kext[driver["devicename"]][:version] = pnp_drivers[driver["deviceid"]][:driver_version]
          kext[driver["devicename"]][:date] = pnp_drivers[driver["deviceid"]][:driver_date] ? pnp_drivers[driver["deviceid"]][:driver_date].to_s[0..7] : nil
        end
      end

      kernel[:pnp_drivers] = pnp_drivers
      kernel[:modules] = kext

    end
  end

end
