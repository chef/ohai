#
# Author:: Jacques Marneweck (<jacques@powertrip.co.za>)
# Copyright:: Copyright (c) 2012 Jacques Marneweck.  All rights reserved.
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

Ohai.plugin(:Nodejs) do
  provides "languages/nodejs"

  depends "languages"

  collect_data do
    begin
      so = shell_out("node -v")
      if so.exitstatus == 0
        Ohai::Log.debug("Successfully ran node -v")
        nodejs = Mash.new
        output = nil
        output = so.stdout.split
        if output.length >= 1
          nodejs[:version] = output[0][1..output[0].length]
        end
        languages[:nodejs] = nodejs unless nodejs.empty?
      end
    rescue Errno::ENOENT
      Ohai::Log.debug("Could not run node -v: Errno::ENOENT")
    end
  end
end
