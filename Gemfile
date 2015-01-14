source "https://rubygems.org"

gemspec

# https://github.com/sj26/rspec_junit_formatter/pull/14
# rspec_junit_formatter isn't compatible with RSpec3 yet, but is fixed in
# master. Once it's released we should remove this.
gem "rspec_junit_formatter", :git => 'git://github.com/sj26/rspec_junit_formatter.git',
                             :ref => "147836c41fab23ff7b92806f34122c8e5f2ddcad"

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("1.9.3")
  gem "mixlib-shellout", "~> 1.4.0"
end

group :development do

  gem "sigar", :platform => "ruby"
  gem 'plist'

  # gem 'pry-debugger'
  # gem 'pry-stack_explorer'
end


