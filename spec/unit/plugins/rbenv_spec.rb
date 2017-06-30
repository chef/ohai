#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2017 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../../spec_helper.rb"

describe Ohai::System, "plugin rbenv" do
  let(:stdout) { <<-OUT
system
* 2.4.1 (set by /Users/tsmith/.rbenv/version)
OUT
}
  let(:plugin) do
    plugin = get_plugin("rbenv")
    plugin[:languages] = Mash.new
    plugin[:languages][:ruby] = Mash.new
    expect(plugin).to receive(:shell_out).with("rbenv versions").and_return(mock_shell_out(0, stdout, ""))
    expect(plugin).to receive(:shell_out).with("rbenv --version").and_return(mock_shell_out(0, "rbenv 1.1.1", ""))
    plugin
  end

  it "sets the rbenv version" do
    plugin.run
    expect(plugin[:languages][:ruby][:rbenv][:rbenv_version]).to eql("1.1.1")
  end

  it "sets the default ruby version" do
    plugin.run
    expect(plugin[:languages][:ruby][:rbenv][:default]).to eql("2.4.1")
  end

  it "versions includes ruby 2.4.1" do
    plugin.run
    expect(plugin[:languages][:ruby][:rbenv][:versions]).to include("2.4.1")
  end

  it "versions doesn't include the system ruby" do
    plugin.run
    expect(plugin[:languages][:ruby][:rbenv][:versions]).not_to include("system")
  end
end
