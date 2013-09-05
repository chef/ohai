# Add cpu to Ohai, it is not implemented for SmartOS in Ohai
provides "cpu"

cpu Mash.new
cpu[:total] = `psrinfo | wc -l`.chomp.to_i
cpu[:real]  = `psrinfo -p`.chomp.to_i
