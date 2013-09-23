require 'rspec'

$:.unshift(File.expand_path("../..", __FILE__))
$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'spec/support/platform_helpers'
require 'ohai'
Ohai::Config[:log_level] = :error

def it_should_check_from(plugin, attribute, from, value)
  it "should set the #{attribute} to the value from '#{from}'" do
    @ohai._require_plugin(plugin)
    @ohai[attribute].should == value
  end
end

def it_should_check_from_mash(plugin, attribute, from, value)
  it "should get the #{plugin}[:#{attribute}] value from '#{from}'" do
    @ohai.should_receive(:from).with(from).and_return(value)
    @ohai._require_plugin(plugin)
  end

  it "should set the #{plugin}[:#{attribute}] to the value from '#{from}'" do
    @ohai._require_plugin(plugin)
    @ohai[plugin][attribute].should == value
  end
end

# the mash variable may be an array listing multiple levels of Mash hierarchy
def it_should_check_from_deep_mash(plugin, mash, attribute, from, value)
  it "should get the #{mash.inspect}[:#{attribute}] value from '#{from}'" do
    @ohai.should_receive(:from).with(from).and_return(value)
    @ohai._require_plugin(plugin)
  end

  it "should set the #{mash.inspect}[:#{attribute}] to the value from '#{from}'" do
    @ohai._require_plugin(plugin)
    if mash.is_a?(String)
      @ohai[mash][attribute].should == value
    elsif mash.is_a?(Array)
      if mash.length == 2
        @ohai[mash[0]][mash[1]][attribute].should == value
      elsif mash.length == 3
        @ohai[mash[0]][mash[1]][mash[2]][attribute].should == value
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

  config.filter_run_excluding :windows_only => true unless windows?
  config.filter_run_excluding :unix_only => true unless unix?
  config.filter_run_excluding :ruby_18_only => true unless ruby_18?
  config.filter_run_excluding :ruby_19_only => true unless ruby_19?
  config.filter_run_excluding :requires_root => true unless ENV['USER'] == 'root'
  config.filter_run_excluding :requires_unprivileged_user => true if ENV['USER'] == 'root'
end
