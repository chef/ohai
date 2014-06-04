#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Bryan McLellan (<btm@loftninjas.org>)
# Author:: Claire McQuin (<claire@opscode.com>)
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Author:: Kurt Yoder (<ktyopscode@yoderhome.com>)
# Author:: Paul Mooring (<paul@opscode.com>)
# Copyright:: Copyright (c) 2008, 2012, 2013 Opscode, Inc.
# Copyright:: Copyright (c) 2009 Bryan McLellan
# Copyright:: Copyright (c) 2010 VMware, Inc.
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'ohai/mixin/seconds_to_human'

Ohai.plugin(:Uptime) do
  provides "uptime", "uptime_seconds"
  provides "idletime", "idletime_seconds" # linux only

  def collect_uptime(path)
    # kern.boottime: { sec = 1232765114, usec = 823118 } Fri Jan 23 18:45:14 2009
    so = shell_out("#{Ohai.abs_path(path)} kern.boottime")
    so.stdout.lines do |line|
      if line =~ /kern.boottime:\D+(\d+)/
        usec = Time.new.to_i - $1.to_i
        return [usec, seconds_to_human(usec)]
      end
    end
    return [nil, nil]
  end

  collect_data(:hpux, :default) do
    require 'sigar'

    sigar = Sigar.new
    uptime = sigar.uptime.uptime
    uptime_seconds uptime.to_i * 1000
    uptime seconds_to_human(uptime.to_i)
  end

  collect_data(:darwin) do
    data = collect_uptime("/usr/sbin/sysctl")
    uptime_seconds data.first
    uptime data.last
  end

  collect_data(:freebsd, :netbsd) do
    data = collect_uptime("/sbin/sysctl")
    uptime_seconds data.first
    uptime data.last
  end

  collect_data(:linux) do
    uptime, idletime = File.open("/proc/uptime").gets.split(" ")
    uptime_seconds uptime.to_i
    uptime seconds_to_human(uptime.to_i)
    idletime_seconds idletime.to_i
    idletime seconds_to_human(idletime.to_i)
  end

  collect_data(:openbsd) do
    # kern.boottime=Tue Nov  1 14:45:52 2011
    so = shell_out("#{ Ohai.abs_path( "/sbin/sysctl" )} #kern.boottime")
    so.stdout.lines do |line|
      if line =~ /kern.boottime=(.+)/
        uptime_seconds Time.new.to_i - Time.parse($1).to_i
        uptime seconds_to_human(uptime_seconds)
      end
    end
  end

  collect_data(:solaris2) do
    so = shell_out("kstat -p unix:0:system_misc:boot_time")
    # unix:0:system_misc:boot_time    1343860543
    so.stdout.lines do |line|
      if line =~ /unix:0:system_misc:boot_time\s+(\d+)/
        uptime_seconds Time.new.to_i - $1.to_i
        uptime seconds_to_human(uptime_seconds)
      end
    end
  end

  collect_data(:windows) do
    require 'wmi-lite/wmi'
    wmi = WmiLite::Wmi.new
    uptime_seconds wmi.first_of('Win32_PerfFormattedData_PerfOS_System')['systemuptime'].to_i
    uptime seconds_to_human(uptime_seconds)
  end

end

