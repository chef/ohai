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
    @plugin = get_plugin("freebsd/virtualization")
    @plugin.stub(:collect_os).and_return(:freebsd)
    @plugin.stub(:shell_out).with("sysctl -n security.jail.jailed").and_return(mock_shell_out(0, "0", ""))
    @plugin.stub(:shell_out).with("#{ Ohai.abs_path( "/sbin/kldstat" )}").and_return(mock_shell_out(0, "", ""))
    @plugin.stub(:shell_out).with("jls -n").and_return(mock_shell_out(0, "",""))
    @plugin.stub(:shell_out).with("sysctl -n hw.model").and_return(mock_shell_out(0, "", ""))
  end

  context "jails" do
    it "detects we are in a jail" do
      @plugin.stub(:shell_out).with("sysctl -n security.jail.jailed").and_return(mock_shell_out(0, "1", ""))
      @plugin.run
      @plugin[:virtualization][:system].should == "jail"
      @plugin[:virtualization][:role].should == "guest"
    end

    it "detects we are hosting jails" do
      # from http://www.freebsd.org/doc/handbook/jails-application.html
    @jails = "JID  IP Address      Hostname                      Path\n     3  192.168.3.17    ns.example.org                /home/j/ns\n     2  192.168.3.18    mail.example.org              /home/j/mail\n     1  62.123.43.14    www.example.org               /home/j/www"
      @plugin.stub(:shell_out).with("jls -n").and_return(mock_shell_out(0, @jails, ""))
      @plugin.run
      @plugin[:virtualization][:system].should == "jail"
      @plugin[:virtualization][:role].should == "host"
    end
  end

  context "when on a virtualbox guest" do
    before do
      @vbox_guest = <<-OUT
Id Refs Address Size Name
1 40 0xffffffff80100000 d20428 kernel
7 3 0xffffffff81055000 41e88 vboxguest.ko
OUT
      @plugin.stub(:shell_out).with("#{ Ohai.abs_path("/sbin/kldstat")}").and_return(mock_shell_out(0, @vbox_guest, ""))
    end

    it "detects we are a guest" do
      @plugin.run
      @plugin[:virtualization][:system].should == "vbox"
      @plugin[:virtualization][:role].should == "guest"
    end
  end

  context "when on a virtualbox host" do
    before do
      @stdout = <<-OUT
Id Refs Address Size Name
1 40 0xffffffff80100000 d20428 kernel
7 3 0xffffffff81055000 41e88 vboxdrv.ko
OUT
      @plugin.stub(:shell_out).with("/sbin/kldstat").and_return(mock_shell_out(0, @stdout, ""))
    end

    it "detects we are a host" do
      @plugin.run
      @plugin[:virtualization][:system].should == "vbox"
      @plugin[:virtualization][:role].should == "host"
    end
  end

  context "when on a QEMU guest" do
    it "detects we are a guest" do
      [ 'Common KVM processor', 'QEMU Virtual CPU version (cpu64-rhel6) ("GenuineIntel" 686-class)', 'Common 32-bit KVM processor'].each do |kvm_string|
        @plugin.stub(:shell_out).with("sysctl -n hw.model").and_return(mock_shell_out(0, kvm_string, ""))
        @plugin.run
        @plugin[:virtualization][:system].should == "kvm"
        @plugin[:virtualization][:role].should == "guest"
      end
    end
  end

  # TODO upfactor tests from linux virtualization plugin for dmidecode
end
