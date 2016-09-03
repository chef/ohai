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

Ohai.plugin(:LSB) do
  provides "lsb"

  collect_data(:linux) do
    lsb Mash.new

    if File.exists?("/usr/bin/lsb_release")
      # From package redhat-lsb on Fedora/Redhat, lsb-release on Debian/Ubuntu
      so = shell_out("lsb_release -a")
      so.stdout.lines do |line|
        case line
        when /^Distributor ID:\s+(.+)$/
          lsb[:id] = $1
        when /^Description:\s+(.+)$/
          lsb[:description] = $1
        when /^Release:\s+(.+)$/
          lsb[:release] = $1
        when /^Codename:\s+(.+)$/
          lsb[:codename] = $1
        else
          lsb[:id] = line
        end
      end
    elsif File.exists?("/etc/lsb-release")
      # Old, non-standard Debian support
      File.open("/etc/lsb-release").each do |line|
        case line
        when /^DISTRIB_ID=["']?(.+?)["']?$/
          lsb[:id] = $1
        when /^DISTRIB_RELEASE=["']?(.+?)["']?$/
          lsb[:release] = $1
        when /^DISTRIB_CODENAME=["']?(.+?)["']?$/
          lsb[:codename] = $1
        when /^DISTRIB_DESCRIPTION=["']?(.+?)["']?$/
          lsb[:description] = $1
        end
      end
    else
      Ohai::Log.debug("Skipping LSB, cannot find /etc/lsb-release or /usr/bin/lsb_release")
    end
  end
end
