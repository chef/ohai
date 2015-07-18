
$:.unshift File.expand_path('../lib', __FILE__)
require 'ohai/version'

Gem::Specification.new do |s|
  s.name = "ohai"
  s.version = Ohai::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "Ohai profiles your system and emits JSON"
  s.description = s.summary
  s.license = "Apache-2.0"
  s.author = "Adam Jacob"
  s.email = "adam@chef.io"
  s.homepage = "https://docs.chef.io/ohai.html"

  s.required_ruby_version = ">= 2.0.0"

  s.add_dependency "mime-types", "~> 2.0"
  s.add_dependency "systemu", "~> 2.6.4"
  s.add_dependency "ffi-yajl", "~> 2.2"
  s.add_dependency "mixlib-cli"
  s.add_dependency "mixlib-config", "~> 2.0"
  s.add_dependency "mixlib-log"
  s.add_dependency "mixlib-shellout", "~> 2.0"
  s.add_dependency "ipaddress"
  s.add_dependency "wmi-lite", "~> 1.0"
  s.add_dependency "ffi", "~> 1.9"

  s.add_dependency "rake", "~> 10.1"
  s.add_development_dependency "rspec-core", "~> 3.0"
  s.add_development_dependency "rspec-expectations", "~> 3.0"
  s.add_development_dependency "rspec-mocks", "~> 3.0"
  s.add_development_dependency "rspec-collection_matchers", "~> 1.0"
  s.add_development_dependency "rspec_junit_formatter"
  s.add_development_dependency "chef"
  s.bindir = "bin"
  s.executables = %w(ohai)

  s.require_path = 'lib'
  s.files = %w(LICENSE README.md Rakefile) + Dir.glob("{docs,lib,spec}/**/*")
end
