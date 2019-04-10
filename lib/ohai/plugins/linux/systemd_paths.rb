#
# Author:: Davide Cavalca <dcavalca@fb.com>
# Copyright:: Copyright (c) 2017 Facebook
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

Ohai.plugin(:SystemdPaths) do
  provides "systemd_paths"

  collect_data(:linux) do
    systemd_path_path = which("systemd-path")
    if systemd_path_path
      systemd_path = shell_out(systemd_path_path)

      systemd_paths Mash.new unless systemd_paths

      systemd_path.stdout.each_line do |line|
        key, val = line.split(":")
        systemd_paths[key] = val.strip
      end
    end
  end
end
