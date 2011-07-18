provides "cpu"

cpuinfo = Mash.new
real_cpu = Mash.new

`sysctl -a hw`.each_line do |line|
  case line
  when /hw.ncpu: (\d+)/
    cpu[:total] = $1
  when /hw.physicalcpu: (\d+)/
    cpu[:real] = $1
  else
    puts "Unhandled line: #{line}"
  end
end
cpu cpuinfo
cpu[:total] = 2
cpu[:real] = 2
