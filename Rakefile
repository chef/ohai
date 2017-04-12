require "bundler/gem_tasks"
require "date"
require "ohai/version"

begin
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new do |t|
    t.pattern = "spec/**/*_spec.rb"
  end
rescue LoadError
  desc "rspec is not installed, this task is disabled"
  task :spec do
    abort "rspec is not installed. `(sudo) gem install rspec` to run unit tests"
  end
end

task :default => :spec

require "chefstyle"
require "rubocop/rake_task"
RuboCop::RakeTask.new(:style) do |task|
  task.options += ["--display-cop-names", "--no-color"]
end

begin
  require "github_changelog_generator/task"

  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.future_release = Ohai::VERSION
    config.max_issues = 0
    config.add_issues_wo_labels = false
  end
rescue LoadError
end
