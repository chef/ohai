#
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Ohai::System, "AIX memory plugin" do
  before do
    @plugin = get_plugin("aix/memory")
    allow(@plugin).to receive(:collect_os).and_return(:aix)
    allow(@plugin).to receive(:shell_out).with("svmon -G -O unit=KB,summary=longreal | grep '[0-9]'").and_return(mock_shell_out(0, " 25165824   7255120  17910704    4507712   4913152  19409452   1572864\n", nil))
    @swap_s = "allocated  =    23887872 blocks    used  =   288912 blocks      free  =    23598960 blocks\n"
    allow(@plugin).to receive(:shell_out).with("swap -s").and_return(mock_shell_out(0, @swap_s, nil))
  end

  it "gets total memory" do
    @plugin.run
    expect(@plugin["memory"]["total"]).to eql("25165824kB")
  end

  it "gets free memory" do
    @plugin.run
    expect(@plugin["memory"]["free"]).to eql("17910704kB")
  end

  it "gets total swap" do
    @plugin.run
    expect(@plugin["memory"]["swap"]["total"]).to eql( "95551488kB")
  end

  it "gets free swap" do
    @plugin.run
    expect(@plugin["memory"]["swap"]["free"]).to eql( "94395840kB")
  end
end
