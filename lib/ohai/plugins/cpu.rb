#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Tim Smith (tsmith@chef.io)
# Author:: Mathieu Sauve-Frankel <msf@kisoku.net>
# Author:: Nathan L Smith (<nlloyds@gmail.com>)
# Author:: Joshua Timberman <joshua@chef.io>
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Author:: Isa Farnik (<isa@chef.io>)
# Author:: Doug MacEachern <dougm@vmware.com>
# Copyright:: Copyright (c) 2008-2018 Chef Software, Inc.
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

  def parse_bsd_dmesg(&block)
    cpuinfo = Mash.new
    cpuinfo["flags"] = []
    File.open("/var/run/dmesg.boot").each do |line|
      case line
      when /CPU:\s+(.+) \(([\d.]+).+\)/
        cpuinfo["model_name"] = $1
        cpuinfo["mhz"] = $2
      when /Features=.+<(.+)>/
        cpuinfo["flags"].concat($1.downcase.split(","))
        # Features2=0x80000001<SSE3,<b31>>
      when /Features2=[a-f\dx]+<(.+)>/
        cpuinfo["flags"].concat($1.downcase.split(","))
      else
        yield(cpuinfo, line)
      end
    end
    cpuinfo
  end

  collect_data(:linux) do
    cpuinfo = Mash.new
    real_cpu = Mash.new
    cpu_number = 0
    current_cpu = nil

    File.open("/proc/cpuinfo").each do |line|
      case line
      when /processor\s+:\s(.+)/
        cpuinfo[$1] = Mash.new
        current_cpu = $1
        cpu_number += 1
      when /vendor_id\s+:\s(.+)/
        vendor_id = $1
        if vendor_id =~ (%r{IBM/S390})
          cpuinfo["vendor_id"] = vendor_id
        else
          cpuinfo[current_cpu]["vendor_id"] = vendor_id
        end
      when /cpu family\s+:\s(.+)/
        cpuinfo[current_cpu]["family"] = $1
      when /model\s+:\s(.+)/
        cpuinfo[current_cpu]["model"] = $1
      when /stepping\s+:\s(.+)/
        cpuinfo[current_cpu]["stepping"] = $1
      when /physical id\s+:\s(.+)/
        cpuinfo[current_cpu]["physical_id"] = $1
        real_cpu[$1] = true
      when /core id\s+:\s(.+)/
        cpuinfo[current_cpu]["core_id"] = $1
      when /cpu cores\s+:\s(.+)/
        cpuinfo[current_cpu]["cores"] = $1
      when /model name\s+:\s(.+)/
        cpuinfo[current_cpu]["model_name"] = $1
      when /cpu MHz\s+:\s(.+)/
        cpuinfo[current_cpu]["mhz"] = $1
      when /cache size\s+:\s(.+)/
        cpuinfo[current_cpu]["cache_size"] = $1
      when /flags\s+:\s(.+)/
        cpuinfo[current_cpu]["flags"] = $1.split(" ")
      when /BogoMIPS\s+:\s(.+)/
        cpuinfo[current_cpu]["bogomips"] = $1
      when /Features\s+:\s(.+)/
        cpuinfo[current_cpu]["features"] = $1.split(" ")
      when /bogomips per cpu:\s(.+)/
        cpuinfo["bogomips_per_cpu"] = $1
      when /features\s+:\s(.+)/
        cpuinfo["features"] = $1.split(" ")
      when /processor\s(\d):\s(.+)/
        current_cpu = $1
        cpu_number += 1
        cpuinfo[current_cpu] = Mash.new
        current_cpu_info = $2.split(",")
        current_cpu_info.each do |i|
          name_value = i.split("=")
          name = name_value[0].strip
          value = name_value[1].strip
          cpuinfo[current_cpu][name] = value
        end
      end
    end

    cpu cpuinfo

    cpu[:total] = cpu_number

    # use data we collected unless cpuinfo is lacking core information
    # which is the case on older linux distros
    if !real_cpu.empty? && cpu["0"]["cores"]
      cpu[:real] = real_cpu.keys.length
      cpu[:cores] = real_cpu.keys.length * cpu["0"]["cores"].to_i
    else
      begin
        logger.trace("Plugin CPU: Falling back to aggregate data from lscpu as real cpu & core data is missing in /proc/cpuinfo")
        so = shell_out("lscpu")
        if so.exitstatus == 0
          lscpu_data = Mash.new
          so.stdout.each_line do |line|
            case line
            when /^Thread\(s\) per core:\s(.+)/ # http://rubular.com/r/lOw2pRrw1q
              lscpu_data[:threads] = $1.to_i
            when /^Core\(s\) per socket:\s(.+)/ # http://rubular.com/r/lOw2pRrw1q
              lscpu_data[:cores] = $1.to_i
            when /^Socket\(s\):\s(.+)/ # http://rubular.com/r/DIzmPtJFvK
              lscpu_data[:sockets] = $1.to_i
            end
          end
          cpu[:total] = lscpu_data[:sockets] * lscpu_data[:cores] * lscpu_data[:threads]
          cpu[:real] = lscpu_data[:sockets]
          cpu[:cores] = lscpu_data[:sockets] * lscpu_data[:cores]
        else
          logger.trace("Plugin CPU: Error executing lscpu. CPU data may not be available.")
        end
      rescue Ohai::Exceptions::Exec # util-linux isn't installed most likely
        logger.trace("Plugin CPU: Error executing lscpu. util-linux may not be installed.")
      end
    end
  end

  collect_data(:freebsd) do
    # all dmesg output for smp I can find only provides info about a single processor
    # identical processors is probably a hardware requirement so we'll duplicate data for each cpu
    # old examples: http://www.bnv-bamberg.de/home/ba3294/smp/rbuild/index.htm

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

    info = parse_bsd_dmesg do |cpuinfo, line|
      case line
      when /Origin.*"(.*)".*Family.*0x(\S+).*Model.*0x(\S+).*Stepping.*(\S+)/
        cpuinfo["vendor_id"] = $1
        # convert from hex value to int, but keep a string to match Linux ohai
        cpuinfo["family"] = $2.to_i(16).to_s
        cpuinfo["model"] = $3.to_i(16).to_s
        cpuinfo["stepping"] = $4
        # These _should_ match /AMD Features2?/ lines as well
      when %r{FreeBSD/SMP: Multiprocessor System Detected: (\d*) CPUs}
        cpuinfo["total"] = $1.to_i
      when %r{FreeBSD/SMP: (\d*) package\(s\) x (\d*) core\(s\)}
        cpuinfo["real"] = $1.to_i
        cpuinfo["cores"] = $1.to_i * $2.to_i
      end
    end
    cpu info
  end

  collect_data(:dragonflybsd) do
    # /var/run/dmesg.boot
    # CPU: Intel(R) Core(TM) i7-3615QM CPU @ 2.30GHz (3516.61-MHz K8-class CPU)
    # Origin = "GenuineIntel"  Id = 0x306a9  Family = 6  Model = 3a  Stepping = 9
    # Features=0x783fbff<FPU,VME,DE,PSE,TSC,MSR,PAE,MCE,CX8,APIC,SEP,MTRR,PGE,MCA,CMOV,PAT,PSE36,MMX,FXSR,SSE,SSE2>
    # Features2=0x209<SSE3,MON,SSSE3>
    # AMD Features=0x28100800<SYSCALL,NX,RDTSCP,LM>
    # AMD Features2=0x1<LAHF>

    info = parse_bsd_dmesg do |cpuinfo, line|
      case line
      when /Origin = "(.+)"\s+Id = (.+)\s+Stepping = (.+)/
        cpuinfo["vendor_id"] = $1
        cpuinfo["stepping"] = $3
      end
    end

    so = shell_out("sysctl -n hw.ncpu")
    info[:total] = so.stdout.split($/)[0].to_i
    cpu info
  end

  collect_data(:openbsd) do
    cpuinfo = Mash.new

    # OpenBSD provides most cpu information via sysctl, the only thing we need to
    # to scrape from dmesg.boot is the cpu feature list.
    # cpu0: FPU,V86,DE,PSE,TSC,MSR,MCE,CX8,SEP,MTRR,PGE,MCA,CMOV,PAT,CFLUSH,DS,ACPI,MMX,FXSR,SSE,SSE2,SS,TM,SBF,EST,TM2

    File.open("/var/run/dmesg.boot").each do |line|
      case line
      when /cpu\d+:\s+([A-Z]+$|[A-Z]+,.*$)/
        cpuinfo["flags"] = $1.downcase.split(",")
      end
    end

    [["hw.model", :model_name], ["hw.ncpu", :total], ["hw.cpuspeed", :mhz]].each do |param, node|
      so = shell_out("sysctl -n #{param}")
      cpuinfo[node] = so.stdout.split($/)[0]
    end

    cpu cpuinfo
  end

  collect_data(:netbsd) do
    cpuinfo = Mash.new

    # NetBSD provides some cpu information via sysctl, and a little via dmesg.boot
    # unlike OpenBSD and FreeBSD, NetBSD does not provide information about the
    # available instruction set
    # cpu0 at mainbus0 apid 0: Intel 686-class, 2134MHz, id 0x6f6

    File.open("/var/run/dmesg.boot").each do |line|
      case line
      when /cpu[\d\w\s]+:\s([\w\s\-]+),\s+(\w+),/
        cpuinfo[:model_name] = $1
        cpuinfo[:mhz] = $2.gsub(/mhz/i, "")
      end
    end

    flags = []
    so = shell_out("dmidecode")
    so.stdout.lines do |line|
      if line =~ /^\s+([A-Z\d-]+)\s+\([\w\s-]+\)$/
        flags << $1.downcase
      end
    end

    cpuinfo[:flags] = flags unless flags.empty?

    cpu cpuinfo
  end

  collect_data(:darwin) do
    cpu Mash.new
    shell_out("sysctl hw machdep").stdout.lines.each do |line|
      case line
      when /^hw.packages: (.*)$/
        cpu[:real] = Regexp.last_match[1].to_i
      when /^hw.physicalcpu: (.*)$/
        cpu[:cores] = Regexp.last_match[1].to_i
      when /^hw.logicalcpu: (.*)$/
        cpu[:total] = Regexp.last_match[1].to_i
      when /^hw.cpufrequency: (.*)$/
        cpu[:mhz] = Regexp.last_match[1].to_i / 1000000
      when /^machdep.cpu.vendor: (.*)$/
        cpu[:vendor_id] = Regexp.last_match[1].chomp
      when /^machdep.cpu.brand_string: (.*)$/
        cpu[:model_name] = Regexp.last_match[1].chomp
      when /^machdep.cpu.model: (.*)$/
        cpu[:model] = Regexp.last_match[1].to_i
      when /^machdep.cpu.family: (.*)$/
        cpu[:family] = Regexp.last_match[1].to_i
      when /^machdep.cpu.stepping: (.*)$/
        cpu[:stepping] = Regexp.last_match[1].to_i
      when /^machdep.cpu.features: (.*)$/
        cpu[:flags] = Regexp.last_match[1].downcase.split(" ")
      end
    end
  end

  collect_data(:aix) do
    cpu Mash.new

    cpu[:total] = shell_out("pmcycles -m").stdout.lines.length

    # The below is only relevent on an LPAR
    if shell_out("uname -W").stdout.strip == "0"

      # At least one CPU will be available, but we'll wait to increment this later.
      cpu[:available] = 0

      cpudevs = shell_out("lsdev -Cc processor").stdout.lines
      # from http://www-01.ibm.com/software/passportadvantage/pvu_terminology_for_customers.html
      # on AIX number of cores and processors are considered same
      cpu[:real] = cpu[:cores] = cpudevs.length
      cpudevs.each.with_index do |c, i|
        name, status, location = c.split
        index = i.to_s
        cpu[index] = Mash.new
        cpu[index][:status] = status
        cpu[index][:location] = location
        if status =~ /Available/
          cpu[:available] += 1
          lsattr = shell_out("lsattr -El #{name}").stdout.lines
          lsattr.each do |attribute|
            attrib, value = attribute.split
            if attrib == "type"
              cpu[index][:model_name] = value
            elsif attrib == "frequency"
              cpu[index][:mhz] = value.to_i / (1000 * 1000) # convert from hz to MHz
            else
              cpu[index][attrib] = value
            end
          end
          # IBM is the only maker of CPUs for AIX systems.
          cpu[index][:vendor_id] = "IBM"
        end
      end
    end
  end

  collect_data(:solaris2) do
    cpu Mash.new
    # This does assume that /usr/bin/kstat is in the path
    processor_info = shell_out("kstat -p cpu_info").stdout.lines
    cpu["total"] = 0
    cpu["sockets"] = 0
    cpu["cores"] = 0
    cpu["corethreads"] = 0
    cpu["cpustates"] = Mash.new

    currentcpu = 0
    cpucores = []
    cpusockets = []
    processor_info.each do |processor|
      _desc, instance, _record, keyvalue = processor.split(":")
      cpu[instance] ||= Mash.new
      if currentcpu != instance
        cpu["total"] += 1
        currentcpu = instance
      end
      kv = keyvalue.split(/\s+/)
      key = kv.shift
      value = kv.join(" ").chomp
      case key
        when /chip_id/
          cpu[instance]["socket"] = value
          cpusockets.push(value) if cpusockets.index(value).nil?
        when /cpu_type/
          cpu[instance]["arch"] = value
        when /clock_MHz/
          cpu[instance]["mhz"] = value
        when /brand/
          cpu[instance]["model_name"] = value.sub(/\s+/, " ")
        when /^state$/
          cpu[instance]["state"] = value
          cpu["cpustates"][value] ||= 0
          cpu["cpustates"][value] += 1
        when /core_id/
          cpu[instance]["core_id"] = value
           # Detect hyperthreading/multithreading
          cpucores.push(value) if cpucores.index(value).nil?
        when /family|fpu_type|model|stepping|vendor_id/
          cpu[instance][key] = value
      end
    end
    cpu["cores"] = cpucores.size
    cpu["corethreads"] = (cpu["total"] / cpucores.size)
    cpu["sockets"] = cpusockets.size
    cpu["real"] = cpusockets.size
  end

  collect_data(:windows) do
    require "wmi-lite/wmi"

    cpu Mash.new
    cores = 0
    logical_processors = 0

    wmi = WmiLite::Wmi.new
    processors = wmi.instances_of("Win32_Processor")

    processors.each_with_index do |processor, index|
      current_cpu = index.to_s
      cpu[current_cpu] = Mash.new

      cpu[current_cpu]["cores"] = processor["numberofcores"]
      cores += processor["numberofcores"]

      logical_processors += processor["numberoflogicalprocessors"]
      cpu[current_cpu]["vendor_id"] = processor["manufacturer"]
      cpu[current_cpu]["family"] = processor["family"].to_s
      cpu[current_cpu]["model"] = processor["revision"].to_s
      cpu[current_cpu]["stepping"] = if processor["stepping"].nil?
                                       processor["description"].match(/Stepping\s+(\d+)/)[1]
                                     else
                                       processor["stepping"]
                                     end
      cpu[current_cpu]["physical_id"] = processor["deviceid"]
      cpu[current_cpu]["model_name"] = processor["name"]
      cpu[current_cpu]["description"] = processor["description"]
      cpu[current_cpu]["mhz"] = processor["maxclockspeed"].to_s
      cpu[current_cpu]["cache_size"] = "#{processor["l2cachesize"]} KB"
    end

    cpu[:total] = logical_processors
    cpu[:cores] = cores
    cpu[:real] =  processors.length
  end
end
