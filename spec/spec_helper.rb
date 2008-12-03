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