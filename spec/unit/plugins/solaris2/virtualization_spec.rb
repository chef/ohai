#
# Author:: Sean Walbran (<seanwalbran@gmail.com>)
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

describe Ohai::System, "Solaris virtualization platform" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai[:os] = "solaris2"
    @ohai.stub!(:require_plugin).and_return(true)
    @ohai.extend(SimpleFromFile)

    # default to all requested Files not existing
    File.stub!(:exists?).with("/usr/sbin/psrinfo").and_return(false)
    File.stub!(:exists?).with("/usr/sbin/smbios").and_return(false)
    File.stub!(:exists?).with("/usr/sbin/zoneadm").and_return(false)
  end

  describe "when we are checking for kvm" do
    before(:each) do
      File.should_receive(:exists?).with("/usr/sbin/psrinfo").and_return(true)
      @stdin = mock("STDIN", { :close => true })
      @pid = 10
      @stderr = mock("STDERR")
      @stdout = mock("STDOUT")
      @status = 0
    end

    it "should run psrinfo -pv" do
      @ohai.should_receive(:popen4).with("/usr/sbin/psrinfo -pv").and_return(true)
      @ohai._require_plugin("solaris2::virtualization")
    end

    it "Should set kvm guest if psrinfo -pv contains QEMU Virtual CPU" do
      @stdout.stub!(:read).and_return("QEMU Virtual CPU") 
      @ohai.stub!(:popen4).with("/usr/sbin/psrinfo -pv").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @ohai._require_plugin("solaris2::virtualization")
      @ohai[:virtualization][:system].should == "kvm"
      @ohai[:virtualization][:role].should == "guest"
    end

    it "should not set virtualization if kvm isn't there" do
      @ohai.should_receive(:popen4).with("/usr/sbin/psrinfo -pv").and_return(true)
      @ohai._require_plugin("solaris2::virtualization")
      @ohai[:virtualization].should == {}
    end
  end

  describe "when we are parsing smbios" do
    before(:each) do
      File.should_receive(:exists?).with("/usr/sbin/smbios").and_return(true)
      @stdin = mock("STDIN", { :close => true })
      @pid = 20
      @stderr = mock("STDERR")
      @stdout = mock("STDOUT")
      @status = 0
    end

    it "should run smbios" do
      @ohai.should_receive(:popen4).with("/usr/sbin/smbios").and_return(true)
      @ohai._require_plugin("solaris2::virtualization")
    end

    it "should set virtualpc guest if smbios detects Microsoft Virtual Machine" do
      ms_vpc_smbios=<<-MSVPC
ID    SIZE TYPE
1     72   SMB_TYPE_SYSTEM (system information)

  Manufacturer: Microsoft Corporation
  Product: Virtual Machine
  Version: VS2005R2
  Serial Number: 1688-7189-5337-7903-2297-1012-52

  UUID: D29974A4-BE51-044C-BDC6-EFBC4B87A8E9
  Wake-Up Event: 0x6 (power switch)
MSVPC
      @stdout.stub!(:read).and_return(ms_vpc_smbios) 
       
      @ohai.stub!(:popen4).with("/usr/sbin/smbios").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @ohai._require_plugin("solaris2::virtualization")
      @ohai[:virtualization][:system].should == "virtualpc"
      @ohai[:virtualization][:role].should == "guest"
    end

    it "should set vmware guest if smbios detects VMware Virtual Platform" do
      vmware_smbios=<<-VMWARE
ID    SIZE TYPE
1     72   SMB_TYPE_SYSTEM (system information)

  Manufacturer: VMware, Inc.
  Product: VMware Virtual Platform
  Version: None
  Serial Number: VMware-50 3f f7 14 42 d1 f1 da-3b 46 27 d0 29 b4 74 1d

  UUID: a86cc405-e1b9-447b-ad05-6f8db39d876a
  Wake-Up Event: 0x6 (power switch)
VMWARE
      @stdout.stub!(:read).and_return(vmware_smbios)
      @ohai.stub!(:popen4).with("/usr/sbin/smbios").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @ohai._require_plugin("solaris2::virtualization")
      @ohai[:virtualization][:system].should == "vmware"
      @ohai[:virtualization][:role].should == "guest"
    end

    it "should run smbios and not set virtualization if nothing is detected" do
      @ohai.should_receive(:popen4).with("/usr/sbin/smbios").and_return(true)
      @ohai._require_plugin("solaris2::virtualization")
      @ohai[:virtualization].should == {}
    end
  end

  it "should not set virtualization if no tests match" do
    @ohai._require_plugin("solaris2::virtualization")
    @ohai[:virtualization].should == {}
  end
end


