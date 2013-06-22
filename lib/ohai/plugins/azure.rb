
provides "azure"


azure_metadata_from_hints = hint?('azure')
if azure_metadata_from_hints
  Ohai::Log.debug("azure_metadata_from_hints is present.")
  azure Mash.new
  azure_metadata_from_hints.each {|k, v| azure[k] = v }
else
  Ohai::Log.debug("No hints present for azure.")
  false
end