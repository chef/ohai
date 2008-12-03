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

require_plugin "os"

case os
when "linux"
  File.open("/proc/meminfo").each do |line|
    case line
    when /^MemTotal:\s+(\d+) (.+)$/
      memory_total "#{$1$2}"
    when /^MemFree:\s+(\d+) (.+)$/
      memory_free  "#{$1$2}"
    when /^SwapTotal:\s+(\d+) (.+)$/
      swap_total "#{$1$2}"
    when /^SwapFree:\s+(\d+) (.+)$/
      swap_total "#{$1$2}"
    end
  end
end