#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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


require File.join(File.dirname(__FILE__),  '..', '..', '..', '/spec_helper.rb')

describe Ohai::System, "Linux plugin platform" do
  before(:each) do
    @ohai = Ohai::System.new    
    @ohai.stub!(:require_plugin).and_return(true)
    @ohai[:os] = "linux"
    @ohai[:lsb] = Mash.new
  end
  
  it "should require the lsb plugin" do
    @ohai.should_receive(:require_plugin).with("linux::lsb").and_return(true)  
    @ohai._require_plugin("linux::platform")
  end
  
  describe "on lsb compliant distributions" do
    before(:each) do
      @ohai[:lsb][:id] = "Ubuntu"
      @ohai[:lsb][:release] = "8.04"
    end
    
    it "should set platform to lowercased lsb[:id]" do
      @ohai._require_plugin("linux::platform")        
      @ohai[:platform].should == "ubuntu"
    end
    
    it "should set platform_version to lsb[:release]" do
      @ohai._require_plugin("linux::platform")
      @ohai[:platform_version].should == "8.04"
    end
  end
end  
