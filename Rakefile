require "bundler/gem_tasks"
require 'date'
require 'ohai/version'

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new do |t|
    t.pattern = 'spec/**/*_spec.rb'
  end

  require 'github_changelog_generator/task'

  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.token = ENV['GITHUB_CHANGELOG_TOKEN']
    config.future_release = Ohai::VERSION
    config.enhancement_labels = "enhancement,Enhancement,New Feature".split(",")
    config.bug_labels = "bug,Bug,Improvement,Upstream Bug".split(",")
    config.exclude_labels = "duplicate,question,invalid,wontfix,no_changelog".split(",")
  end

rescue LoadError
  desc "rspec is not installed, this task is disabled"
  task :spec do
    abort "rspec is not installed. `(sudo) gem install rspec` to run unit tests"
  end
end

task :default => :spec
