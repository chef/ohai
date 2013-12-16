source "https://rubygems.org"

gemspec

group :development do

  # Fixes https://tickets.opscode.com/browse/MIXLIB-17
  # This line can be removed and replaced with a line in the gemspec that specifies
  #   that the mixlib::shellout version be > 1.2.0
  gem "mixlib-shellout", :git => "https://github.com/opscode/mixlib-shellout.git"

  gem "sigar", :platform => "ruby"
  gem 'plist'

  gem 'pry-debugger'
  # gem 'pry-stack_explorer'
end


