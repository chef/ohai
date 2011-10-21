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
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "Linux plugin platform" do
  before(:each) do
    @ohai = Ohai::System.new    
    @ohai.stub!(:require_plugin).and_return(true)
    @ohai.extend(SimpleFromFile)
    @ohai[:os] = "linux"
    @ohai[:lsb] = Mash.new
    File.stub!(:exists?).with("/etc/debian_version").and_return(false)
    File.stub!(:exists?).with("/etc/redhat-release").and_return(false)
    File.stub!(:exists?).with("/etc/gentoo-release").and_return(false)
    File.stub!(:exists?).with("/etc/SuSE-release").and_return(false)
    File.stub!(:exists?).with("/etc/arch-release").and_return(false)
    File.stub!(:exists?).with("/etc/system-release").and_return(false)
    File.stub!(:exists?).with("/etc/slackware-version").and_return(false)
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

    it "should set platform to redhat when [:lsb][:id] contains Redhat" do
      @ohai[:lsb][:id] = "RedHatEnterpriseServer"
      @ohai[:lsb][:release] = "5.7"
      @ohai._require_plugin("linux::platform")
      @ohai[:platform].should == "redhat"
    end

    it "should set platform to amazon when [:lsb][:id] contains Amazon" do
      @ohai[:lsb][:id] = "AmazonAMI"
      @ohai[:lsb][:release] = "2011.09"
      @ohai._require_plugin("linux::platform")
      @ohai[:platform].should == "amazon"
    end
  end

  describe "on debian" do
    before(:each) do
      @ohai.lsb = nil
      File.should_receive(:exists?).with("/etc/debian_version").and_return(true)
    end
    
    it "should check for the existance of debian_version" do 
      @ohai._require_plugin("linux::platform")
    end

    it "should read the version from /etc/debian_version" do
      File.should_receive(:read).with("/etc/debian_version").and_return("5.0")
      @ohai._require_plugin("linux::platform")
      @ohai[:platform_version].should == "5.0"
    end

    it "should correctly strip any newlines" do
      File.should_receive(:read).with("/etc/debian_version").and_return("5.0\n")
      @ohai._require_plugin("linux::platform")
      @ohai[:platform_version].should == "5.0"
    end

  end

  describe "on slackware" do
    before(:each) do
      @ohai.lsb = nil
      File.should_receive(:exists?).with("/etc/slackware-version").and_return(true)
    end

    it "should set platform to slackware" do
      @ohai._require_plugin("linux::platform")
      @ohai[:platform].should == "slackware"
    end
  end
  
  describe "on arch" do
    before(:each) do
      @ohai.lsb = nil
      File.should_receive(:exists?).with("/etc/arch-release").and_return(true)
    end

    it "should set platform to arch" do
      @ohai._require_plugin("linux::platform")
      @ohai[:platform].should == "arch"
    end
  end
  
  describe "on gentoo" do
    before(:each) do
      @ohai.lsb = nil
      File.should_receive(:exists?).with("/etc/gentoo-release").and_return(true)
    end

    it "should set platform to gentoo" do
      @ohai._require_plugin("linux::platform")
      @ohai[:platform].should == "gentoo"
    end
  end

  describe "on redhat breeds" do
    describe "with lsb_release results" do
      it "should set the platform to redhat even if the LSB name is something absurd but redhat like" do
        @ohai[:lsb][:id] = "RedHatEnterpriseServer"
        @ohai[:lsb][:release] = "6.1"
        @ohai._require_plugin("linux::platform")
        @ohai[:platform].should == "redhat"
        @ohai[:platform_version].should == "6.1"
      end

      it "should set the platform to centos" do
        @ohai[:lsb][:id] = "CentOS"
        @ohai[:lsb][:release] = "5.4"
        @ohai._require_plugin("linux::platform")
        @ohai[:platform].should == "centos"
        @ohai[:platform_version].should == "5.4"
      end
    end
  
    describe "without lsb_release results" do
      before(:each) do
        @ohai.lsb = nil
        File.should_receive(:exists?).with("/etc/redhat-release").and_return(true)
      end
  
      it "should check for the existance of redhat-release" do
        @ohai._require_plugin("linux::platform")
      end
            
      it "should read the platform as centos and version as 5.3" do
        File.should_receive(:read).with("/etc/redhat-release").and_return("CentOS release 5.3")
        @ohai._require_plugin("linux::platform")
        @ohai[:platform].should == "centos"
      end
  
      it "may be that someone munged Red Hat to be RedHat" do
        File.should_receive(:read).with("/etc/redhat-release").and_return("RedHat release 5.3")
        @ohai._require_plugin("linux::platform")
        @ohai[:platform].should == "redhat"
        @ohai[:platform_version].should == "5.3"
      end
  
      it "should read the platform as redhat and version as 5.3" do
        File.should_receive(:read).with("/etc/redhat-release").and_return("Red Hat release 5.3")
        @ohai._require_plugin("linux::platform")
        @ohai[:platform].should == "redhat"
        @ohai[:platform_version].should == "5.3"
      end
  
      it "should read the platform as fedora and version as 13 (rawhide)" do
        File.should_receive(:read).with("/etc/redhat-release").and_return("Fedora release 13 (Rawhide)")
        @ohai._require_plugin("linux::platform")
        @ohai[:platform].should == "fedora"
        @ohai[:platform_version].should == "13 (rawhide)"
      end
      
      it "should read the platform as fedora and version as 10" do
        File.should_receive(:read).with("/etc/redhat-release").and_return("Fedora release 10")
        @ohai._require_plugin("linux::platform")
        @ohai[:platform].should == "fedora"
        @ohai[:platform_version].should == "10"
      end
  
      it "should read the platform as fedora and version as 13 using to_i" do
        File.should_receive(:read).with("/etc/redhat-release").and_return("Fedora release 13 (Rawhide)")
        @ohai._require_plugin("linux::platform")
        @ohai[:platform].should == "fedora"
        @ohai[:platform_version].to_i.should == 13
      end
    end
  end

  describe "on suse" do
    before(:each) do
      @ohai.lsb = nil
      File.should_receive(:exists?).with("/etc/SuSE-release").and_return(true)
    end
  
    it "should check for the existance of SuSE-release" do
      @ohai._require_plugin("linux::platform")
    end
  
    it "should set platform to suse" do
      @ohai._require_plugin("linux::platform")
      @ohai[:platform].should == "suse"
    end
  
    it "should read the version as 10.1 for bogus SLES 10" do
      File.should_receive(:read).with("/etc/SuSE-release").and_return("SUSE Linux Enterprise Server 10 (i586)\nVERSION = 10\nPATCHLEVEL = 1\n")
      @ohai._require_plugin("linux::platform")
      @ohai[:platform].should == "suse"
      @ohai[:platform_version].should == "10.1"
    end
  
    it "should read the version as 11.2" do
      File.should_receive(:read).with("/etc/SuSE-release").and_return("SUSE Linux Enterprise Server 11.2 (i586)\nVERSION = 11\nPATCHLEVEL = 2\n")
      @ohai._require_plugin("linux::platform")
      @ohai[:platform].should == "suse"
      @ohai[:platform_version].should == "11.2"
    end
    
    it "[OHAI-272] should read the version as 11.3" do
      File.should_receive(:read).with("/etc/SuSE-release").exactly(2).times.and_return("openSUSE 11.3 (x86_64)\nVERSION = 11.3")
      @ohai._require_plugin("linux::platform")
      @ohai[:platform].should == "suse"
      @ohai[:platform_version].should == "11.3"
    end
    
    it "[OHAI-272] should read the version as 9.1" do
      File.should_receive(:read).with("/etc/SuSE-release").exactly(2).times.and_return("SuSE Linux 9.1 (i586)\nVERSION = 9.1")
      @ohai._require_plugin("linux::platform")
      @ohai[:platform].should == "suse"
      @ohai[:platform_version].should == "9.1"
    end
    
    it "[OHAI-272] should read the version as 11.4" do
      File.should_receive(:read).with("/etc/SuSE-release").exactly(2).times.and_return("openSUSE 11.4 (i586)\nVERSION = 11.4\nCODENAME = Celadon")
      @ohai._require_plugin("linux::platform")
      @ohai[:platform].should == "suse"
      @ohai[:platform_version].should == "11.4"
    end
  end

end

