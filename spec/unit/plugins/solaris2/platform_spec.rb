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
    @plugin = get_plugin("solaris2/platform")
    @plugin.stub(:collect_os).and_return(:solaris2)
    @plugin.stub(:shell_out).with("/sbin/uname -X")
  end
  
  describe "on SmartOS" do
    before(:each) do
      @uname_x = <<-UNAME_X
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

      File.stub(:exists?).with("/sbin/uname").and_return(true)
      @plugin.stub(:shell_out).with("/sbin/uname -X").and_return(mock_shell_out(0, @uname_x, ""))
      
      @release = StringIO.new("  SmartOS 20120130T201844Z x86_64\n")
      File.stub(:open).with("/etc/release").and_yield(@release)
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

  describe "on Solaris 11" do
    before(:each) do
      @uname_x = <<-UNAME_X
System = SunOS
Node = node.example.com
Release = 5.11
KernelID = 11.1
Machine = i86pc
BusType = <unknown>
Serial = <unknown>
Users = <unknown>
OEM# = 0
Origin# = 1
NumCPU = 1
UNAME_X

      File.stub(:exists?).with("/sbin/uname").and_return(true)
      @plugin.stub(:shell_out).with("/sbin/uname -X").and_return(mock_shell_out(0, @uname_x, ""))

      @release = StringIO.new("                             Oracle Solaris 11.1 X86\n")
      File.stub(:open).with("/etc/release").and_yield(@release)
    end

    it "should run uname and set platform and build" do
      @plugin.run
      @plugin[:platform_build].should == "11.1"
    end

    it "should set the platform" do
      @plugin.run
      @plugin[:platform].should == "solaris2"
    end

    it "should set the platform_version" do
      @plugin.run
      @plugin[:platform_version].should == "5.11"
    end

  end

end
