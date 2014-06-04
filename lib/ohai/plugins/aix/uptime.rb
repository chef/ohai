#
# Author:: Kurt Yoder (<ktyopscode@yoderhome.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
    require 'date'
    # Example output:
    # $ who -b
    #   .       system boot  Jul  9 17:51
    so = shell_out('who -b')
    so.stdout.lines.each do |line|
      if line =~ /.* boot (.+)/
        uptime_seconds Time.now.to_i - DateTime.parse($1).strftime('%s').to_i
        uptime seconds_to_human(uptime_seconds)
        break
      end
    end
  end
end
