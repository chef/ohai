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

def machine_lookup(sys_type)
  return "i386" if sys_type.eql?("X86-based PC")
  return "x86_64" if sys_type.eql?("x64-based PC")
  sys_type
end

require 'ruby-wmi'
host = WMI::Win32_OperatingSystem.find(:first)

kernel[:name] = "#{host.Caption}"
kernel[:release] = "#{host.Version}"
kernel[:version] = "#{host.Version} #{host.CSDVersion} Build #{host.BuildNumber}"

host = WMI::Win32_ComputerSystem.find(:first)
kernel[:machine] = machine_lookup("#{host.SystemType}")
kernel[:os] = languages[:ruby][:host_os]

kext = Mash.new
pnp_drivers = Mash.new

#popen4("/sbin/lsmod") do |pid, stdin, stdout, stderr|
#  stdin.close
#  stdout.each do |line|
#    if line =~ /([a-zA-Z0-9\_]+)\s+(\d+)\s+(\d+)/
#      kext[$1] = { :size => $2, :refcount => $3 }
#    end
#  end
#end

drivers = WMI::Win32_PnPSignedDriver.find(:all)
drivers.each do |driver|
  pnp_drivers[driver.DeviceID] = Mash.new
  driver.properties_.each do |p|
    pnp_drivers[driver.DeviceID][p.name.underscore.to_sym] = driver[p.name]
  end
  if driver.DeviceName
    #kext[driver.DeviceName] = { :version => driver.DriverVersion, 
    #                            :signed => driver.IsSigned,
    #                            :signer => driver.Signer,
    #                            :id => driver.DeviceID,
    #                            :class => driver.DeviceClass,
    #                            :date => driver.DriverDate ? driver.DriverDate.to_s[0..7] : nil
    #                          }
    kext[driver.DeviceName] = pnp_drivers[driver.DeviceID]
    kext[driver.DeviceName][:version] = pnp_drivers[driver.DeviceID][:driver_version]
    kext[driver.DeviceName][:date] = pnp_drivers[driver.DeviceID][:driver_date] ? pnp_drivers[driver.DeviceID][:driver_date].to_s[0..7] : nil
  end 
end

kernel[:pnp_drivers] = pnp_drivers
kernel[:modules] = kext
