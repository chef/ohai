#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

begin
  File.open("/etc/lsb-release").each do |line|
    case line
    when /^DISTRIB_ID=(.+)$/
      lsb_dist_id $1
    when /^DISTRIB_RELEASE=(.+)$/
      lsb_dist_release $1
    when /^DISTRIB_CODENAME=(.+)$/
      lsb_dist_codename $1
    when /^DISTRIB_DESCRIPTION=(.+)$/
      lsb_dist_description $1
    end
  end
rescue
  Ohai::Log.debug("Skipping LSB, cannot find /etc/lsb-release")
end
