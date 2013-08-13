#
# Author:: Benjamin Black (<nostromo@gmail.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

provides "platform", "platform_version", "platform_build"

if File.exists?("/sbin/uname")
  uname_exec = "/sbin/uname"
else
  uname_exec = "uname"
end

popen4("#{uname_exec} -X") do |pid, stdin, stdout, stderr|
  stdin.close
  stdout.each do |line|
    case line
    when /^Release =\s+(.+)$/
      platform_version $1
    when /^KernelID =\s+(.+)$/
      platform_build $1
    end
  end
end

File.open("/etc/release") do |file|
  while line = file.gets
    case line
    when /^.*(SmartOS).*$/
      platform "smartos"
    when /^\s*(OmniOS).*r(\d+).*$/
      platform "omnios"
      platform_version $2
    when /^\s*(OpenIndiana).*oi_(\d+).*$/
      platform "openindiana"
      platform_version $2
    when /^\s*(OpenSolaris).*snv_(\d+).*$/
      platform "opensolaris"
      platform_version $2
    when /^\s*(Oracle Solaris) (\d+)\s.*$/
      platform "solaris2"
    when /^\s*(Solaris)\s.*$/
      platform "solaris2"
    when /^\s*(NexentaCore)\s.*$/
      platform "nexentacore"
    end
  end
end
