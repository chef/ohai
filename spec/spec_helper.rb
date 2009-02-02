begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'ohai'
Ohai::Config[:log_level] = :error

def it_should_check_from(plugin, attribute, from, value)
  it "should get the #{attribute} value from '#{from}'" do
    @ohai.should_receive(:from).with(from).and_return(value)
    @ohai._require_plugin(plugin)
  end
  
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

def it_should_check_from_deep_mash(plugin, mash, attribute, from, value)
  it "should get the #{mash}[:#{attribute}] value from '#{from}'" do
    @ohai.should_receive(:from).with(from).and_return(value)
    @ohai._require_plugin(plugin)
  end
  
  it "should set the #{mash}[:#{attribute}] to the value from '#{from}'" do
    @ohai._require_plugin(plugin)
    @ohai[mash][attribute].should == value
  end
end

module SimpleFromFile
  def from_file(filename)
    self.instance_eval(IO.read(filename), filename, 1)
  end
end
