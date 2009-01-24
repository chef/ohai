#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2008 Bryan McLellan
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

# FIXME: Fixed support for a single processor at the moment
cpuinfo = Mash.new
cpuinfo[0] = Mash.new
cpu_number = 0
current_cpu = nil

# /var/run/dmesg.boot
#CPU: QEMU Virtual CPU version 0.9.1 (1862.02-MHz 686-class CPU)
#  Origin = "GenuineIntel"  Id = 0x623  Stepping = 3
#  Features=0x78bfbfd<FPU,DE,PSE,TSC,MSR,PAE,MCE,CX8,APIC,SEP,MTRR,PGE,MCA,CMOV,PAT,PSE36,CLFLUSH,MMX,FXSR,SSE,SSE2>
#  Features2=0x80000001<SSE3,<b31>>

File.open("/var/run/dmesg.boot").each do |line|
  case line
  when /CPU:\s+(.+) \(([\d.]+).+\)/
    cpuinfo[0]["model_name"] = $1
    cpuinfo[0]["mhz"] = $2
  when /Origin = "(.+)"\s+Id = (.+)\s+Stepping = (.+)/
    cpuinfo[0]["vendor_id"] = $1
    cpuinfo[0]["stepping"] = $3
  when /Features=.+<(.+)>/
    cpuinfo[0]["flags"] = $1.downcase.split(',')
  when /Features2=.+<(\w+)>/
    cpuinfo[0]["flags"].insert($1.downcase.split(','))
  end
end

cpu cpuinfo
cpu[:total] = cpu_number
