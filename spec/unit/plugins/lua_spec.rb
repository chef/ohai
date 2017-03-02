#
# Author:: Doug MacEachern <dougm@vmware.com>
# Author:: Theodore Nordsieck (<theo@chef.io>)
# Copyright:: Copyright (c) 2009 VMware, Inc.
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

require_relative "../../spec_helper.rb"

describe Ohai::System, "plugin lua" do

  let(:plugin) { get_plugin("lua") }

  before(:each) do
    plugin[:languages] = Mash.new
    @message = "Lua 5.1.2  Copyright (C) 1994-2008 Lua.org, PUC-Rio\n"
    allow(plugin).to receive(:shell_out).with("lua -v").and_return(mock_shell_out(0, "", @message))
  end

  it "gets the lua version from running lua -v" do
    expect(plugin).to receive(:shell_out).with("lua -v")
    plugin.run
  end

  it "sets languages[:lua][:version]" do
    plugin.run
    expect(plugin.languages[:lua][:version]).to eql("5.1.2")
  end

  it "does not set languages[:lua] if lua command fails" do
    allow(plugin).to receive(:shell_out).with("lua -v").and_return(mock_shell_out(1, "", ""))
    plugin.run
    expect(plugin.languages).not_to have_key(:lua)
  end

  it "does not set languages[:lua] if lua command doesn't exist" do
    allow(plugin).to receive(:shell_out).and_raise(Ohai::Exceptions::Exec)
    plugin.run
    expect(plugin.languages).not_to have_key(:lua)
  end

  it "sets languages[:lua][:version] when 'lua -v' returns output on stdout not stderr" do
    allow(plugin).to receive(:shell_out).with("lua -v").and_return(mock_shell_out(0, @message, ""))
    plugin.run
    expect(plugin.languages[:lua][:version]).to eql("5.1.2")
  end
end
