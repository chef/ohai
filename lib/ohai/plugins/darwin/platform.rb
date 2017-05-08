#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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

  collect_data(:darwin) do
    so = shell_out("#{Ohai.abs_path( "/usr/bin/sw_vers" )}")
    so.stdout.lines do |line|
      case line
      when /^ProductName:\s+(.+)$/
        macname = $1
        macname.downcase!
        macname.tr!(" ", "_")
        platform macname
      when /^ProductVersion:\s+(.+)$/
        platform_version $1
      when /^BuildVersion:\s+(.+)$/
        platform_build $1
      end
    end

    platform_family "mac_os_x"
  end
end
