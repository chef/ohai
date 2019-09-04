#
# Author:: Joshua Miller <joshmiller@fb.com>
# Copyright:: Copyright (c) 2019 Facebook
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

Ohai.plugin(:Sysctl) do
  provides "sysctl"
  optional true

  collect_data(:linux) do
    sysctl_path = which("sysctl")
    if sysctl_path
      sysctl_cmd = shell_out("#{sysctl_path} -a")

      if sysctl_cmd.exitstatus == 0
        sysctl Mash.new unless sysctl

        sysctl_cmd.stdout.lines.each do |line|
          k, v = line.split("=").map(&:strip)
          sysctl[k] = v
        end
      end
    end
  end
end
