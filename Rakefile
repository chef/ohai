require 'rubygems'
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'date'

gemspec = eval(IO.read("ohai.gemspec"))


Rake::GemPackageTask.new(gemspec).define

desc "install the gem locally"
task :install => [:package] do
  sh %{gem install pkg/#{ohai}-#{OHAI_VERSION}}
end

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new do |t|
    t.pattern = 'spec/**/*_spec.rb'
    t.rspec_opts = %w(-fs --color)
  end
rescue LoadError
  desc "rspec is not installed, this task is disabled"
  task :spec do
    abort "rspec is not installed. `(sudo) gem install rspec` to run unit tests"
  end
end

task :default => :spec
