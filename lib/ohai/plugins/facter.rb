require 'rubygems'

begin
  require 'facter'
  Facter.each do |name, value|
    set_attribute("facter_#{name}", value)
  end
rescue Exception => e
  Ohai::Log.debug("Skipping facter facts, as facter is not installed")
end




