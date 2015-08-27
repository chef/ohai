#
# Author:: Claire McQuin (<claire@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

require_relative '../spec_helper'

require 'ohai/config'

RSpec.describe Ohai::Config do

  describe "top-level configuration options" do
    shared_examples_for "option" do
      it "logs a deprecation warning and sets the value" do
        expect(Ohai::Log).to receive(:warn).
          with(/Ohai::Config\[:#{option}\] is deprecated/)
        Ohai::Config[option] = value
        expect(Ohai::Config[option]).to eq(value)
      end
    end

    shared_examples_for "appendable option" do
      it "sets the value" do
        expect(Ohai::Log).to_not receive(:warn)
        Ohai::Config[option] << value
        expect(Ohai::Config[option]).to include(value)
      end
    end

    describe ":directory" do
      include_examples "option" do
        let(:option) { :directory }
        let(:value)  { "/some/fantastic/plugins" }
      end
    end

    describe ":disabled_plugins" do
      include_examples "option" do
        let(:option) { :disabled_plugins }
        let(:value)  { [ :Foo, :Baz ] }
      end
    end

    describe ":hints_path" do
      include_examples "appendable option" do
        let(:option) { :hints_path }
        let(:value)  { "/some/helpful/hints" }
      end
    end

    describe ":log_level" do
      include_examples "option" do
        let(:option) { :log_level }
        let(:value)  { :cheese }
      end
    end

    describe ":log_location" do
      include_examples "option" do
        let(:option) { :log_location }
        let(:value)  { "/etc/chef/cache/loooogs" }
      end
    end

    describe ":plugin_path" do
      include_examples "appendable option" do
        let(:option) { :plugin_path }
        let(:value)  { "/some/fantastic/plugins" }
      end
    end

    describe ":version" do
      include_examples "option" do
        let(:option) { :version }
        let(:value)  { "8.2.0" }
      end
    end
  end

  describe "config_context :ohai" do
    describe "option :plugin" do
      it "gets configured with a value" do
        Ohai::Config.ohai[:plugin][:foo] = true
        expect(Ohai::Config.ohai[:plugin]).to have_key(:foo)
        expect(Ohai::Config.ohai[:plugin][:foo]).to be true
      end

      it "gets configured with a Hash" do
        value = { :bar => true, :baz => true }
        Ohai::Config.ohai[:plugin][:foo] = value
        expect(Ohai::Config.ohai[:plugin]).to have_key(:foo)
        expect(Ohai::Config.ohai[:plugin][:foo]).to eq(value)
      end

      it "raises an error if the plugin name is not a symbol" do
        expect { Ohai::Config.ohai[:plugin]["foo"] = false }.
          to raise_error(Ohai::Exceptions::PluginConfigError, /Expected Symbol/)
      end

      it "raises an error if the value Hash has non-Symbol key" do
        value = { :bar => true, "baz" => true }
        expect { Ohai::Config.ohai[:plugin][:foo] = value }.
          to raise_error(Ohai::Exceptions::PluginConfigError, /Expected Symbol/)
      end
    end
  end

  describe "::merge_deprecated_config" do
    before(:each) do
      allow(Ohai::Log).to receive(:warn)
      configure_ohai
    end

    def configure_ohai
      Ohai::Config[:directory] = "/some/fantastic/plugins"
      Ohai::Config[:disabled_plugins] = [ :Foo, :Baz ]
      Ohai::Config[:log_level] = :debug
    end

    it "merges top-level config values into the ohai config context" do
      Ohai::Config.merge_deprecated_config
      expect(Ohai::Config.ohai.configuration).to eq (Ohai::Config.configuration)
    end

    shared_examples_for "delayed warn" do
      it "logs a deprecation warning and merges the value" do
        expect(Ohai::Log).to receive(:warn).
          with(/Ohai::Config\[:#{option}\] is deprecated/)
        Ohai::Config[option] << value
        Ohai::Config.merge_deprecated_config
        expect(Ohai::Config.ohai[option]).to include(value)
      end
    end

    context "when :hints_path is set" do
      include_examples "delayed warn" do
        let(:option) { :hints_path }
        let(:value)  { "/some/helpful/hints" }
      end
    end

    context "when :plugin_path is set" do
      include_examples "delayed warn" do
        let(:option) { :plugin_path }
        let(:value)  { "/some/fantastic/plugins" }
      end
    end
  end

  describe "Ohai.config" do
    it "returns the ohai config context" do
      expect(Ohai.config).to eq(Ohai::Config.ohai)
    end
  end
end
