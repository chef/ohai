Ohai.plugin(:Counters) do
  provides "counters"

  collect_data do
    counters Mash.new
  end
end
