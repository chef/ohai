#
# Author:: Kurt Yoder (<ktyopscode@yoderhome.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
require 'date'
# It would be far better if we could include sys/uptime from sys-uptime RubyGem
# It would also be good if we could pull idle time; how do we do this on Solaris?

provides "uptime", "uptime_seconds"

# Example output:
# $ who -b
#   .       system boot  Jul  9 17:51
popen4('who -b') do |pid, stdin, stdout, stderr|
  stdin.close
  stdout.each do |line|
    if line =~ /.* boot (.+)/
      uptime_seconds Time.now.to_i - DateTime.parse($1).strftime('%s').to_i
		uptime self._seconds_to_human(uptime_seconds)
		break
    end
  end
end
