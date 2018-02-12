#
# Author:: Kurt Yoder (<ktyopscode@yoderhome.com>)
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

Ohai.plugin(:Uptime) do
  provides "uptime", "uptime_seconds"

  collect_data(:aix) do
    require "date"
    # below we're going to assume that PID 1 is init (this is true 99.99999% of the time)
    # output will look like this
    # 1148-20:54:50
    # This reads as 1148 days, 20 hours, 54 minutes, 50 seconds since the process was started (elapsed)
    # who -b does not return the YEAR, so we need something more concrete
    so = shell_out("LC_ALL=POSIX ps -o etime= -p 1").stdout.strip

    # Here we'll check our shell_out for a dash, which indicates there is a # of days involved
    # We'll chunk off the days, hours (where applicable), minutes, seconds into seperate vars
    # We also need to do this because ps -o etime= will not display days if the machine has been up for less than 24 hours
    # If the machine has been up for less than one hour, the shell_out will not output hours hence our else
    # see here: https://www.ibm.com/support/knowledgecenter/en/ssw_aix_72/com.ibm.aix.cmds4/ps.htm#ps__row-d3e109655
    d = nil
    h = nil
    case so
    when /^\d+-\d/
      (d, h, m, s) = so.split(/[-:]/)
    when /^\d+:\d+:\d/
      (h, m, s) = so.split(/[:]/)
    else
      (m, s) = so.split(/[:]/)
    end
    elapsed_seconds = ((d.to_i * 86400) + (h.to_i * 3600) + (m.to_i * 60) + s.to_i)

    # uptime seconds below will return the elapsed time since boot
    uptime_seconds elapsed_seconds
    uptime seconds_to_human(elapsed_seconds)
  end
end
