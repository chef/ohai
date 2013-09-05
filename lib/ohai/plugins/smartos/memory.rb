# Add cpu to Ohai, it is not implemented for SmartOS in Ohai
Ohai.plugin.do
  provides "memory"

  collect_data do
    memory Mash.new
    memory[:total] = `prtconf -m`.chomp.to_i
  end
end
