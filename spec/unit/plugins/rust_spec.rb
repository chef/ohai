# Author:: Christopher M Luciano (<cmlucian@us.ibm.com>)
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

describe Ohai::System, "plugin rust" do
  let(:stdout) { "rustc 1.0.0-nightly (29bd9a06e 2015-01-20 23:03:09 +0000)" }
  let (:plugin) do
    plugin = get_plugin("rust")
    plugin[:languages] = Mash.new
    allow(plugin).to receive(:shell_out).with("rustc --version").and_return(mock_shell_out(0, stdout, ""))
    plugin
  end

  it "should get the rust version" do
    expect(plugin).to receive(:shell_out).with("rustc --version").and_return(mock_shell_out(0, stdout, ""))
    plugin.run
  end

  it "should set languages[:rust][:version]" do
    plugin.run
    expect(plugin.languages[:rust][:version]).to eql("1.0.0-nightly")
  end

  it "should not set the languages[:rust] if rust command fails" do
    allow(plugin).to receive(:shell_out).with("rustc --version").and_return(mock_shell_out(1, stdout, ""))
    plugin.run
    expect(plugin.languages).not_to have_key(:rust)
  end
end
