#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Ohai::System, "plugin kernel" do
  let(:uname) do
    {
      sysname: "Darwin",
      nodename: "katie.local",
      release: "9.5.0",
      version: "Darwin Kernel Version 9.5.0: Wed Sep  3 11:29:43 PDT 2008; root:xnu-1228.7.58~1/RELEASE_I386",
      machine: "i386",
    }
  end

  before do
    @plugin = get_plugin("kernel")
    allow(@plugin).to receive(:collect_os).and_return(:default) # for debugging
    allow(Etc).to receive(:uname).and_return(uname)
    allow(@plugin).to receive(:shell_out).with("uname -p").and_return(mock_shell_out(0, "i386\n", ""))
  end

  it "reads name, release, version and machine from Etc.uname without running uname" do
    %w{-s -r -v -m}.each { |flag| expect(@plugin).not_to receive(:shell_out).with("uname #{flag}") }
    @plugin.run
    expect(@plugin[:kernel][:name]).to eq("Darwin")
    expect(@plugin[:kernel][:release]).to eq("9.5.0")
    expect(@plugin[:kernel][:version]).to eq(uname[:version])
    expect(@plugin[:kernel][:machine]).to eq("i386")
  end

  it_should_check_from_mash("kernel", "processor", "uname -p", [0, "i386\n", ""])

  context "in target mode" do
    before do
      allow(@plugin).to receive(:target_mode?).and_return(true)
      allow(@plugin).to receive(:shell_out).with("uname -s").and_return(mock_shell_out(0, "Linux\n", ""))
      allow(@plugin).to receive(:shell_out).with("uname -r").and_return(mock_shell_out(0, "6.8.0\n", ""))
      allow(@plugin).to receive(:shell_out).with("uname -v").and_return(mock_shell_out(0, "#1 SMP PREEMPT_DYNAMIC\n", ""))
      allow(@plugin).to receive(:shell_out).with("uname -m").and_return(mock_shell_out(0, "x86_64\n", ""))
      allow(@plugin).to receive(:shell_out).with("uname -p").and_return(mock_shell_out(0, "x86_64\n", ""))
    end

    it "asks the target's uname rather than the local Etc.uname" do
      expect(Etc).not_to receive(:uname)
      @plugin.run
      expect(@plugin[:kernel][:name]).to eq("Linux")
      expect(@plugin[:kernel][:release]).to eq("6.8.0")
      expect(@plugin[:kernel][:version]).to eq("#1 SMP PREEMPT_DYNAMIC")
      expect(@plugin[:kernel][:machine]).to eq("x86_64")
      expect(@plugin[:kernel][:processor]).to eq("x86_64")
    end
  end
end
