#
# Author:: Will Maier (<will@simple.com>)
# Copyright:: Copyright (c) 2013 Simple Finance Technology, Inc.
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

provides "getconf"

status, stdout, stderr = run_command(
                                     :no_status_check => true,
                                     :command => "getconf -a")
getconf = Mash.new
self[:getconf] = getconf

if status == 0
  stdout.lines.each do |line|
    fields = line.strip.split
    getconf[fields[0].to_sym] = fields[1]
  end
end

