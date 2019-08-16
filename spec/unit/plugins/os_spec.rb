#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Richard Manyanza (<liseki@nyikacraftsmen.com>)
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
# Copyright:: Copyright (c) 2014 Richard Manyanza.
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

require "spec_helper"

ORIGINAL_CONFIG_HOST_OS = ::RbConfig::CONFIG["host_os"]

describe Ohai::System, "plugin os" do
  before do
    @plugin = get_plugin("os")
    @plugin[:kernel] = Mash.new
    @plugin[:kernel][:release] = "kings of leon"
  end

  after do
    ::RbConfig::CONFIG["host_os"] = ORIGINAL_CONFIG_HOST_OS
  end

  it "sets os_version to kernel_release" do
    @plugin.run
    expect(@plugin[:os_version]).to eq(@plugin[:kernel][:release])
  end

  describe "on linux" do
    before do
      ::RbConfig::CONFIG["host_os"] = "linux"
    end

    it "sets the os to linux" do
      @plugin.run
      expect(@plugin[:os]).to eq("linux")
    end
  end

  describe "on darwin" do
    before do
      ::RbConfig::CONFIG["host_os"] = "darwin10.0"
    end

    it "sets the os to darwin" do
      @plugin.run
      expect(@plugin[:os]).to eq("darwin")
    end
  end

  describe "on solaris" do
    before do
      ::RbConfig::CONFIG["host_os"] = "solaris2.42" # heh
    end

    it "sets the os to solaris2" do
      @plugin.run
      expect(@plugin[:os]).to eq("solaris2")
    end
  end

  describe "on AIX" do
    before do
      @plugin = get_plugin("os")
      allow(@plugin).to receive(:collect_os).and_return(:aix)
      allow(@plugin).to receive(:shell_out).with("oslevel -s").and_return(mock_shell_out(0, "7200-00-01-1543\n", nil))
      @plugin.run
    end

    it "sets the top-level os attribute" do
      expect(@plugin[:os]).to be(:aix)
    end

    it "sets the top-level os_level attribute" do
      expect(@plugin[:os_version]).to eql("7200-00-01-1543")
    end
  end

  describe "on FreeBSD" do
    before do
      @plugin = get_plugin("os")
      allow(@plugin).to receive(:shell_out).with("sysctl -n kern.osreldate").and_return(mock_shell_out(0, "902001\n", ""))
      allow(@plugin).to receive(:collect_os).and_return(:freebsd)
    end

    it "sets os_version to __FreeBSD_version" do
      @plugin.run
      expect(@plugin[:os_version]).to eq("902001")
    end
  end

  describe "on something we have never seen before, but ruby has" do
    before do
      ::RbConfig::CONFIG["host_os"] = "tron"
    end

    it "sets the os to the ruby 'host_os'" do
      @plugin.run
      expect(@plugin[:os]).to eq("tron")
    end
  end
end
