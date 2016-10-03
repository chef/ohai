#
# Author:: Claire McQuin (<claire@chef.io>)
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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

require_relative "../spec_helper"

require "info_getter/config"

RSpec.describe info_getter::Config do

  describe "top-level configuration options" do
    shared_examples_for "option" do
      it "logs a deprecation warning and sets the value" do
        expect(info_getter::Log).to receive(:warn).
          with(/info_getter::Config\[:#{option}\] is deprecated/)
        info_getter::Config[option] = value
        expect(info_getter::Config[option]).to eq(value)
      end
    end

    shared_examples_for "appendable option" do
      it "sets the value" do
        expect(info_getter::Log).to_not receive(:warn)
        info_getter::Config[option] << value
        expect(info_getter::Config[option]).to include(value)
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

  describe "config_context :info_getter" do
    describe "option :plugin" do
      it "gets configured with a value" do
        info_getter::Config.info_getter[:plugin][:foo] = true
        expect(info_getter::Config.info_getter[:plugin]).to have_key(:foo)
        expect(info_getter::Config.info_getter[:plugin][:foo]).to be true
      end

      it "gets configured with a Hash" do
        value = { :bar => true, :baz => true }
        info_getter::Config.info_getter[:plugin][:foo] = value
        expect(info_getter::Config.info_getter[:plugin]).to have_key(:foo)
        expect(info_getter::Config.info_getter[:plugin][:foo]).to eq(value)
      end

      it "raises an error if the plugin name is not a symbol" do
        expect { info_getter::Config.info_getter[:plugin]["foo"] = false }.
          to raise_error(info_getter::Exceptions::PluginConfigError, /Expected Symbol/)
      end

      it "raises an error if the value Hash has non-Symbol key" do
        value = { :bar => true, "baz" => true }
        expect { info_getter::Config.info_getter[:plugin][:foo] = value }.
          to raise_error(info_getter::Exceptions::PluginConfigError, /Expected Symbol/)
      end
    end
  end

  describe "::merge_deprecated_config" do
    before(:each) do
      allow(info_getter::Log).to receive(:warn)
      configure_info_getter
    end

    def configure_info_getter
      info_getter::Config[:directory] = "/some/fantastic/plugins"
      info_getter::Config[:disabled_plugins] = [ :Foo, :Baz ]
      info_getter::Config[:log_level] = :debug
    end

    it "merges top-level config values into the info_getter config context" do
      info_getter::Config.merge_deprecated_config
      expect(info_getter::Config.info_getter.configuration).to eq (info_getter::Config.configuration)
    end

    shared_examples_for "delayed warn" do
      it "logs a deprecation warning and merges the value" do
        expect(info_getter::Log).to receive(:warn).
          with(/info_getter::Config\[:#{option}\] is deprecated/)
        info_getter::Config[option] << value
        info_getter::Config.merge_deprecated_config
        expect(info_getter::Config.info_getter[option]).to include(value)
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

  describe "info_getter.config" do
    it "returns the info_getter config context" do
      expect(info_getter.config).to eq(info_getter::Config.info_getter)
    end
  end
end
