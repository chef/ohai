# frozen_string_literal: true
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
# Author:: Lance Albertson <lance@osuosl.org>
# Copyright:: Copyright (c) Chef Software Inc.
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
    file_open("/var/run/dmesg.boot").each do |line|
      case line
      when /CPU:\s+(.+) \(([\d.]+).+\)/
        cpuinfo["model_name"] = $1
        cpuinfo["mhz"] = $2
      when /Features=.+<(.+)>/, /Features2=[a-f\dx]+<(.+)>/
        cpuinfo["flags"].concat($1.downcase.split(","))
        # Features2=0x80000001<SSE3,<b31>>
      else
        yield(cpuinfo, line)
      end
    end
    cpuinfo
  end

  # Convert a string that looks like range of CPUs to an array
  # Given the following range: 1-7
  # Convert it into an array: [1, 2, 3, 4, 5, 6, 7]
  def range_str_to_a(range)
    range.split(",").each_with_object([]) do |cpu, arr|
      if /\d+-\d+/.match?(cpu.to_s)
        arr << Range.new(*cpu.split("-").map(&:to_i)).to_a
      else
        arr << cpu.to_i
      end
    end.flatten
  end

  def parse_lscpu(cpu_info)
    lscpu_info = Mash.new
    begin
      so = shell_out("lscpu")
      cpu_cores = shell_out("lscpu -p=CPU,CORE,SOCKET")
      if so.exitstatus == 0 && cpu_cores.exitstatus == 0
        lscpu_info[:numa_node_cpus] = Mash.new
        lscpu_info[:vulnerability] = Mash.new
        so.stdout.each_line do |line|
          case line
          when /^Architecture:\s+(.+)/
            lscpu_info[:architecture] = $1.to_s
          when /^CPU op-mode\(s\):\s+(.+)/
            lscpu_info[:cpu_opmodes] = $1.split(", ")
          when /^Byte Order:\s+(.+)/
            lscpu_info[:byte_order] = $1.downcase
          when /^Address sizes:\s+(.+)/
            lscpu_info[:address_sizes] = $1.split(", ")
          when /^CPU\(s\):\s+(.+)/
            lscpu_info[:cpus] = $1.to_i
          when /^On-line CPU\(s\) list:\s+(.+)/
            cpu_range = range_str_to_a($1)
            if cpu_range == [0]
              lscpu_info[:cpus_online] = 0
            else
              lscpu_info[:cpus_online] = cpu_range.length
            end
          when /^Off-line CPU\(s\) list:\s+(.+)/
            cpu_range = range_str_to_a($1)
            if cpu_range == [0]
              lscpu_info[:cpus_offline] = 0
            else
              lscpu_info[:cpus_offline] = cpu_range.length
            end
          when /^Thread\(s\) per core:\s+(.+)/ # http://rubular.com/r/lOw2pRrw1q
            lscpu_info[:threads_per_core] = $1.to_i
          when /^Core\(s\) per socket:\s+(.+)/ # http://rubular.com/r/lOw2pRrw1q
            lscpu_info[:cores_per_socket] = $1.to_i
          when /^Socket\(s\):\s+(.+)/ # http://rubular.com/r/DIzmPtJFvK
            lscpu_info[:sockets] = $1.to_i
          when /^Socket\(s\) per book:\s+(.+)/
            lscpu_info[:sockets_per_book] = $1.to_i
          when /^Book\(s\) per drawer:\s+(.+)/
            lscpu_info[:books_per_drawer] = $1.to_i
          when /^Drawer\(s\):\s+(.+)/
            lscpu_info[:drawers] = $1.to_i
          when /^NUMA node\(s\):\s+(.+)/
            lscpu_info[:numa_nodes] = $1.to_i
          when /^Vendor ID:\s+(.+)/
            lscpu_info[:vendor_id] = $1
          when /^Machine type:\s+(.+)/
            lscpu_info[:machine_type] = $1
          when /^CPU family:\s+(.+)/
            lscpu_info[:family] = $1
          when /^Model:\s+(.+)/
            lscpu_info[:model] = $1
          when /^Model name:\s+(.+)/
            lscpu_info[:model_name] = $1
          when /^Stepping:\s+(.+)/
            lscpu_info[:stepping] = $1
          when /^CPU MHz:\s+(.+)/
            lscpu_info[:mhz] = $1
          when /^CPU static MHz:\s+(.+)/
            lscpu_info[:mhz] = $1
          when /^CPU max MHz:\s+(.+)/
            lscpu_info[:mhz_max] = $1
          when /^CPU min MHz:\s+(.+)/
            lscpu_info[:mhz_min] = $1
          when /^CPU dynamic MHz:\s+(.+)/
            lscpu_info[:mhz_dynamic] = $1
          when /^BogoMIPS:\s+(.+)/
            lscpu_info[:bogomips] = $1
          when /^Virtualization:\s+(.+)/
            lscpu_info[:virtualization] = $1
          when /^Virtualization type:\s+(.+)/
            lscpu_info[:virtualization_type] = $1
          when /^Hypervisor vendor:\s+(.+)/
            lscpu_info[:hypervisor_vendor] = $1
          when /^Dispatching mode:\s+(.+)/
            lscpu_info[:dispatching_mode] = $1
          when /^L1d cache:\s+(.+)/
            lscpu_info[:l1d_cache] = $1
          when /^L1i cache:\s+(.+)/
            lscpu_info[:l1i_cache] = $1
          when /^L2 cache:\s+(.+)/
            lscpu_info[:l2_cache] = $1
          when /^L2d cache:\s+(.+)/
            lscpu_info[:l2d_cache] = $1
          when /^L2i cache:\s+(.+)/
            lscpu_info[:l2i_cache] = $1
          when /^L3 cache:\s+(.+)/
            lscpu_info[:l3_cache] = $1
          when /^L4 cache:\s+(.+)/
            lscpu_info[:l4_cache] = $1
          when /^NUMA node(\d+) CPU\(s\):\s+(.+)/
            numa_node = $1
            cpus = $2
            lscpu_info[:numa_node_cpus][numa_node] = range_str_to_a(cpus)
          when /^Vulnerability (.+?):\s+(.+)/ # https://rubular.com/r/aKtSD1ypUlKbGm
            name = $1.strip.downcase.tr(" ", "_")
            description = $2.strip
            lscpu_info[:vulnerability][name] = Mash.new
            lscpu_info[:vulnerability][name] = description
          when /^Flags:\s+(.+)/
            lscpu_info[:flags] = $1.split(" ").sort
            # flags are "features" on aarch64 and s390x so add it for backwards computability
            lscpu_info[:features] = lscpu_info[:flags] if lscpu_info[:architecture].match?(/aarch64|s390x/)
          end
        end

        case lscpu_info[:architecture]
        when "s390x"
          # Add data from /proc/cpuinfo that isn't available from lscpu
          lscpu_info[:bogomips_per_cpu] = cpu_info[:bogomips_per_cpu]
          lscpu_info[:version] = cpu_info["0"][:version]
          lscpu_info[:identification] = cpu_info["0"][:identification]
          lscpu_info[:machine] = cpu_info["0"][:machine]
          lscpu_total = lscpu_info[:sockets_per_book] * lscpu_info[:cores_per_socket] * lscpu_info[:threads_per_core] * lscpu_info[:books_per_drawer] * lscpu_info[:drawers]
          lscpu_real = lscpu_info[:sockets_per_book]
          lscpu_cores = lscpu_info[:sockets_per_book] * lscpu_info[:cores_per_socket] * lscpu_info[:books_per_drawer] * lscpu_info[:drawers]
        when "ppc64le"
          # Add data from /proc/cpuinfo that isn't available from lscpu
          lscpu_info[:timebase] = cpu_info[:timebase]
          lscpu_info[:platform] = cpu_info[:platform]
          lscpu_info[:machine_model] = cpu_info[:machine_model]
          lscpu_info[:machine] = cpu_info[:machine]
          lscpu_info[:firmware] = cpu_info[:firmware] if cpu_info[:firmware]
          lscpu_info[:mmu] = cpu_info[:mmu] if cpu_info[:mmu]
          lscpu_info[:mhz] = cpu_info["0"][:mhz]
          lscpu_total = lscpu_info[:sockets] * lscpu_info[:cores_per_socket] * lscpu_info[:threads_per_core]
          lscpu_real = lscpu_info[:sockets]
          lscpu_cores = lscpu_info[:sockets] * lscpu_info[:cores_per_socket]
        else
          threads_per_core = [lscpu_info[:threads_per_core], 1].max
          lscpu_total = lscpu_info[:sockets] * lscpu_info[:cores_per_socket] * threads_per_core
          lscpu_real = lscpu_info[:sockets]
          lscpu_cores = lscpu_info[:sockets] * lscpu_info[:cores_per_socket]
        end

        # Enumerate cpus and fill out data to provide backwards compatibility data
        cpu_cores.stdout.each_line do |line|
          current_cpu = nil
          current_core = nil
          current_socket = nil

          case line
          # skip comments
          when /^#/
            next
          # Parse data from "lscpu -p=CPU,CORE,SOCKET"
          when /(\d+),(\d+),(\d+)/
            current_cpu = $1
            current_core = $2
            current_socket = $3
          end
          lscpu_info[current_cpu] = Mash.new
          lscpu_info[current_cpu][:vendor_id] = lscpu_info[:vendor_id] if lscpu_info[:vendor_id]
          lscpu_info[current_cpu][:family] = lscpu_info[:family] if lscpu_info[:family]
          lscpu_info[current_cpu][:model] = lscpu_info[:model] if lscpu_info[:model]
          lscpu_info[current_cpu][:model_name] = lscpu_info[:model_name] if lscpu_info[:model_name]
          lscpu_info[current_cpu][:stepping] = lscpu_info[:stepping] if lscpu_info[:stepping]
          lscpu_info[current_cpu][:mhz] = lscpu_info[:mhz] if lscpu_info[:mhz]
          lscpu_info[current_cpu][:bogomips] = lscpu_info[:bogomips] if lscpu_info[:bogomips]
          # Per cpu cache_size is only really available from /proc/cpuinfo on x86
          lscpu_info[current_cpu][:cache_size] = cpu_info[current_cpu][:cache_size] if cpu_info[current_cpu] && cpu_info[current_cpu][:cache_size]
          lscpu_info[current_cpu][:physical_id] = current_socket
          lscpu_info[current_cpu][:core_id] = current_core
          lscpu_info[current_cpu][:cores] = lscpu_info[:cores_per_socket].to_s
          lscpu_info[current_cpu][:flags] = lscpu_info[:flags] if lscpu_info[:flags]
          lscpu_info[current_cpu][:features] = lscpu_info[:flags] if lscpu_info[:architecture].match?(/aarch64|s390x/)
          if lscpu_info[:architecture] == "s390x"
            lscpu_info[current_cpu][:version] = cpu_info[current_cpu][:version] if cpu_info[current_cpu][:version]
            lscpu_info[current_cpu][:identification] = cpu_info[current_cpu][:identification] if cpu_info[current_cpu][:identification]
            lscpu_info[current_cpu][:machine] = cpu_info[current_cpu][:machine] if cpu_info[current_cpu][:machine]
          end
        end
        lscpu_info[:total] = lscpu_total
        lscpu_info[:real] = lscpu_real
        lscpu_info[:cores] = lscpu_cores
      else
        logger.trace("Plugin CPU: Error executing lscpu. CPU data may not be available.")
      end
    rescue Ohai::Exceptions::Exec # util-linux isn't installed most likely
      logger.trace("Plugin CPU: Error executing lscpu. util-linux may not be installed.")
    end
    lscpu_info
  end

  def parse_cpuinfo
    cpuinfo = Mash.new
    real_cpu = Mash.new
    cpu_number = 0
    current_cpu = nil

    file_open("/proc/cpuinfo").each_line do |line|
      case line
      when /processor\s+:\s(.+)/
        cpuinfo[$1] = Mash.new
        current_cpu = $1
        cpu_number += 1
      when /vendor_id\s+:\s(.+)/
        vendor_id = $1
        if vendor_id.include?("IBM/S390")
          cpuinfo["vendor_id"] = vendor_id
        else
          cpuinfo[current_cpu]["vendor_id"] = vendor_id
        end
      when /cpu family\s+:\s(.+)/
        cpuinfo[current_cpu]["family"] = $1
      when /model\s+:\s(.+)/
        model = $1
        cpuinfo[current_cpu]["model"] = model
        # ppc has "model" at the end of /proc/cpuinfo. In addition it should always include a include a dash or "IBM".
        # So let's put this in cpu/model on ppc
        cpuinfo["machine_model"] = model if model.match?(/-|IBM/)
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
        cpuinfo[current_cpu]["flags"] = $1.split
      when /BogoMIPS\s+:\s(.+)/
        cpuinfo[current_cpu]["bogomips"] = $1
      when /Features\s+:\s(.+)/
        cpuinfo[current_cpu]["features"] = $1.split
      when /bogomips per cpu:\s(.+)/
        cpuinfo["bogomips_per_cpu"] = $1
      when /features\s+:\s(.+)/
        cpuinfo["features"] = $1.split
      # ppc64le
      when /revision\s+:\s(.+)/
        cpuinfo[current_cpu]["model"] = $1
      when /cpu\s+:\s(.+)/
        cpuinfo[current_cpu]["model_name"] = $1
      when /clock\s+:\s(.+)/
        cpuinfo[current_cpu]["mhz"] = $1
      when /timebase\s+:\s(.+)/
        cpuinfo["timebase"] = $1
      when /platform\s+:\s(.+)/
        cpuinfo["platform"] = $1
      when /machine\s+:\s(.+)/
        cpuinfo["machine"] = $1
      when /firmware\s+:\s(.+)/
        cpuinfo["firmware"] = $1
      when /MMU\s+:\s(.+)/
        cpuinfo["mmu"] = $1
      # s390x
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

    # use data we collected unless cpuinfo is lacking core information
    # which is the case on older linux distros
    if !real_cpu.empty? && cpuinfo["0"]["cores"]
      logger.trace("Plugin CPU: Error executing lscpu. CPU data may not be available.")
      cpuinfo[:real] = real_cpu.keys.length
      cpuinfo[:cores] = real_cpu.keys.length * cpuinfo["0"]["cores"].to_i
    else
      logger.trace("Plugin CPU: real cpu & core data is missing in /proc/cpuinfo and lscpu")
    end
    cpuinfo[:total] = cpu_number
    cpuinfo
  end

  # Check if the `lscpu` data looks reasonable
  def valid_lscpu?(lscpu)
    return false if lscpu.empty?
    return false if %i{total real cores}.any? { |key| lscpu[key].to_i == 0 }

    true
  end

  collect_data(:linux) do
    cpuinfo = parse_cpuinfo
    lscpu = parse_lscpu(cpuinfo)

    # If we don't have any sensible data from lscpu then get it from /proc/cpuinfo
    if valid_lscpu?(lscpu)
      cpu lscpu
    else
      cpu cpuinfo
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
    info[:total] = so.stdout.strip.to_i
    cpu info
  end

  collect_data(:openbsd) do
    cpuinfo = Mash.new

    # OpenBSD provides most cpu information via sysctl, the only thing we need to
    # to scrape from dmesg.boot is the cpu feature list.
    # cpu0: FPU,V86,DE,PSE,TSC,MSR,MCE,CX8,SEP,MTRR,PGE,MCA,CMOV,PAT,CFLUSH,DS,ACPI,MMX,FXSR,SSE,SSE2,SS,TM,SBF,EST,TM2

    file_open("/var/run/dmesg.boot").each do |line|
      case line
      when /cpu\d+:\s+([A-Z]+$|[A-Z]+,.*$)/
        cpuinfo["flags"] = $1.downcase.split(",")
      end
    end

    [["hw.model", :model_name], ["hw.ncpu", :total], ["hw.cpuspeed", :mhz]].each do |param, node|
      so = shell_out("sysctl -n #{param}")
      cpuinfo[node] = so.stdout.strip
    end

    cpu cpuinfo
  end

  collect_data(:netbsd) do
    cpuinfo = Mash.new

    # NetBSD provides some cpu information via sysctl, and a little via dmesg.boot
    # unlike OpenBSD and FreeBSD, NetBSD does not provide information about the
    # available instruction set
    # cpu0 at mainbus0 apid 0: Intel 686-class, 2134MHz, id 0x6f6

    file_open("/var/run/dmesg.boot").each do |line|
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
        cpu[:flags] = Regexp.last_match[1].downcase.split
      end
    end
  end

  collect_data(:aix) do
    cpu Mash.new

    cpu[:total] = shell_out("pmcycles -m").stdout.lines.length

    # The below is only relevant on an LPAR
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
        if status.include?("Available")
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
    require "wmi-lite/wmi" unless defined?(WmiLite::Wmi)

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
