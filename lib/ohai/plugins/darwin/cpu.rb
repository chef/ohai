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
  when /hw.ncpu: (\d+)/
    cpuinfo[:total] = $1
  when /hw.physicalcpu: (\d+)/
    cpuinfo[:real] = $1
  else
    puts "Unhandled line: #{line}"
  end
end
cpu cpuinfo

#testing
cpu[:total] = 2
cpu[:real] = 2
