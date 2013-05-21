#
# Author:: Dmytro Kovalov (<dmytro.kovalov@gmail.com>)
# Copyright:: Copyright (c) 2012, Dmytro Kovalov
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

provides "cpu"

cpuinfo = Mash.new
cpu_number = 0


IO.popen("sysctl -a hw").each do |line|
  next unless line =~/^hw\..*cpu.*:\s*\d+/
  key,val = line.strip.split /\s*:\s*/
  key.sub!(/^hw\./, '')
  cpuinfo[key.to_sym] = val

end

cpu cpuinfo
cpu[:total] = cpuinfo[:ncpu].to_i
cpu[:real] = cpuinfo[:physicalcpu].to_i
