# Author:: Chris Dituri (<csdituri@gmail.com>)
# Copyright:: Copyright (c) 2016 Chris Dituri
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

describe Ohai::System, "plugin haskell" do

  let(:plugin) do
    plugin = get_plugin("haskell").tap do |plugin|
      plugin[:languages] = Mash.new
    end
  end

  let(:ghc_out) { "The Glorious Glasgow Haskell Compilation System, version 7.6.3" }
  let(:ghci_out) { "The Glorious Glasgow Haskell Compilation System, version 7.6.3" }
  let(:cabal_out) { "cabal-install version 1.16.0.2\nusing version 1.16.0 of the Cabal library" }
  let(:stack_out) { "Version 1.2.0 x86_64 hpack-0.14.0" }
  let(:stack_out_git) { "Version 1.1.0, Git revision 0e9430aad55841b5ff2c6c2851f0548c16bce7cf (3540 commits) x86_64 hpack-0.13.0" }

  def setup_plugin
    allow(plugin).to receive(:shell_out)
      .with("ghc --version")
      .and_return(mock_shell_out(0, ghc_out, ""))
    allow(plugin).to receive(:shell_out)
      .with("ghci --version")
      .and_return(mock_shell_out(0, ghci_out, ""))
    allow(plugin).to receive(:shell_out)
      .with("cabal --version")
      .and_return(mock_shell_out(0, cabal_out, ""))
    allow(plugin).to receive(:shell_out)
      .with("stack --version")
      .and_return(mock_shell_out(0, stack_out, ""))
  end

  context "if haskell/ghc is installed" do

    before(:each) do
      setup_plugin
      plugin.run
    end

    it "set languages[:haskell][:ghc][:version]" do
      expect(plugin[:languages][:haskell][:ghc][:version]).to eql("7.6.3")
    end

    it "set languages[:haskell][:ghc][:description]" do
      expect(plugin[:languages][:haskell][:ghc][:description]).to eql(ghc_out)
    end
  end

  context "if haskell/ghci is installed" do

    before(:each) do
      setup_plugin
      plugin.run
    end

    it "set languages[:haskell][:ghci][:version]" do
      expect(plugin[:languages][:haskell][:ghci][:version]).to eql("7.6.3")
    end

    it "set languages[:haskell][:ghci][:description]" do
      expect(plugin[:languages][:haskell][:ghci][:description]).to eql(ghci_out)
    end
  end

  context "if haskell/cabal is installed" do

    before(:each) do
      setup_plugin
      plugin.run
    end

    it "set languages[:haskell][:cabal][:version]" do
      expect(plugin[:languages][:haskell][:cabal][:version]).to eql("1.16.0.2")
    end

    it "set languages[:haskell][:cabal][:description]" do
      expect(plugin[:languages][:haskell][:cabal][:description]).to eql(cabal_out.split("\n")[0].chomp)
    end
  end

  context "if haskell/stack is installed" do

    before(:each) do
      setup_plugin
      plugin.run
    end

    it "set languages[:haskell][:stack][:version]" do
      expect(plugin[:languages][:haskell][:stack][:version]).to eql("1.2.0")
    end

    it "set languages[:haskell][:stack][:description]" do
      expect(plugin[:languages][:haskell][:stack][:description]).to eql(stack_out)
    end
  end

  context "if haskell/stack prerelease is installed" do

    before(:each) do
      setup_plugin
      allow(plugin).to receive(:shell_out)
        .with("stack --version")
        .and_return(mock_shell_out(0, stack_out_git, ""))
      plugin.run
    end

    it "set languages[:haskell][:stack][:version]" do
      expect(plugin[:languages][:haskell][:stack][:version]).to eql("1.1.0")
    end

    it "set languages[:haskell][:stack][:description]" do
      expect(plugin[:languages][:haskell][:stack][:description]).to eql(stack_out_git)
    end
  end

  context "if haskell is NOT installed" do

    before(:each) do
      allow(plugin).to receive(:shell_out)
        .and_raise( Ohai::Exceptions::Exec )
      plugin.run
    end

    it "do NOT set languages[:haskell]" do
      expect(plugin[:languages]).not_to have_key(:haskell)
    end
  end

  context "if haskell/ghc is NOT installed" do
    before(:each) do
      allow(plugin).to receive(:shell_out)
        .with("ghc --version")
        .and_raise( Ohai::Exceptions::Exec )
      allow(plugin).to receive(:shell_out)
        .with("ghci --version")
        .and_return(mock_shell_out(0, ghci_out, ""))
      allow(plugin).to receive(:shell_out)
        .with("cabal --version")
        .and_return(mock_shell_out(0, cabal_out, ""))
      allow(plugin).to receive(:shell_out)
        .with("stack --version")
        .and_return(mock_shell_out(0, stack_out, ""))
      plugin.run
    end

    it "do NOT set languages[:haskell][:ghc]" do
      expect(plugin[:languages][:haskell]).not_to have_key(:ghc)
    end
  end

  context "if haskell/ghci is NOT installed" do
    before(:each) do
      allow(plugin).to receive(:shell_out)
        .with("ghc --version")
        .and_return(mock_shell_out(0, ghc_out, ""))
      allow(plugin).to receive(:shell_out)
        .with("ghci --version")
        .and_raise( Ohai::Exceptions::Exec )
      allow(plugin).to receive(:shell_out)
        .with("cabal --version")
        .and_return(mock_shell_out(0, cabal_out, ""))
      allow(plugin).to receive(:shell_out)
        .with("stack --version")
        .and_return(mock_shell_out(0, stack_out, ""))
      plugin.run
    end

    it "do NOT set languages[:haskell][:ghci]" do
      expect(plugin[:languages][:haskell]).not_to have_key(:ghci)
    end
  end

  context "if haskell/cabal is NOT installed" do
    before(:each) do
      allow(plugin).to receive(:shell_out)
        .with("ghc --version")
        .and_return(mock_shell_out(0, ghc_out, ""))
      allow(plugin).to receive(:shell_out)
        .with("ghci --version")
        .and_return(mock_shell_out(0, ghci_out, ""))
      allow(plugin).to receive(:shell_out)
        .with("cabal --version")
        .and_raise( Ohai::Exceptions::Exec )
      allow(plugin).to receive(:shell_out)
        .with("stack --version")
        .and_return(mock_shell_out(0, stack_out, ""))
      plugin.run
    end

    it "do NOT set languages[:haskell][:cabal]" do
      expect(plugin[:languages][:haskell]).not_to have_key(:cabal)
    end
  end

  context "if haskell/stack is NOT installed" do
    before(:each) do
      allow(plugin).to receive(:shell_out)
        .with("ghc --version")
        .and_return(mock_shell_out(0, ghc_out, ""))
      allow(plugin).to receive(:shell_out)
        .with("ghci --version")
        .and_return(mock_shell_out(0, ghci_out, ""))
      allow(plugin).to receive(:shell_out)
        .with("cabal --version")
        .and_return(mock_shell_out(0, cabal_out, ""))
      allow(plugin).to receive(:shell_out)
        .with("stack --version")
        .and_raise( Ohai::Exceptions::Exec )
      plugin.run
    end

    it "do NOT set languages[:haskell][:stack]" do
      expect(plugin[:languages][:haskell]).not_to have_key(:stack)
    end
  end
end
