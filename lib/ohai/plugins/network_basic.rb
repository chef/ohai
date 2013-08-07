Ohai.plugin(:NetworkBasic) do
  provides "network", "network/interfaces", "counters/network"
  depends "counters"

  collect_data do
    network Mash.new
    network[:interfaces] = Mash.new
    counters[:network] = Mash.new
  end
end
