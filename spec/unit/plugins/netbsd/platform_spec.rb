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

describe Ohai::System, "NetBSD plugin platform" do
  before(:each) do
    @plugin = get_plugin("netbsd/platform")
    allow(@plugin).to receive(:shell_out).with("uname -s").and_return(mock_shell_out(0, "NetBSD\n", ""))
    allow(@plugin).to receive(:shell_out).with("uname -r").and_return(mock_shell_out(0, "4.5\n", ""))
    allow(@plugin).to receive(:collect_os).and_return(:netbsd)
  end

  it "should set platform to lowercased lsb[:id]" do
    @plugin.run
    expect(@plugin[:platform]).to eq("netbsd")
  end

  it "should set platform_version to lsb[:release]" do
    @plugin.run
    expect(@plugin[:platform_version]).to eq("4.5")
  end
end
