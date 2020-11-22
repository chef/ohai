# frozen_string_literal: true
#
# Author:: Adam Jacob (<adam@chef.io>)
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

Ohai.plugin(:LSB) do
  provides "lsb"

  collect_data(:linux) do
    lsb Mash.new

    if file_exist?("/usr/bin/lsb_release")
      # From package redhat-lsb on Fedora/Redhat, lsb-release on Debian/Ubuntu
      shell_out("lsb_release -a").stdout.lines do |line|
        case line
        when /^Distributor ID:\s+(.+)/
          lsb[:id] = $1
        when /^Description:\s+(.+)/
          lsb[:description] = $1
        when /^Release:\s+(.+)/
          lsb[:release] = $1
        when /^Codename:\s+(.+)/
          lsb[:codename] = $1
        else
          lsb[:id] = line
        end
      end
    else
      logger.trace("Plugin LSB: Skipping LSB, cannot find /usr/bin/lsb_release")
    end
  end
end
