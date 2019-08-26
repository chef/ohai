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

require "spec_helper"

describe Ohai::System, "Darwin plugin platform" do
  before do
    @plugin = get_plugin("darwin/platform")
    allow(@plugin).to receive(:collect_os).and_return(:darwin)
    @stdout = "ProductName:	Mac OS X\nProductVersion:	10.5.5\nBuildVersion:	9F33"
    allow(@plugin).to receive(:shell_out).with("/usr/bin/sw_vers").and_return(mock_shell_out(0, @stdout, ""))
  end

  it "runs sw_vers" do
    expect(@plugin).to receive(:shell_out).with("/usr/bin/sw_vers").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
  end

  it "sets platform to ProductName, downcased with _ for \\s" do
    @plugin.run
    expect(@plugin[:platform]).to eq("mac_os_x")
  end

  it "sets platform_version to ProductVersion" do
    @plugin.run
    expect(@plugin[:platform_version]).to eq("10.5.5")
  end

  it "sets platform_build to BuildVersion" do
    @plugin.run
    expect(@plugin[:platform_build]).to eq("9F33")
  end

  it "sets platform_family to mac_os_x" do
    @plugin.run
    expect(@plugin[:platform_family]).to eq("mac_os_x")
  end

  describe "on os x server" do
    before do
      @plugin[:os] = "darwin"
      @stdout = "ProductName:	Mac OS X Server\nProductVersion:	10.6.8\nBuildVersion:	10K549"
      allow(@plugin).to receive(:shell_out).with("/usr/bin/sw_vers").and_return(mock_shell_out(0, @stdout, ""))
    end

    it "sets platform to mac_os_x_server" do
      @plugin.run
      expect(@plugin[:platform]).to eq("mac_os_x_server")
    end

    it "sets platform_family to mac_os_x" do
      @plugin.run
      expect(@plugin[:platform_family]).to eq("mac_os_x")
    end
  end
end
