#
# Author:: Thom May (<thom@clearairturbulence.org>)
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

require File.join(File.dirname(__FILE__), '..', '..', '..', '/spec_helper.rb')

describe Ohai::System, "Linux virtualization platform" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai[:os] = "linux"
    @ohai.stub!(:require_plugin).and_return(true)
    File.should_receive(:exists?).with(/linux\/virtualization.rb/).and_return(true)
    File.should_receive(:exists?).with("/usr/sbin/dmidecode").and_return(true)
    @stdin = mock("STDIN", { :close => true })
    @pid = 10
    @stderr = mock("STDERR")
    @stdout = mock("STDOUT")
  end

  it "should set xen host if /proc/xen/capabilities contains control_d" do
    ["/proc/modules", "/proc/cpuinfo"].each do |d|
      File.should_receive(:exists?).with(d).and_return(false)
    end
    File.should_receive(:exists?).with("/proc/xen/capabilities").and_return(true)
    File.stub!(:read).with("/proc/xen/capabilities").and_return("control_d")
    @ohai._require_plugin("linux::virtualization")
    @ohai[:virtualization][:system].should == "xen" 
    @ohai[:virtualization][:role].should == "host"
  end

  it "should set xen guest if /proc/sys/xen/independent_wallclock exists" do
    ["/proc/xen/capabilities", "/proc/modules", "/proc/cpuinfo"].each do |d|
      File.should_receive(:exists?).with(d).and_return(false)
    end
    File.should_receive(:exists?).with("/proc/sys/xen/independent_wallclock").and_return(true)
    @ohai._require_plugin("linux::virtualization")
    @ohai[:virtualization][:system].should == "xen"
    @ohai[:virtualization][:role].should == "guest"
  end

  it "should set kvm host if /proc/modules contains kvm" do
    ["/proc/xen/capabilities", "/proc/sys/xen/independent_wallclock", "/proc/cpuinfo"].each do |d|
      File.should_receive(:exists?).with(d).and_return(false)
    end
    File.should_receive(:exists?).with("/proc/modules").and_return(true)
    File.stub!(:read).with("/proc/modules").and_return("kvm")
    @ohai._require_plugin("linux::virtualization")
    @ohai[:virtualization][:system].should == "kvm"
    @ohai[:virtualization][:role].should == "host"
  end
  
  it "should set kvm guest if /proc/cpuinfo contains QEMU Virtual CPU" do
    ["/proc/xen/capabilities", "/proc/sys/xen/independent_wallclock", "/proc/modules"].each do |d|
      File.should_receive(:exists?).with(d).and_return(false)
    end
    File.should_receive(:exists?).with("/proc/cpuinfo").and_return(true)
    File.stub!(:read).with("/proc/cpuinfo").and_return("QEMU Virtual CPU")
    @ohai._require_plugin("linux::virtualization")
    @ohai[:virtualization][:system].should == "kvm"
    @ohai[:virtualization][:role].should == "guest"
  end
  
  it "should not set virtualization if xen isn't there" do
    File.should_receive(:exists?).at_least(:once).and_return(false)
    @ohai._require_plugin("linux::virtualization")
    @ohai[:virtualization].should == {}
  end
end


