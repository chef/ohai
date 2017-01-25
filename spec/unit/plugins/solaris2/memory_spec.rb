#
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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "Solaris2.X memory plugin" do
  before(:each) do
    @plugin = get_plugin("solaris2/memory")
    allow(@plugin).to receive(:collect_os).and_return("solaris2")
    allow(@plugin).to receive(:shell_out).with("prtconf | grep Memory").and_return(mock_shell_out(0, "Memory size: 8194 Megabytes\n", ""))
    @swap_s = "total: 112230656k bytes allocated + 357865576k reserved = 470096232k used, 47057688k available\n"
    allow(@plugin).to receive(:shell_out).with("swap -s").and_return(mock_shell_out(0, @swap_s, ""))
  end

  it "should get the total memory" do
    @plugin.run
    expect(@plugin[:memory][:total]).to eql("#{8194 * 1024}kB")
  end

  it "should get total swap" do
    @plugin.run
    expect(@plugin[:memory][:swap][:total]).to eql("#{(470096232 + 47057688)}kB" )
  end

  it "should get free swap" do
    @plugin.run
    expect(@plugin[:memory][:swap][:free]).to eql("47057688kB")
  end

end
