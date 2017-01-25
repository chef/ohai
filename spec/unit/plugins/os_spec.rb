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

require_relative "../../spec_helper.rb"

ORIGINAL_CONFIG_HOST_OS = ::RbConfig::CONFIG["host_os"]

describe Ohai::System, "plugin os" do
  before(:each) do
    @plugin = get_plugin("os")
    @plugin[:kernel] = Mash.new
    @plugin[:kernel][:release] = "kings of leon"
  end

  after do
    ::RbConfig::CONFIG["host_os"] = ORIGINAL_CONFIG_HOST_OS
  end

  it "should set os_version to kernel_release" do
    @plugin.run
    expect(@plugin[:os_version]).to eq(@plugin[:kernel][:release])
  end

  describe "on linux" do
    before(:each) do
      ::RbConfig::CONFIG["host_os"] = "linux"
    end

    it "should set the os to linux" do
      @plugin.run
      expect(@plugin[:os]).to eq("linux")
    end
  end

  describe "on darwin" do
    before(:each) do
      ::RbConfig::CONFIG["host_os"] = "darwin10.0"
    end

    it "should set the os to darwin" do
      @plugin.run
      expect(@plugin[:os]).to eq("darwin")
    end
  end

  describe "on solaris" do
    before do
      ::RbConfig::CONFIG["host_os"] = "solaris2.42" #heh
    end

    it "sets the os to solaris2" do
      @plugin.run
      expect(@plugin[:os]).to eq("solaris2")
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
