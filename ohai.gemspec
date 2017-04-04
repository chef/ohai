
$:.unshift File.expand_path("../lib", __FILE__)
require "ohai/version"

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

  s.required_ruby_version = ">= 2.3"

  s.add_dependency "systemu", "~> 2.6.4"
  s.add_dependency "ffi-yajl", "~> 2.2"
  s.add_dependency "mixlib-cli"
  s.add_dependency "mixlib-config", "~> 2.0"
  s.add_dependency "mixlib-log", ">= 1.7.1", "< 2.0"
  s.add_dependency "mixlib-shellout", "~> 2.0"
  s.add_dependency "plist", "~> 3.1"
  s.add_dependency "ipaddress"
  s.add_dependency "wmi-lite", "~> 1.0"
  s.add_dependency "ffi", "~> 1.9"
  s.add_dependency "chef-config", ">= 12.5.0.alpha.1", "< 14"
  # Note for ohai developers: If chef-config causes you grief, try:
  #     bundle install --with development
  # this should work as long as chef is a development dependency in Gemfile.
  #

  s.bindir = "bin"
  s.executables = %w{ohai}

  s.require_path = "lib"
  s.files = %w{LICENSE README.md Gemfile Rakefile} + Dir.glob("*.gemspec") + Dir.glob("{docs,lib,spec}/**/*")
end
