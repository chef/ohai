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

Ohai.plugin(:CPU) do
  provides "cpu"

  collect_data(:dragonflybsd) do
    # all dmesg output for smp I can find only provides info about a single processor
    # identical processors is probably a hardware requirement so we'll duplicate data for each cpu
    # old examples: http://www.bnv-bamberg.de/home/ba3294/smp/rbuild/index.htm
    cpuinfo = Mash.new
    cpuinfo["flags"] = []

    # /var/run/dmesg.boot
    # CPU: Intel(R) Core(TM) i7-3615QM CPU @ 2.30GHz (3516.61-MHz K8-class CPU)
    # Origin = "GenuineIntel"  Id = 0x306a9  Family = 6  Model = 3a  Stepping = 9
    # Features=0x783fbff<FPU,VME,DE,PSE,TSC,MSR,PAE,MCE,CX8,APIC,SEP,MTRR,PGE,MCA,CMOV,PAT,PSE36,MMX,FXSR,SSE,SSE2>
    # Features2=0x209<SSE3,MON,SSSE3>
    # AMD Features=0x28100800<SYSCALL,NX,RDTSCP,LM>
    # AMD Features2=0x1<LAHF>

    File.open("/var/run/dmesg.boot").each do |line|
      case line
      when /CPU:\s+(.+) \(([\d.]+).+\)/
        cpuinfo["model_name"] = $1
        cpuinfo["mhz"] = $2
      when /Origin = "(.+)"\s+Id = (.+)\s+Stepping = (.+)/
        cpuinfo["vendor_id"] = $1
        cpuinfo["stepping"] = $3
        # These _should_ match /AMD Features2?/ lines as well
      when /Features=.+<(.+)>/
        cpuinfo["flags"].concat($1.downcase.split(","))
        # Features2=0x80000001<SSE3,<b31>>
      when /Features2=[a-f\dx]+<(.+)>/
        cpuinfo["flags"].concat($1.downcase.split(","))
      end
    end

    cpu cpuinfo
    so = shell_out("sysctl -n hw.ncpu")
    cpu[:total] = so.stdout.split($/)[0].to_i
  end
end
