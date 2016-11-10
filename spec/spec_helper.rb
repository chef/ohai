require "rspec/collection_matchers"

# require 'pry-debugger'
# require 'pry-stack_explorer'

$:.unshift(File.expand_path("../..", __FILE__))
$:.unshift(File.dirname(__FILE__) + "/../lib")

require "spec/support/platform_helpers"
require "spec/support/integration_helper"
require "wmi-lite"
require "ohai"
Ohai.config[:log_level] = :error

PLUGIN_PATH = File.expand_path("../../lib/ohai/plugins", __FILE__)
SPEC_PLUGIN_PATH = File.expand_path("../data/plugins", __FILE__)

RSpec.configure do |config|
  config.before(:each) { @object_pristine = Object.clone }
  config.after(:each) { remove_constants }
end

include Ohai::Mixin::ConstantHelper

if Ohai::Mixin::OS.collect_os == /mswin|mingw32|windows/
  ENV["PATH"] = ""
end

def get_plugin(plugin, ohai = Ohai::System.new, path = PLUGIN_PATH)
  loader = Ohai::Loader.new(ohai)
  loader.load_plugin(File.join(path, "#{plugin}.rb"))
end

def convert_windows_output(stdout)
  stdout.gsub("\n", "\r\n")
end

def it_should_check_from(plugin, attribute, from, value)
  it "should set the #{attribute} to the value from '#{from}'" do
    @plugin.run
    expect(@plugin[attribute]).to eq(value)
  end
end

def it_should_check_from_mash(plugin, attribute, from, value)
  it "should get the #{plugin}[:#{attribute}] value from '#{from}'" do
    expect(@plugin).to receive(:shell_out).with(from).and_return(mock_shell_out(value[0], value[1], value[2]))
    @plugin.run
  end

  it "should set the #{plugin}[:#{attribute}] to the value from '#{from}'" do
    @plugin.run
    expect(@plugin[plugin][attribute]).to eq(value[1].split($/)[0])
  end
end

def mock_shell_out(exitstatus, stdout, stderr)
  shell_out = double("mixlib_shell_out")
  allow(shell_out).to receive(:exitstatus).and_return(exitstatus)
  allow(shell_out).to receive(:stdout).and_return(stdout)
  allow(shell_out).to receive(:stderr).and_return(stderr)
  shell_out
end

# the mash variable may be an array listing multiple levels of Mash hierarchy
def it_should_check_from_deep_mash(plugin, mash, attribute, from, value)
  it "should get the #{mash.inspect}[:#{attribute}] value from '#{from}'" do
    expect(@plugin).to receive(:shell_out).with(from).and_return(mock_shell_out(value[0], value[1], value[2]))
    @plugin.run
  end

  it "should set the #{mash.inspect}[:#{attribute}] to the value from '#{from}'" do
    @plugin.run
    value = value[1].split($/)[0]
    if mash.is_a?(String)
      expect(@plugin[mash][attribute]).to eq(value)
    elsif mash.is_a?(Array)
      if mash.length == 2
        expect(@plugin[mash[0]][mash[1]][attribute]).to eq value
      elsif mash.length == 3
        expect(@plugin[mash[0]][mash[1]][mash[2]][attribute]).to eq value
      else
        return nil
      end
    else
      return nil
    end
  end
end

RSpec.configure do |config|

  # Not worth addressing warnings in Ohai until upstream ones in ffi-yajl are
  # fixed.
  # config.warnings = true

  config.raise_errors_for_deprecations!

  # `expect` should be preferred for new tests or when refactoring old tests,
  # but we're not going to do a "big bang" change at this time.
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run :focus => true

  config.filter_run_excluding :windows_only => true unless windows?
  config.filter_run_excluding :unix_only => true unless unix?
  config.filter_run_excluding :requires_root => true unless ENV["USER"] == "root"
  config.filter_run_excluding :requires_unprivileged_user => true if ENV["USER"] == "root"

  config.run_all_when_everything_filtered = true

  config.before :each do
    # TODO: Change to Ohai.config once Ohai::Config is deprecated fully. Needs
    # to stay Ohai::Config for now so that top-level attributes will get cleared
    # out between tests (config_spec should be the only place where top-level
    # config attributes are set).
    Ohai::Config.reset
  end
end
