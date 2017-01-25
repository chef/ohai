#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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

# We do not alter case for lsb attributes and consume them as provided

describe Ohai::System, "Linux lsb plugin" do
  before(:each) do
    @plugin = get_plugin("linux/lsb")
    allow(@plugin).to receive(:collect_os).and_return(:linux)
  end

  describe "on systems with /etc/lsb-release" do
    before(:each) do
      @double_file = double("/etc/lsb-release")
      allow(@double_file).to receive(:each).
        and_yield("DISTRIB_ID=Ubuntu").
        and_yield("DISTRIB_RELEASE=8.04").
        and_yield("DISTRIB_CODENAME=hardy").
        and_yield('DISTRIB_DESCRIPTION="Ubuntu 8.04"')
      allow(File).to receive(:open).with("/etc/lsb-release").and_return(@double_file)
      allow(File).to receive(:exists?).with("/usr/bin/lsb_release").and_return(false)
      allow(File).to receive(:exists?).with("/etc/lsb-release").and_return(true)
    end

    it "should set lsb[:id]" do
      @plugin.run
      expect(@plugin[:lsb][:id]).to eq("Ubuntu")
    end

    it "should set lsb[:release]" do
      @plugin.run
      expect(@plugin[:lsb][:release]).to eq("8.04")
    end

    it "should set lsb[:codename]" do
      @plugin.run
      expect(@plugin[:lsb][:codename]).to eq("hardy")
    end

    it "should set lsb[:description]" do
      @plugin.run
      expect(@plugin[:lsb][:description]).to eq("Ubuntu 8.04")
    end
  end

  describe "on systems with /usr/bin/lsb_release" do
    before(:each) do
      allow(File).to receive(:exists?).with("/usr/bin/lsb_release").and_return(true)

      @stdin = double("STDIN", { :close => true })
      @pid = 10
      @stderr = double("STDERR")
      @stdout = double("STDOUT")
      @status = 0

    end

    describe "on Centos 5.4 correctly" do
      before(:each) do
        @stdout = <<-LSB_RELEASE
LSB Version: :core-3.1-ia32:core-3.1-noarch:graphics-3.1-ia32:graphics-3.1-noarch
Distributor ID: CentOS
Description:  CentOS release 5.4 (Final)
Release:  5.4
Codename: Final
LSB_RELEASE
        allow(@plugin).to receive(:shell_out).with("lsb_release -a").and_return(mock_shell_out(0, @stdout, ""))
      end

      it "should set lsb[:id]" do
        @plugin.run
        expect(@plugin[:lsb][:id]).to eq("CentOS")
      end

      it "should set lsb[:release]" do
        @plugin.run
        expect(@plugin[:lsb][:release]).to eq("5.4")
      end

      it "should set lsb[:codename]" do
        @plugin.run
        expect(@plugin[:lsb][:codename]).to eq("Final")
      end

      it "should set lsb[:description]" do
        @plugin.run
        expect(@plugin[:lsb][:description]).to eq("CentOS release 5.4 (Final)")
      end
    end

    describe "on Fedora 14 correctly" do
      before(:each) do
        @stdout = <<-LSB_RELEASE
LSB Version:    :core-4.0-ia32:core-4.0-noarch
Distributor ID: Fedora
Description:    Fedora release 14 (Laughlin)
Release:        14
Codename:       Laughlin
LSB_RELEASE
        allow(@plugin).to receive(:shell_out).with("lsb_release -a").and_return(mock_shell_out(0, @stdout, ""))
      end

      it "should set lsb[:id]" do
        @plugin.run
        expect(@plugin[:lsb][:id]).to eq("Fedora")
      end

      it "should set lsb[:release]" do
        @plugin.run
        expect(@plugin[:lsb][:release]).to eq("14")
      end

      it "should set lsb[:codename]" do
        @plugin.run
        expect(@plugin[:lsb][:codename]).to eq("Laughlin")
      end

      it "should set lsb[:description]" do
        @plugin.run
        expect(@plugin[:lsb][:description]).to eq("Fedora release 14 (Laughlin)")
      end
    end
  end

  it "should not set any lsb values if /etc/lsb-release or /usr/bin/lsb_release do not exist " do
    allow(File).to receive(:exists?).with("/etc/lsb-release").and_return(false)
    allow(File).to receive(:exists?).with("/usr/bin/lsb_release").and_return(false)
    expect(@plugin.attribute?(:lsb)).to be(false)
  end
end
