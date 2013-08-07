#
# Author:: Adam Jacob (<adam@opscode.com>)
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

Ohai.plugin(:Uptime) do
  provides "uptime", "idletime", "uptime_seconds", "idletime_seconds"

  collect_data do
    uptime, idletime = File.open("/proc/uptime").gets.split(" ")
    uptime_seconds uptime.to_i
    uptime seconds_to_human(uptime.to_i)
    idletime_seconds idletime.to_i
    idletime seconds_to_human(idletime.to_i)
  end
end
