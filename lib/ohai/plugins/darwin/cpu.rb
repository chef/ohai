#
# Author:: Chris Lundquist <https://github.com/ChrisLundquist>
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

#Sample
#$ sysctl -a hw
#hw.ncpu: 2
#hw.byteorder: 1234
#hw.memsize: 2147483648
#hw.activecpu: 2
#hw.physicalcpu: 2
#hw.physicalcpu_max: 2
#hw.logicalcpu: 2
#hw.logicalcpu_max: 2
#hw.cputype: 7
#hw.cpusubtype: 4
#hw.cpu64bit_capable: 1
#hw.cpufamily: 1114597871
#hw.cacheconfig: 2 1 2 0 0 0 0 0 0 0
#hw.cachesize: 2147483648 32768 4194304 0 0 0 0 0 0 0
#hw.pagesize: 4096
#hw.busfrequency: 664000000
#hw.busfrequency_min: 664000000
#hw.busfrequency_max: 664000000
#hw.cpufrequency: 2000000000
#hw.cpufrequency_min: 2000000000
#hw.cpufrequency_max: 2000000000
#hw.cachelinesize: 64
#hw.l1icachesize: 32768
#hw.l1dcachesize: 32768
#hw.l2cachesize: 4194304
#hw.tbfrequency: 1000000000
#hw.packages: 1
#hw.optional.floatingpoint: 1
#hw.optional.mmx: 1
#hw.optional.sse: 1
#hw.optional.sse2: 1
#hw.optional.sse3: 1
#hw.optional.supplementalsse3: 1
#hw.optional.sse4_1: 0
#hw.optional.sse4_2: 0
#hw.optional.x86_64: 1
#hw.optional.aes: 0
#hw.machine = i386
#hw.model = MacBook2,1
#hw.ncpu = 2
#hw.byteorder = 1234
#hw.physmem = 2147483648
#hw.usermem = 1892192256
#hw.pagesize = 4096
#hw.epoch = 0
#hw.vectorunit = 1
#hw.busfrequency = 664000000
#hw.cpufrequency = 2000000000
#hw.cachelinesize = 64
#hw.l1icachesize = 32768
#hw.l1dcachesize = 32768
#hw.l2settings = 1
#hw.l2cachesize = 4194304
#hw.tbfrequency = 1000000000
#hw.memsize = 2147483648
#hw.availcpu = 2
#
cpuinfo = Mash.new
real_cpu = Mash.new

`sysctl -a hw`.each_line do |line|
  case line
  when /hw.physicalcpu: (\d+)/ #hw.physicalcpu: 2
    cpu[:total] = $1
  when /hw.physicalcpu: (\d+)/
    cpu[:real] = $1
  when /hw.cpufrequency_max: (\d+)/ #hw.cpufrequency_max: 2000000000
    cpu[:mhz] = $1 / 1000000.0
  end
end
#cpu cpuinfo
