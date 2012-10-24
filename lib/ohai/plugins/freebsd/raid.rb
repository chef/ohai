provides 'raid/devices'

raid Mash.new

# sample data
#ciss0@pci0:3:0:0:       class=0x010400 card=0x3245103c chip=0x323a103c rev=0x01 hdr=0x00
#    vendor     = 'Hewlett-Packard Company'
#    device     = 'Smart Array P410i Controller (Smart Array P410i Controller)'
#    class      = mass storage
#    subclass   = RAID

# A few vars to rule them all
devices=Array.new
re_id=Regexp.new(".*@pci(.*):\.*")
re_vendor=Regexp.new("vendor.*= '(.*)'")
re_device=Regexp.new("device.*= '(.*)'")
indexes=Array.new
lines=Array.new

# hack around pciconf, as output is multiline and non filterable per class
# One loop to find them all
`/usr/sbin/pciconf -lv`.each_line { |l|
  lines.push l.chomp
}

# find where raid devices hide themselves (with their class ID)
# One loop to bring them all
lines.each { |line|
	if line =~ /class=0x010400/ then
		indexes.push(lines.index line)
  end
}

# extract meaningfull data
# And in the darkness, bind them
indexes.each { |i|
  data=Hash.new
  data[:pciid]=re_id.match(lines[i])[1]
  data[:vendor]=re_vendor.match(lines[i+1])[1]
  data[:fulldescription] = re_device.match(lines[i+2])[1]
  devices.push(data)
}

raid[:devices]=devices
