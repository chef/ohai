require 'rubygems'
require 'date'

begin
  require 'bundler'
  Bundler::GemHelper.install_tasks
rescue LoadError
  $stderr.puts "You should install Bundler with: gem install bundler"
end

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new do |t|
    t.pattern = 'spec/**/*_spec.rb'
  end
rescue LoadError
  desc "rspec is not installed, this task is disabled"
  task :spec do
    abort "rspec is not installed. `(sudo) gem install rspec` to run unit tests"
  end
end

task :default => :spec
