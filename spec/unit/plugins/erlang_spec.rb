#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Theodore Nordsieck (<theo@opscode.com>)
# Copyright:: Copyright (c) 2008-2013 Opscode, Inc.
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

describe Ohai::System, "plugin erlang" do

  before(:each) do
    @plugin = get_plugin("erlang")
    @plugin[:languages] = Mash.new
    @stderr = "Erlang (ASYNC_THREADS,SMP,HIPE) (BEAM) emulator version 5.6.2\n"
    allow(@plugin).to receive(:shell_out).with("erl +V").and_return(mock_shell_out(0, "", @stderr))
  end

  it "should get the erlang version from erl +V" do
    expect(@plugin).to receive(:shell_out).with("erl +V").and_return(mock_shell_out(0, "", @stderr))
    @plugin.run
  end

  it "should set languages[:erlang][:version]" do
    @plugin.run
    expect(@plugin.languages[:erlang][:version]).to eql("5.6.2")
  end

  it "should set languages[:erlang][:options]" do
    @plugin.run
    expect(@plugin.languages[:erlang][:options]).to eql(["ASYNC_THREADS", "SMP", "HIPE"])
  end

  it "should set languages[:erlang][:emulator]" do
    @plugin.run
    expect(@plugin.languages[:erlang][:emulator]).to eql("BEAM")
  end

  it "should not set the languages[:erlang] tree up if erlang command fails" do
    @status = 1
    @stdin = ""
    @stderr = "Erlang (ASYNC_THREADS,SMP,HIPE) (BEAM) emulator version 5.6.2\n"
    allow(@plugin).to receive(:shell_out).with("erl +V").and_return(mock_shell_out(1, "", @stderr))
    @plugin.run
    expect(@plugin.languages).not_to have_key(:erlang)
  end

end
