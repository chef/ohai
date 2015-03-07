# Author:: Dave Parfitt <dparfitt@chef.io>
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

describe Ohai::System, "plugin haskell" do

  before(:each) do
    @plugin = get_plugin("haskell")
    @plugin[:languages] = Mash.new
    @stdout = "The Glorious Glasgow Haskell Compilation System, version 7.6.3\n"
    allow(@plugin).to receive(:shell_out).with("ghc --version").and_return(mock_shell_out(0, @stdout, ""))
  end

  it "should get the haskell version from running ghc --version" do
    expect(@plugin).to receive(:shell_out).with("ghc --version").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
  end

  it "should set languages[:haskell][:version]" do
    @plugin.run
    expect(@plugin.languages[:haskell][:version]).to eql("7.6.3")
  end

  it "should not set the languages[:haskell] tree up if ghc --version fails" do
    @stdout = "The Glorious Glasgow Haskell Compilation System, version 7.6.3\n"
    allow(@plugin).to receive(:shell_out).with("ghc --version").and_return(mock_shell_out(1, @stdout, ""))
    @plugin.run
    expect(@plugin.languages).not_to have_key(:haskell)
  end

end
