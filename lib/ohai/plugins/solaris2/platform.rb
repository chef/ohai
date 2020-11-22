# frozen_string_literal: true
#
# Author:: Benjamin Black (<nostromo@gmail.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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

Ohai.plugin(:Platform) do
  provides "platform", "platform_version", "platform_build", "platform_family"

  collect_data(:solaris2) do
    if file_exist?("/sbin/uname")
      uname_exec = "/sbin/uname"
    else
      uname_exec = "uname"
    end

    shell_out("#{uname_exec} -X").stdout.lines do |line|
      case line
      when /^Release =\s+(.+)$/
        platform_version $1
      when /^KernelID =\s+(.+)$/
        platform_build $1
      end
    end

    file_open("/etc/release") do |file|
      while ( line = file.gets )
        case line
        when /.*SmartOS.*/
          platform "smartos"
        when /^\s*OmniOS.*r(\d+).*$/
          platform "omnios"
          platform_version $1
        when /^\s*OpenIndiana.*(Development oi_|Hipster )(\d\S*)/ # https://rubular.com/r/iMtOBwbnyqDz7u
          platform "openindiana"
          platform_version $2
        when /^\s*(Oracle Solaris|Solaris)/
          platform "solaris2"
        end
      end
    end

    platform_family platform
  end
end
