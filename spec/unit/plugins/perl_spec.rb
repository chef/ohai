#
# Author:: Joshua Timberman(<joshua@opscode.com>)
# Author:: Theodore Nordsieck (<theo@opscode.com>)
# Copyright:: Copyright (c) 2009-2013 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, "plugin perl" do
  before(:each) do
    @plugin = get_plugin("perl")
    @plugin[:languages] = Mash.new
    @stdout = "version='5.8.8';#{$/}archname='darwin-thread-multi-2level';"
    allow(@plugin).to receive(:shell_out).with("perl -V:version -V:archname").and_return(mock_shell_out(0, @stdout, ""))
  end

  it "should run perl -V:version -V:archname" do
    expect(@plugin).to receive(:shell_out).with("perl -V:version -V:archname").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
  end

  it "should set languages[:perl][:version]" do
    @plugin.run
    expect(@plugin.languages[:perl][:version]).to eql("5.8.8")
  end

  it "should set languages[:perl][:archname]" do
    @plugin.run
    expect(@plugin.languages[:perl][:archname]).to eql("darwin-thread-multi-2level")
  end

  it "should set languages[:perl] if perl command succeeds" do
    allow(@plugin).to receive(:shell_out).with("perl -V:version -V:archname").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
    expect(@plugin.languages).to have_key(:perl)
  end

  it "should not set languages[:perl] if perl command fails" do
    @status = 1
    allow(@plugin).to receive(:shell_out).with("perl -V:version -V:archname").and_return(mock_shell_out(1, @stdout, ""))
    @plugin.run
    expect(@plugin.languages).not_to have_key(:perl)
  end

end
