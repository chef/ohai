#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Tim Smith (tsmith@chef.io)
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

  collect_data(:freebsd) do
    # all dmesg output for smp I can find only provides info about a single processor
    # identical processors is probably a hardware requirement so we'll duplicate data for each cpu
    # old examples: http://www.bnv-bamberg.de/home/ba3294/smp/rbuild/index.htm
    cpuinfo = Mash.new
    cpuinfo["flags"] = []

    # /var/run/dmesg.boot
    # CPU: Intel(R) Core(TM) i7-4980HQ CPU @ 2.80GHz (2793.59-MHz K8-class CPU)
    #   Origin="GenuineIntel"  Id=0x40661  Family=0x6  Model=0x46  Stepping=1
    #   Features=0x783fbff<FPU,VME,DE,PSE,TSC,MSR,PAE,MCE,CX8,APIC,SEP,MTRR,PGE,MCA,CMOV,PAT,PSE36,MMX,FXSR,SSE,SSE2>
    #   Features2=0x5ed8220b<SSE3,PCLMULQDQ,MON,SSSE3,CX16,SSE4.1,SSE4.2,MOVBE,POPCNT,AESNI,XSAVE,OSXSAVE,AVX,RDRAND>
    #   AMD Features=0x28100800<SYSCALL,NX,RDTSCP,LM>
    #   AMD Features2=0x21<LAHF,ABM>
    #   Structured Extended Features=0x2000<NFPUSG>
    #   TSC: P-state invariant
    #   ...
    #   FreeBSD/SMP: Multiprocessor System Detected: 16 CPUs
    #   FreeBSD/SMP: 2 package(s) x 4 core(s) x 2 SMT threads

    File.open("/var/run/dmesg.boot").each do |line|
      case line
      when /CPU:\s+(.+) \(([\d.]+).+\)/
        cpuinfo["model_name"] = $1
        cpuinfo["mhz"] = $2
      when /Origin.*"(.*)".*Family.*0x(\S+).*Model.*0x(\S+).*Stepping.*(\S+)/
        cpuinfo["vendor_id"] = $1
        # convert from hex value to int, but keep a string to match Linux ohai
        cpuinfo["family"] = $2.to_i(16).to_s
        cpuinfo["model"] = $3.to_i(16).to_s
        cpuinfo["stepping"] = $4
        # These _should_ match /AMD Features2?/ lines as well
      when /Features=.+<(.+)>/
        cpuinfo["flags"].concat($1.downcase.split(","))
        # Features2=0x80000001<SSE3,<b31>>
      when /Features2=[a-f\dx]+<(.+)>/
        cpuinfo["flags"].concat($1.downcase.split(","))
      when /FreeBSD\/SMP: Multiprocessor System Detected: (\d*) CPUs/
        cpuinfo["total"] = $1.to_i
      when /FreeBSD\/SMP: (\d*) package\(s\) x (\d*) core\(s\)/
        cpuinfo["real"] = $1.to_i
        cpuinfo["cores"] = $1.to_i * $2.to_i
      end
    end

    cpu cpuinfo
  end
end
