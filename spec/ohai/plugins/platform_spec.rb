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


require File.join(File.dirname(__FILE__), '..', '..', '/spec_helper.rb')

describe Ohai::System, "plugin platform" do
  before(:each) do
    @ohai = Ohai::System.new    
    @ohai.stub!(:require_plugin).and_return(true)
  end
  
  it "should require the os plugin" do
    @ohai.should_receive(:require_plugin).with("os").and_return(true)  
    @ohai._require_plugin("platform")
  end
  
  it "should require the lsb plugin" do
    @ohai.should_receive(:require_plugin).with("lsb").and_return(true)  
    @ohai._require_plugin("platform")
  end
  
  describe "on linux" do
    before(:each) do
      @ohai[:os] = "linux"
      #File.stub!(:exists?).with("/etc/debian_version").and_return(false)
      #File.stub!(:exists?).with("/etc/redhat-release").and_return(false)
    end
    
    describe "on lsb compliant distributions" do
      before(:each) do
        @ohai[:lsb_dist_id] = "Ubuntu"
        @ohai[:lsb_dist_version] = "8.04"
      end
      
      it "should set platform to lowercased lsb_dist_id" do
        @ohai._require_plugin("platform")        
        @ohai[:platform].should == "ubuntu"
      end
      
      it "should set platform_version to lsb_dist_version" do
        @ohai._require_plugin("platform")
        @ohai[:platform_version].should == "8.04"
      end
    end
    
    # describe "on debian" do
    #   before(:each) do
    #     File.stub!(:exists?).and_return(true)
    #   end
    #   
    #   it "should set the platform to debian" do
    #     @ohai._require_plugin("platform")
    #     @ohai[:platform].should == "debian"
    #   end
    #   
    #   it_should_check_from("platform", "platform_version", "cat /etc/debian_version", "lenny/sid")
    # end
  end
  
  describe "on darwin" do
    before(:each) do
      @ohai[:os] = "darwin"
      @pid = 10
      @stdin = mock("STDIN", { :close => true })
      @stdout = mock("STDOUT")
      @stdout.stub!(:each).
        and_yield("ProductName:	Mac OS X").
        and_yield("ProductVersion:	10.5.5").
        and_yield("BuildVersion:	9F33")
      @stderr = mock("STDERR") 
      @ohai.stub!(:popen4).with("sw_vers").and_yield(@pid, @stdin, @stdout, @stderr)
    end
    
    it "should run sw_vers" do
      @ohai.should_receive(:popen4).with("sw_vers").and_return(true)
      @ohai._require_plugin("platform")
    end
    
    it "should close sw_vers stdin" do
      @stdin.should_receive(:close)
      @ohai._require_plugin("platform")
    end
    
    it "should iterate over each line of sw_vers stdout" do
      @stdout.should_receive(:each).and_return(true)
      @ohai._require_plugin("platform")
    end
    
    it "should set platform to ProductName, downcased with _ for \\s" do
      @ohai._require_plugin("platform")
      @ohai[:platform].should == "mac_os_x"
    end
    
    it "should set platform_version to ProductVersion" do
      @ohai._require_plugin("platform")
      @ohai[:platform_version].should == "10.5.5"
    end
    
    it "should set platform_build to BuildVersion" do
      @ohai._require_plugin("platform")
      @ohai[:platform_build].should == "9F33"
    end
  end
end