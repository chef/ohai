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

describe Ohai::System, "plugin platform" do
  before(:each) do
    @ohai = Ohai::System.new    
    @plugin = Ohai::DSL::Plugin.new(@ohai, File.join(PLUGIN_PATH, "platform.rb"))
    @plugin.stub!(:require_plugin).and_return(true)
    @plugin[:os] = 'monkey'
    @plugin[:os_version] = 'poop'
  end
  
  it "should require the os platform plugin" do
    @plugin.should_receive(:require_plugin).with("monkey::platform")
    @plugin.run
  end
  
  it "should set the platform and platform family to the os if it was not set earlier" do
    @plugin.run
    @plugin[:platform].should eql("monkey")
    @plugin[:platform_family].should eql("monkey")
  end
  
  it "should not set the platform to the os if it was set earlier" do
    @plugin[:platform] = 'lars'
    @plugin.run
    @plugin[:platform].should eql("lars")
  end
  
  it "should set the platform_family to the platform if platform was set earlier but not platform_family" do
    @plugin[:platform] = 'lars'
    @plugin[:platform_family] = 'jack'
    @plugin.run
    @plugin[:platform_family].should eql("jack")
  end
 
  it "should not set the platform_family if the platform_family was set earlier." do
    @plugin[:platform] = 'lars'
    @plugin.run
    @plugin[:platform].should eql("lars")
    @plugin[:platform_family].should eql("lars")
  end

  it "should set the platform_version to the os_version if it was not set earlier" do
    @plugin.run
    @plugin[:os_version].should eql("poop")
  end
  
  it "should not set the platform to the os if it was set earlier" do
    @plugin[:platform_version] = 'ulrich'
    @plugin.run
    @plugin[:platform_version].should eql("ulrich")
  end
end
