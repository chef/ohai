#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Tollef Fog Heen <tfheen@err.no>
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# Copyright:: Copyright (c) 2010 Tollef Fog Heen <tfheen@err.no>
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

begin
  require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
  
  require 'chef/version'
  
  describe Ohai::System, "plugin chef" do
    before(:each) do
      @ohai = Ohai::System.new
      @ohai.stub!(:require_plugin).and_return(true)
    end
    
    it "should set [:chef_packages][:chef][:version] to the current chef version", :if => defined?(Chef) do
      @ohai._require_plugin("chef")
      @ohai[:chef_packages][:chef][:version].should == Chef::VERSION
    end
  
    pending "would set [:chef_packages][:chef][:version] if chef was available", :unless => defined?(Chef)
  
  end
rescue LoadError
  # the chef module is not available, ignoring.

  describe Ohai::System, "plugin chef" do
    pending "would set [:chef_packages][:chef][:version] if chef was available", :unless => defined?(Chef)
  end
end
