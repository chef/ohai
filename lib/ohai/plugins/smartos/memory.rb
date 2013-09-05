# Add cpu to Ohai, it is not implemented for SmartOS in Ohai
provides "memory"

memory Mash.new
memory[:total] = `prtconf -m`.chomp.to_i
