#
# Author:: Bryan McLellan <btm@opscode.com>
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

describe Ohai::System, "FreeBSD virtualization plugin" do
  before(:each) do
    @ohai = Ohai::System.new
    @plugin = Ohai::DSL::Plugin.new(@ohai, File.join(PLUGIN_PATH, "freebsd/virtualization.rb"))
    @plugin.stub(:require_plugin)
    @plugin[:os] = "freebsd"
    @stderr = StringIO.new
    @stdin = StringIO.new
    @status = 0
    @pid = 42
    @plugin.stub(:popen4).with("/sbin/kldstat")
    @plugin.stub(:from)
  end

  context "jails" do
    it "detects we are in a jail" do
      @plugin.stub(:from).with("sysctl -n security.jail.jailed").and_return("1")
      @plugin.run
      @plugin[:virtualization][:system].should == "jail"
      @plugin[:virtualization][:role].should == "guest"
    end

    it "detects we are hosing jails" do
      @plugin.stub(:from).with("jls -n \| wc -l").and_return("1")
      @plugin.run
      @plugin[:virtualization][:system].should == "jail"
      @plugin[:virtualization][:role].should == "host"
    end
  end


  context "when on a virtualbox guest" do
    before do
      @stdout = StringIO.new(<<-OUT)
Id Refs Address Size Name
1 40 0xffffffff80100000 d20428 kernel
7 3 0xffffffff81055000 41e88 vboxguest.ko
OUT
      @plugin.stub(:popen4).with("/sbin/kldstat").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    end

    it "detects we are a guest" do
      @plugin.run
      @plugin[:virtualization][:system].should == "vbox"
      @plugin[:virtualization][:role].should == "guest"
    end
  end

  context "when on a virtualbox host" do
    before do
      @stdout = StringIO.new(<<-OUT)
Id Refs Address Size Name
1 40 0xffffffff80100000 d20428 kernel
7 3 0xffffffff81055000 41e88 vboxdrv.ko
OUT
      @plugin.stub(:popen4).with("/sbin/kldstat").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    end

    it "detects we are a host" do
      @plugin.run
      @plugin[:virtualization][:system].should == "vbox"
      @plugin[:virtualization][:role].should == "host"
    end
  end

  context "when on a QEMU guest" do
    it "detects we are a guest" do
      @plugin.stub(:from).with("sysctl -n hw.model").and_return('QEMU Virtual CPU version (cpu64-rhel6) ("GenuineIntel" 686-class)')
      @plugin.run
      @plugin[:virtualization][:system].should == "kvm"
      @plugin[:virtualization][:role].should == "guest"
    end
  end

  # TODO upfactor tests from linux virtualization plugin for dmidecode
end



