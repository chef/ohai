# Add cpu to Ohai, it is not implemented for SmartOS in Ohai
Ohai.plugin do
  provides "cpu"

  collect_data do
    cpu Mash.new
    cpu[:total] = `psrinfo | wc -l`.chomp.to_i
    cpu[:real]  = `psrinfo -p`.chomp.to_i
  end
end
