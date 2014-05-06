provides "swap"

swaps = Mash.new

File.open('/proc/swaps').read_nonblock(4096).each_line do |line|
  next if line =~ /^Filename/

  parts = line.split
  device = parts[0]
  swaps[device] = Mash.new
  swaps[device][:type] = parts[1]
  swaps[device][:size] = parts[2].to_i
  swaps[device][:used] = parts[3].to_i
  swaps[device][:priority] = parts[4].to_i
end

swap swaps
