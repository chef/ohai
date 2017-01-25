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
# See the License for the specific language elixirverning permissions and
# limitations under the License.
#

require_relative "../../spec_helper.rb"

describe Ohai::System, "plugin elixir" do
  let(:plugin) { get_plugin("elixir") }

  before(:each) do
    plugin[:languages] = Mash.new
  end

  it "should shellout to elixir -v" do
    expect(plugin).to receive(:shell_out).with("elixir -v").and_return(mock_shell_out(0, "Elixir 1.0.2", ""))
    plugin.run
  end

  it "sets languages[:elixir][:version] on older elixir" do
    allow(plugin).to receive(:shell_out).with("elixir -v").and_return(mock_shell_out(0, "Elixir 1.0.2", ""))
    plugin.run
    expect(plugin.languages[:elixir][:version]).to eql("1.0.2")
  end

  it "sets languages[:elixir][:version] on newer elixir" do
    new_stdout = "Erlang/OTP 18 [erts-7.3] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]\n\nElixir 1.2.4\n"
    allow(plugin).to receive(:shell_out).with("elixir -v").and_return(mock_shell_out(0, new_stdout, ""))
    plugin.run
    expect(plugin.languages[:elixir][:version]).to eql("1.2.4")
  end

  it "does not set languages[:elixir] if elixir command fails" do
    allow(plugin).to receive(:shell_out).with("elixir -v").and_return(mock_shell_out(1, "", ""))
    plugin.run
    expect(plugin.languages).not_to have_key(:elixir)
  end

  it "does not set languages[:elixir] if elixir command doesn't exist" do
    allow(plugin).to receive(:shell_out).and_raise(Ohai::Exceptions::Exec)
    plugin.run
    expect(plugin.languages).not_to have_key(:elixir)
  end
end
