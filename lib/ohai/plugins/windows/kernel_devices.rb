#
# Author:: James Gartrell (<jgartrel@gmail.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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
require 'ruby-wmi'

WIN32OLE.codepage = WIN32OLE::CP_UTF8

kext = Mash.new
pnp_drivers = Mash.new

drivers = WMI::Win32_PnPSignedDriver.find(:all)
drivers.each do |driver|
  pnp_drivers[driver.DeviceID] = Mash.new
  driver.properties_.each do |p|
    pnp_drivers[driver.DeviceID][p.name.wmi_underscore.to_sym] = driver.send(p.name)
  end
  if driver.DeviceName
    kext[driver.DeviceName] = pnp_drivers[driver.DeviceID]
    kext[driver.DeviceName][:version] = pnp_drivers[driver.DeviceID][:driver_version]
    kext[driver.DeviceName][:date] = pnp_drivers[driver.DeviceID][:driver_date] ? pnp_drivers[driver.DeviceID][:driver_date].to_s[0..7] : nil
  end 
end

kernel[:pnp_drivers] = pnp_drivers
kernel[:modules] = kext
