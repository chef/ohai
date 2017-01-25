#
# Author:: Trevor O (<trevoro@joyent.com>)
# Copyright:: Copyright (c) 2009-2016 Chef Software, Inc.
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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "Solaris plugin platform" do
  before(:each) do
    @plugin = get_plugin("solaris2/platform")
    allow(@plugin).to receive(:collect_os).and_return(:solaris2)
    allow(@plugin).to receive(:shell_out).with("/sbin/uname -X")
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

      allow(File).to receive(:exists?).with("/sbin/uname").and_return(true)
      allow(@plugin).to receive(:shell_out).with("/sbin/uname -X").and_return(mock_shell_out(0, @uname_x, ""))

      @release = StringIO.new("  SmartOS 20120130T201844Z x86_64\n")
      allow(File).to receive(:open).with("/etc/release").and_yield(@release)
    end

    it "should run uname and set platform and build" do
      @plugin.run
      expect(@plugin[:platform_build]).to eq("joyent_20120130T201844Z")
    end

    it "should set the platform" do
      @plugin.run
      expect(@plugin[:platform]).to eq("smartos")
    end

    it "should set the platform_version" do
      @plugin.run
      expect(@plugin[:platform_version]).to eq("5.11")
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

      allow(File).to receive(:exists?).with("/sbin/uname").and_return(true)
      allow(@plugin).to receive(:shell_out).with("/sbin/uname -X").and_return(mock_shell_out(0, @uname_x, ""))

      @release = StringIO.new("                             Oracle Solaris 11.1 X86\n")
      allow(File).to receive(:open).with("/etc/release").and_yield(@release)
    end

    it "should run uname and set platform and build" do
      @plugin.run
      expect(@plugin[:platform_build]).to eq("11.1")
    end

    it "should set the platform" do
      @plugin.run
      expect(@plugin[:platform]).to eq("solaris2")
    end

    it "should set the platform_version" do
      @plugin.run
      expect(@plugin[:platform_version]).to eq("5.11")
    end

  end

end
