#
# Author:: Patrick Collins (<pat@burned.com>)
# Copyright:: Copyright (c) 2013 Patrick Collins
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

provides "memory"

memory Mash.new

popen4("top -l1 -R -n0") do |pid, stdin, stdout, stderr|
  stdin.close
  stdout.each do |line|
    if line =~ /PhysMem:/
      memory[:total] = "#{$1}#{$2}B" if line =~ /(\d+)([a-z]{1})\s+used/i
      memory[:free] = "#{$1}#{$2}B" if line =~ /(\d+)([a-z]{1})\s+free/i
      memory[:active] = "#{$1}#{$2}B" if line =~ /(\d+)([a-z]{1})\s+active/i
      memory[:inactive] = "#{$1}#{$2}B" if line =~ /(\d+)([a-z]{1})\s+inactive/i
    end
  end
end

