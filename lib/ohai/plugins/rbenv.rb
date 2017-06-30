#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2017 Chef Software, Inc.
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

Ohai.plugin(:Rbenv) do
  depends "languages/ruby"
  provides "languages/ruby/rbenv"

  collect_data do
    begin
      so = shell_out("rbenv versions")
      # Sample output:
      #   system
      # * 2.4.1 (set by /Users/tsmith/.rbenv/version)

      if so.exitstatus == 0
        rbenv = Mash.new
        versions = []

        # iterate over each line and build an array of versions
        # exclude system this provides basically no value to the user
        # also find the version that starts with * and set it as the default
        so.stdout.each_line do |line|
          match = /^(\*)?\s*(\S*)/.match(line)
          next if match[2] == "system"
          versions << match[2]
          rbenv[:default] = match[2] unless match[1].empty? # if it starts with * its the default
        end
        rbenv[:versions] = versions

        ver_so = shell_out("rbenv --version")
        # Sample output:
        # rbenv 1.1.0
        if ver_so.exitstatus == 0
          # sample regex http://rubular.com/r/IzjNV7Yyr3
          rbenv[:rbenv_version] = /rbenv\s(.*)/.match(ver_so.stdout)[1]
        end

        languages[:ruby][:rbenv] = rbenv
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug("Plugin Rbenv: Could not shell_out to rbenv. Skipping plugin")
    end
  end
end
