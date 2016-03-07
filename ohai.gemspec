
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

  s.required_ruby_version = ">= 2.0.0"

  s.add_dependency "systemu", "~> 2.6.4"
  s.add_dependency "ffi-yajl", "~> 2.2"
  s.add_dependency "mixlib-cli"
  s.add_dependency "mixlib-config", "~> 2.0"
  s.add_dependency "mixlib-log"
  s.add_dependency "mixlib-shellout", "~> 2.0"
  s.add_dependency "plist"
  s.add_dependency "ipaddress"
  s.add_dependency "wmi-lite", "~> 1.0"
  s.add_dependency "ffi", "~> 1.9"
  # Note for ohai developers: If chef-config causes you grief, try:
  #     bundle install --with development
  # this should work as long as chef is a development dependency in Gemfile.
  #
  # Chef depends on ohai and chef-config. Ohai depends on chef-config. The
  # version of chef-config that chef depends on is whatver version chef
  # happens to be on master. This will need to be updated again once work on
  # Chef 13 starts, otherwise builds will break.
  s.add_dependency "chef-config", ">= 12.5.0.alpha.1", "< 13"

  s.add_dependency "rake", "~> 10.1"
  s.add_development_dependency "rspec-core", "~> 3.0"
  s.add_development_dependency "rspec-expectations", "~> 3.0"
  s.add_development_dependency "rspec-mocks", "~> 3.0"
  s.add_development_dependency "rspec-collection_matchers", "~> 1.0"
  s.add_development_dependency "rspec_junit_formatter"
  s.add_development_dependency "github_changelog_generator", "1.11.3"

  s.bindir = "bin"
  s.executables = %w{ohai}

  s.require_path = "lib"
  s.files = %w{LICENSE README.md Gemfile Rakefile} + Dir.glob("*.gemspec") + Dir.glob("{docs,lib,spec}/**/*")
end
