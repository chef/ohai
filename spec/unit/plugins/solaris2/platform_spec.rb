#
# Author:: Trevor O (<trevoro@joyent.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

describe Ohai::System, "Solaris plugin platform" do
  before(:each) do
    @ohai = Ohai::System.new
    @plugin = Ohai::DSL::Plugin.new(@ohai, File.expand_path("solaris2/platform.rb", PLUGIN_PATH))
    @plugin.extend(SimpleFromFile)
    @plugin.stub!(:require_plugin).and_return(true)
    @plugin[:os] = "solaris2"
    @plugin.stub!(:popen4).with("/sbin/uname -X")
  end
  
  describe "on SmartOS" do
    before(:each) do
      uname_x = <<-UNAME_X
System = SunOS
Node = node.example.com
Release = 5.11
KernelID = joyent_20120130T201844Z
Machine = i86pc
BusType = <unknown>
Serial = <unknown>
Users = <unknown>
OEM# = 0
Origin# = 1
NumCPU = 16
UNAME_X
      @stdin = mock("STDIN", { :close => true })
      @pid = 10
      @stderr = mock("STDERR")
      @status = 0

      @uname_x_lines = uname_x.split("\n")

      File.stub!(:exists?).with("/sbin/uname").and_return(true)
      @plugin.stub(:popen4).with("/sbin/uname -X").and_yield(@pid, @stdin, @uname_x_lines, @stderr).and_return(@status)
      
      @release = StringIO.new("  SmartOS 20120130T201844Z x86_64\n")
      File.stub!(:open).with("/etc/release").and_yield(@release)
    end

    it "should run uname and set platform and build" do 
      @plugin.run
      @plugin[:platform_build].should == "joyent_20120130T201844Z"
    end

    it "should set the platform" do
      @plugin.run
      @plugin[:platform].should == "smartos"
    end
    
    it "should set the platform_version" do
      @plugin.run
      @plugin[:platform_version].should == "5.11"
    end

  end

end
