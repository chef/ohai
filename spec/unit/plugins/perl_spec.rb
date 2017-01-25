#
# Author:: Joshua Timberman(<joshua@chef.io>)
# Author:: Theodore Nordsieck (<theo@chef.io>)
# Copyright:: Copyright (c) 2009-2016 Chef Software, Inc.
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

describe Ohai::System, "plugin perl" do
  let(:plugin) { get_plugin("perl") }

  before(:each) do
    plugin[:languages] = Mash.new
    @stdout = "version='5.8.8';#{$/}archname='darwin-thread-multi-2level';"
    allow(plugin).to receive(:shell_out).with("perl -V:version -V:archname").and_return(mock_shell_out(0, @stdout, ""))
  end

  it "runs perl -V:version -V:archname" do
    expect(plugin).to receive(:shell_out).with("perl -V:version -V:archname").and_return(mock_shell_out(0, "", ""))
    plugin.run
  end

  it "sets languages[:perl][:version]" do
    plugin.run
    expect(plugin.languages[:perl][:version]).to eql("5.8.8")
  end

  it "sets languages[:perl][:archname]" do
    plugin.run
    expect(plugin.languages[:perl][:archname]).to eql("darwin-thread-multi-2level")
  end

  it "sets languages[:perl] if perl command succeeds" do
    plugin.run
    expect(plugin.languages).to have_key(:perl)
  end

  it "does not set languages[:perl] if perl command fails" do
    allow(plugin).to receive(:shell_out).with("perl -V:version -V:archname").and_return(mock_shell_out(1, "", ""))
    plugin.run
    expect(plugin.languages).not_to have_key(:perl)
  end

  it "does not set languages[:perl] if perl command doesn't exist" do
    allow(plugin).to receive(:shell_out).and_raise(Ohai::Exceptions::Exec)
    plugin.run
    expect(plugin.languages).not_to have_key(:perl)
  end
end
