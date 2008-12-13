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

if lsb_dist_id
  platform lsb_dist_id.downcase
  platform_version lsb_dist_release
elsif File.exists?("/etc/debian_version")
  platform "debian"
  platform_version from("cat /etc/debian_version")
elsif File.exists?("/etc/redhat-release")
  platform "redhat"
  File.open("/etc/redhat-release").each do |line|
    platform "centos" if line =~ /centos/i
    case line
    when /\(Rawhide\)/
      platform_version "rawhide"
    when /release (\d+)/
      platform_version $1
    end
  end
end
