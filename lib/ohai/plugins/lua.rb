#
# Author:: Doug MacEachern <dougm@vmware.com>
# Copyright:: Copyright (c) 2009 VMware, Inc.
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

Ohai.plugin(:Lua) do
  provides "languages/lua"
  depends "languages"

  collect_data do
    begin
      so = shell_out("lua -v")
      # Sample output:
      # Lua 5.2.4  Copyright (C) 1994-2015 Lua.org, PUC-Rio
      if so.exitstatus == 0
        lua = Mash.new
        # at some point in lua's history they went from outputting the version
        # on stderr to doing it on stdout. This handles old / new versions
        lua[:version] = so.stdout.empty? ? so.stderr.split[1] : so.stdout.split[1]
        languages[:lua] = lua if lua[:version]
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Plugin Lua: Could not shell_out "lua -v". Skipping plugin')
    end
  end
end
