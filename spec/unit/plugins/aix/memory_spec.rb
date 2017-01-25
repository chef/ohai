#
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

describe Ohai::System, "AIX memory plugin" do
  before(:each) do
    @plugin = get_plugin("aix/memory")
    allow(@plugin).to receive(:collect_os).and_return(:aix)
    allow(@plugin).to receive(:shell_out).with("svmon -G -O unit=MB,summary=longreal | grep '[0-9]'").and_return(mock_shell_out(0, " 513280.00 340034.17 173245.83   62535.17 230400.05 276950.14  70176.00\n", nil))
    @swap_s = "allocated  =    23887872 blocks    used  =   288912 blocks      free  =    23598960 blocks\n"
    allow(@plugin).to receive(:shell_out).with("swap -s").and_return(mock_shell_out(0, @swap_s, nil))
  end

  it "should get total memory" do
    @plugin.run
    expect(@plugin["memory"]["total"]).to eql("#{513280 * 1024}kB")
  end

  it "should get free memory" do
    @plugin.run
    expect(@plugin["memory"]["free"]).to eql("#{173245.83.to_i * 1024}kB")
  end

  it "should get total swap" do
    @plugin.run
    expect(@plugin["memory"]["swap"]["total"]).to eql( "#{23887872 * 4}kB")
  end

  it "should get free swap" do
    @plugin.run
    expect(@plugin["memory"]["swap"]["free"]).to eql( "#{23598960 * 4}kB")
  end
end
