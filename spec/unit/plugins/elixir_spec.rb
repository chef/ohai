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

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '/spec_helper.rb'))

describe Ohai::System, "plugin elixir" do

  before(:each) do
    @plugin = get_plugin("elixir")
    @plugin[:languages] = Mash.new
    @stdout = "Elixir 1.0.2"
    allow(@plugin).to receive(:shell_out).with("elixir -v").and_return(mock_shell_out(0, @stdout, ""))
  end

  it "should get the elixir version" do
    expect(@plugin).to receive(:shell_out).with("elixir -v").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
  end

  it "should set languages[:elixir][:version]" do
    @plugin.run
    expect(@plugin.languages[:elixir][:version]).to eql("1.0.2")
  end

  it "should not set the languages[:elixir] if elixir command fails" do
    @stdout = "Elixir 1.0.2\n"
    allow(@plugin).to receive(:shell_out).with("elixir -v").and_return(mock_shell_out(1, @stdout, ""))
    @plugin.run
    expect(@plugin.languages).not_to have_key(:elixir)
  end

end

