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

provides "languages/nodejs"

require_plugin "languages"

output = nil

nodejs = Mash.new

status, stdout, stderr = run_command(:no_status_check => true, :command => "node -v")
if status == 0
  output = stdout.split
  if output.length >= 1
    nodejs[:version] = output[0][1..output[0].length]
  end
  languages[:nodejs] = nodejs if nodejs[:version]
end
