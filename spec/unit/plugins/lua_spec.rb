#
# Author:: Doug MacEachern <dougm@vmware.com>
# Author:: Theodore Nordsieck (<theo@opscode.com>)
# Copyright:: Copyright (c) 2009 VMware, Inc.
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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


require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '/spec_helper.rb'))

describe Ohai::System, "plugin lua" do

  before(:each) do
    @plugin = get_plugin("lua")
    @plugin[:languages] = Mash.new
    @stderr = "Lua 5.1.2  Copyright (C) 1994-2008 Lua.org, PUC-Rio\n"
    allow(@plugin).to receive(:shell_out).with("lua -v").and_return(mock_shell_out(0, "", @stderr))
  end

  it "should get the lua version from running lua -v" do
    expect(@plugin).to receive(:shell_out).with("lua -v").and_return(mock_shell_out(0, "", @stderr))
    @plugin.run
  end

  it "should set languages[:lua][:version]" do
    @plugin.run
    expect(@plugin.languages[:lua][:version]).to eql("5.1.2")
  end

  it "should not set the languages[:lua] tree up if lua command fails" do
    @stderr = "Lua 5.1.2  Copyright (C) 1994-2008 Lua.org, PUC-Rio\n"
    allow(@plugin).to receive(:shell_out).with("lua -v").and_return(mock_shell_out(1, "", @stderr))
    @plugin.run
    expect(@plugin.languages).not_to have_key(:lua)
  end

end
