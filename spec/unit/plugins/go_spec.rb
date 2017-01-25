# Author:: Christian Vozar (<christian@rogueethic.com>)
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

require_relative "../../spec_helper.rb"

describe Ohai::System, "plugin go" do
  let(:plugin) { get_plugin("go") }

  before(:each) do
    plugin[:languages] = Mash.new
    stdout = "go version go1.6.1 darwin/amd64\n"
    allow(plugin).to receive(:shell_out).with("go version").and_return(mock_shell_out(0, stdout, ""))
  end

  it "it shells out to get the go version" do
    expect(plugin).to receive(:shell_out).with("go version")
    plugin.run
  end

  it "sets languages[:go][:version]" do
    plugin.run
    expect(plugin.languages[:go][:version]).to eql("1.6.1")
  end

  it "does not set languages[:go] if go command fails" do
    allow(plugin).to receive(:shell_out).with("go version").and_return(mock_shell_out(1, "", ""))
    plugin.run
    expect(plugin.languages).not_to have_key(:go)
  end

  it "does not set languages[:go] if go command doesn't exist" do
    allow(plugin).to receive(:shell_out).and_raise(Ohai::Exceptions::Exec)
    plugin.run
    expect(plugin.languages).not_to have_key(:go)
  end
end
