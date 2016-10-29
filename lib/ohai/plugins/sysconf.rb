#
# Author:: Davide Cavalca <dcavalca@fb.com>
# Copyright:: Copyright (c) 2016 Facebook
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

Ohai.plugin(:Sysconf) do
  provides "sysconf"

  collect_data(:aix, :linux, :solaris2) do
    getconf_path = which("getconf")
    if getconf_path
      getconf = shell_out("#{getconf_path} -a")

      if getconf.exitstatus == 0
        sysconf Mash.new unless sysconf

        getconf.stdout.split("\n").each do |line|
          key, val = /^(\S+)\s*(.*)?$/.match(line).captures
          if val && !val.empty?
            begin
              sysconf[key] = Integer(val)
            rescue
              sysconf[key] = val
            end
          else
            sysconf[key] = nil
          end
        end
      end
    end
  end
end
