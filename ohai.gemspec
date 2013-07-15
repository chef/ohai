
$:.unshift File.expand_path('../lib', __FILE__)
require 'ohai/version'

Gem::Specification.new do |s|
  s.name = "ohai"
  s.version = Ohai::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "Ohai profiles your system and emits JSON"
  s.description = s.summary
  s.author = "Adam Jacob"
  s.email = "adam@opscode.com"
  s.homepage = "http://wiki.opscode.com/display/chef/Ohai"

  # This only helps with bundler because otherwise we make a dependency based
  # on what platform we are building a gem on, not what platform we are
  # installing it on.
  if RUBY_PLATFORM =~ /mswin|mingw|windows/
    s.add_dependency "systemu", "~> 2.2.0"
  else
    s.add_dependency "systemu"
  end

  s.add_dependency "yajl-ruby"
  s.add_dependency "mixlib-cli"
  s.add_dependency "mixlib-config"
  s.add_dependency "mixlib-log"
  s.add_dependency "mixlib-shellout"
  s.add_dependency "ipaddress"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec-core"
  s.add_development_dependency "rspec-expectations"
  s.add_development_dependency "rspec-mocks"
  s.add_development_dependency "rspec_junit_formatter"
  s.add_development_dependency "chef"
  s.bindir = "bin"
  s.executables = %w(ohai)

  s.require_path = 'lib'
  s.files = %w(LICENSE README.rdoc Rakefile) + Dir.glob("{docs,lib,spec}/**/*")
end
