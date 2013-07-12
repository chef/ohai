#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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


require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

ORIGINAL_CONFIG_HOST_OS = ::RbConfig::CONFIG['host_os']

describe Ohai::System, "plugin os" do
  before(:each) do
    @ohai = Ohai::System.new    
    @plugin = Ohai::DSL::Plugin.new(@ohai, File.join(PLUGIN_PATH, "os.rb"))
    @plugin.stub!(:require_plugin).and_return(true)
    @plugin[:languages] = Mash.new
    @plugin[:languages][:ruby] = Mash.new
    @plugin[:kernel] = Mash.new
    @plugin[:kernel][:release] = "kings of leon"
  end
  
  after do
    ::RbConfig::CONFIG['host_os'] = ORIGINAL_CONFIG_HOST_OS
  end

  it "should set os_version to kernel_release" do
    @plugin.run
    @plugin[:os_version].should == @plugin[:kernel][:release]
  end
  
  describe "on linux" do
    before(:each) do
      ::RbConfig::CONFIG['host_os'] = "linux"
    end
    
    it "should set the os to linux" do
      @plugin.run
      @plugin[:os].should == "linux"
    end
  end
  
  describe "on darwin" do
    before(:each) do
      ::RbConfig::CONFIG['host_os'] = "darwin10.0"
    end
    
    it "should set the os to darwin" do
      @plugin.run
      @plugin[:os].should == "darwin"
    end
  end
  
  describe "on solaris" do
    before do
      ::RbConfig::CONFIG['host_os'] = "solaris2.42" #heh
    end
    
    it "sets the os to solaris2" do
      @plugin.run
      @plugin[:os].should == "solaris2"
    end
  end

  describe "on something we have never seen before, but ruby has" do
    before do
      ::RbConfig::CONFIG['host_os'] = "tron"
    end

    it "sets the os to the ruby 'host_os'" do
      @plugin.run
      @plugin[:os].should == "tron"
    end
  end
end
