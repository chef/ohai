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


require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "Darwin plugin platform" do
  before(:each) do
    @plugin = get_plugin("darwin/platform")
    @plugin.stub(:collect_os).and_return(:darwin)
    @stdout = "ProductName:	Mac OS X\nProductVersion:	10.5.5\nBuildVersion:	9F33"
    @plugin.stub(:shell_out).with("/usr/bin/sw_vers").and_return(mock_shell_out(0, @stdout, ""))
  end

  it "should run sw_vers" do
    @plugin.should_receive(:shell_out).with("/usr/bin/sw_vers").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
  end

  it "should set platform to ProductName, downcased with _ for \\s" do
    @plugin.run
    @plugin[:platform].should == "mac_os_x"
  end
  
  it "should set platform_version to ProductVersion" do
    @plugin.run
    @plugin[:platform_version].should == "10.5.5"
  end
  
  it "should set platform_build to BuildVersion" do
    @plugin.run
    @plugin[:platform_build].should == "9F33"
  end

  it "should set platform_family to mac_os_x" do
    @plugin.run
    @plugin[:platform_family].should == "mac_os_x"
  end

  describe "on os x server" do
    before(:each) do
      @plugin[:os] = "darwin"
      @stdout = "ProductName:	Mac OS X Server\nProductVersion:	10.6.8\nBuildVersion:	10K549"
      @plugin.stub(:shell_out).with("/usr/bin/sw_vers").and_return(mock_shell_out(0, @stdout, ""))
    end

    it "should set platform to mac_os_x_server" do
      @plugin.run
      @plugin[:platform].should == "mac_os_x_server"
    end

    it "should set platform_family to mac_os_x" do
      @plugin.run
      @plugin[:platform_family].should == "mac_os_x"
    end
  end
end
