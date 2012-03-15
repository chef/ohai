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
    @ohai.extend(SimpleFromFile)
    @ohai.stub!(:require_plugin).and_return(true)
    @ohai[:os] = "solaris2"
    @ohai.stub!(:popen4).with("/sbin/uname -X")
  end
  
  describe "on SmartOS" do
    before(:each) do
      @stdin = mock("STDIN", { :close => true })
      @pid = 10
      @stderr = mock("STDERR")
      @stdout = mock("STDOUT")
      @status = 0
      @stdout.stub!(:each).
        and_yield("System = SunOS").
        and_yield("Node = node.example.com").
        and_yield("Release = 5.11").
        and_yield("KernelID = joyent_20120130T201844Z").
        and_yield("Machine = i86pc").
        and_yield("BusType = <unknown>").
        and_yield("Serial = <unknown>").
        and_yield("Users = <unknown>").
        and_yield("OEM# = 0").
        and_yield("Origin# = 1").
        and_yield("NumCPU = 16")
      File.stub!(:exists?).with("/sbin/uname").and_return(true)
      @ohai.stub(:popen4).with("/sbin/uname -X").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      
      @release = StringIO.new("  SmartOS 20120130T201844Z x86_64\n")
      @mock_file.stub!(:close).and_return(0)
      File.stub!(:open).with("/etc/release").and_yield(@release)
    end

    it "should run uname and set platform and build" do 
      @ohai._require_plugin("solaris2::platform")
      @ohai[:platform_build].should == "joyent_20120130T201844Z"
    end

    it "should set the platform" do
      @ohai._require_plugin("solaris2::platform")
      @ohai[:platform].should == "smartos"
    end
    
    it "should set the platform_version" do
      @ohai._require_plugin("solaris2::platform")
      @ohai[:platform_version].should == "20120130T201844Z"
    end

  end

end
