#
# Author:: Stuart Preston (<stuart@chef.io>)
# Copyright:: Copyright (c) 2018, Chef Software Inc.
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

Ohai.plugin :SystemEnclosure do
  provides "system_enclosure"

  collect_data(:windows) do
    system_enclosure(Mash.new)
    so = shell_out('powershell.exe -Command "get-ciminstance win32_systemenclosure"')
    if so.exitstatus == 0
      so.stdout.strip.each_line do |line|
        kv = line.split(/:/, 2).map(&:strip)
        system_enclosure[kv[0].downcase] = kv[1] if kv.length == 2
      end
    end
  end
end
