require 'rspec'

require 'pry-debugger'
# require 'pry-stack_explorer'

$:.unshift(File.expand_path("../..", __FILE__))
$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'spec/support/platform_helpers'
require 'spec/support/integration_helper'
require 'ohai'
Ohai::Config[:log_level] = :error

PLUGIN_PATH = File.expand_path("../../lib/ohai/plugins", __FILE__)
SPEC_PLUGIN_PATH = File.expand_path("../data/plugins", __FILE__)

RSpec.configure do |config|
  config.before(:each) { @object_pristine = Object.clone }
  config.after(:each) { remove_constants }
end

def remove_constants
  new_object_constants = Object.constants - @object_pristine.constants
  new_object_constants.each do |constant|
    Object.send(:remove_const, constant) unless Object.const_get(constant).is_a?(Module)
  end

  recursive_remove_constants(Ohai::NamedPlugin)
end

def recursive_remove_constants(object)
  if object.respond_to?(:constants)
    object.constants.each do |const|
      next unless strict_const_defined?(object, const)
      recursive_remove_constants(object.const_get(const))
      object.send(:remove_const, const)
    end
  end
end

def strict_const_defined?(object, const)
  if object.method(:const_defined?).arity == 1
    object.const_defined?(const)
  else
    object.const_defined?(const, false)
  end
end

if Ohai::Mixin::OS.collect_os == /mswin|mingw32|windows/
  ENV["PATH"] = ""
end

def get_plugin(plugin, ohai = Ohai::System.new, path = PLUGIN_PATH)
  loader = Ohai::Loader.new(ohai)
  loader.load_plugin(File.join(path, "#{plugin}.rb"))
end

def it_should_check_from(plugin, attribute, from, value)
  it "should set the #{attribute} to the value from '#{from}'" do
    @plugin.run
    @plugin[attribute].should == value
  end
end

def it_should_check_from_mash(plugin, attribute, from, value)
  it "should get the #{plugin}[:#{attribute}] value from '#{from}'" do
    @plugin.should_receive(:shell_out).with(from).and_return(mock_shell_out(value[0], value[1], value[2]))
    @plugin.run
  end

  it "should set the #{plugin}[:#{attribute}] to the value from '#{from}'" do
    @plugin.run
    @plugin[plugin][attribute].should == value[1].split($/)[0]
  end
end

def mock_shell_out(exitstatus, stdout, stderr)
  shell_out = double("mixlib_shell_out")
  shell_out.stub(:exitstatus).and_return(exitstatus)
  shell_out.stub(:stdout).and_return(stdout)
  shell_out.stub(:stderr).and_return(stderr)
  shell_out
end

# the mash variable may be an array listing multiple levels of Mash hierarchy
def it_should_check_from_deep_mash(plugin, mash, attribute, from, value)
  it "should get the #{mash.inspect}[:#{attribute}] value from '#{from}'" do
    @plugin.should_receive(:shell_out).with(from).and_return(mock_shell_out(value[0], value[1], value[2]))
    @plugin.run
  end

  it "should set the #{mash.inspect}[:#{attribute}] to the value from '#{from}'" do
    @plugin.run
    value = value[1].split($/)[0]
    if mash.is_a?(String)
      @plugin[mash][attribute].should == value
    elsif mash.is_a?(Array)
      if mash.length == 2
        @plugin[mash[0]][mash[1]][attribute].should == value
      elsif mash.length == 3
        @plugin[mash[0]][mash[1]][mash[2]][attribute].should == value
      else
        return nil
      end
    else
      return nil
    end
  end
end

module SimpleFromFile
  def from_file(filename)
    self.instance_eval(IO.read(filename), filename, 1)
  end
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.filter_run :focus => true

  config.filter_run_excluding :windows_only => true unless windows?
  config.filter_run_excluding :unix_only => true unless unix?
  config.filter_run_excluding :ruby_18_only => true unless ruby_18?
  config.filter_run_excluding :ruby_19_only => true unless ruby_19?
  config.filter_run_excluding :requires_root => true unless ENV['USER'] == 'root'
  config.filter_run_excluding :requires_unprivileged_user => true if ENV['USER'] == 'root'

  config.run_all_when_everything_filtered = true

  config.before :each do
    Ohai::Config.reset
  end
end
