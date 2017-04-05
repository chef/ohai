# Author:: Christopher M Luciano (<cmlucian@us.ibm.com>)
# © Copyright IBM Corporation 2015.
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

describe Ohai::System, "plugin scala" do

  let(:plugin) do
    plugin = get_plugin("scala").tap do |plugin|
      plugin[:languages] = Mash.new
    end
  end

  let(:scala_out) { "Scala code runner version 2.11.6 -- Copyright 2002-2013, LAMP/EPFL" }

  def setup_plugin
    allow(plugin).to receive(:shell_out)
      .with("scala -version")
      .and_return(mock_shell_out(0, "", scala_out))
  end

  context "if scala is installed" do
    before(:each) do
      setup_plugin
      plugin.run
    end

    it "sets languages[:scala][:version]" do
      expect(plugin[:languages][:scala][:version]).to eql("2.11.6")
    end
  end

  context "if scala is not installed" do
    before(:each) do
      allow(plugin).to receive(:shell_out)
        .and_raise( Ohai::Exceptions::Exec )
      plugin.run
    end

    it "does NOT set the languages[:scala] if scala commands fails" do
      expect(plugin[:languages]).not_to have_key(:scala)
    end
  end
end
