#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Claire McQuin (<claire@chef.io>)
# Copyright:: Copyright (c) 2008-2017, Chef Software Inc.
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

require "spec_helper"
require "ohai/mixin/os"

describe "Ohai::System" do
  extend IntegrationSupport

  let(:ohai_external) {}
  let(:ohai) { Ohai::System.new({ invoked_from_cli: true }) }

  describe "#initialize" do
    it "returns an Ohai::System object" do
      expect(ohai).to be_a_kind_of(Ohai::System)
    end

    it "sets @attributes to a ProvidesMap" do
      expect(ohai.provides_map).to be_a_kind_of(Ohai::ProvidesMap)
    end

    it "merges provided configuration options into the ohai config context" do
      config = {
        disabled_plugins: %i{Foo Baz},
        directory: ["/some/extra/plugins"],
        critical_plugins: %i{Foo Bar},
      }
      Ohai::System.new(config)
      config.each do |option, value|
        expect(Ohai.config[option]).to eq(value)
      end
    end

    context "when a single directory is configured as a string" do
      let(:directory) { "/some/fantastic/plugins" }

      it "adds directory to plugin_path" do
        Ohai.config[:directory] = directory
        Ohai::System.new({ invoked_from_cli: true })
        expect(Ohai.config[:plugin_path]).to include("/some/fantastic/plugins")
      end
    end

    context "when multiple directories are configured" do
      let(:directory) { ["/some/fantastic/plugins", "/some/other/plugins"] }

      it "adds directories to plugin_path" do
        Ohai.config[:directory] = directory
        Ohai::System.new({ invoked_from_cli: true })
        expect(Ohai.config[:plugin_path]).to include("/some/fantastic/plugins")
        expect(Ohai.config[:plugin_path]).to include("/some/other/plugins")
      end
    end

    context "when testing the intializer that does way too much" do
      it "configures logging" do
        log_level = :debug
        Ohai.config[:log_level] = log_level
        expect(Ohai::Log).to receive(:level=).with(log_level)
        Ohai::System.new({ invoked_from_cli: true })
      end

      it "resolves log_level when set to :auto" do
        expect(Ohai::Log).to receive(:level=).with(:info)
        Ohai::System.new({ invoked_from_cli: true })
      end

      context "when called externally" do
        it "does not configure logging" do
          log_level = :debug
          Ohai.config[:log_level] = log_level
          expect(Ohai::Log).not_to receive(:level=).with(log_level)
          Ohai::System.new
        end

        it "does not resolve log_level when set to :auto" do
          expect(Ohai::Log).not_to receive(:level=).with(:info)
          Ohai::System.new
        end
      end
    end
  end

  when_plugins_directory "contains directories inside" do
    with_plugin("repo1/zoo.rb", <<~EOF)
      Ohai.plugin(:Zoo) do
        provides 'seals'
      end
    EOF

    with_plugin("repo1/lake.rb", <<~EOF)
      Ohai.plugin(:Nature) do
      provides 'fish'
      end
    EOF

    with_plugin("repo2/nature.rb", <<~EOF)
      Ohai.plugin(:Nature) do
        provides 'crabs'
      end
    EOF

    with_plugin("repo2/mountain.rb", <<~EOF)
      Ohai.plugin(:Nature) do
      provides 'bear'
      end
    EOF

    before do
      Ohai.config[:plugin_path] = [ path_to("repo1"), path_to("repo2") ]
    end

    it "load_plugins() should load all the plugins" do
      ohai.load_plugins
      expect(ohai.provides_map.map.keys).to include("seals")
      expect(ohai.provides_map.map.keys).to include("crabs")
      expect(Ohai::NamedPlugin.const_get(:Zoo)).to eq(Ohai::NamedPlugin::Zoo)
      expect(Ohai::NamedPlugin.const_get(:Nature)).to eq(Ohai::NamedPlugin::Nature)
    end

  end

  describe "when running plugins" do
    when_plugins_directory "contains a v7 plugins with :default and platform specific blocks" do
      with_plugin("message.rb", <<~EOF)
        Ohai.plugin(:Message) do
          provides 'message'

          collect_data(:default) do
            message("default")
          end

          collect_data(:#{Ohai::Mixin::OS.collect_os}) do
            message("platform_specific_message")
          end
        end
      EOF

      it "collects platform specific" do
        Ohai.config[:plugin_path] = [ path_to(".") ]
        ohai.all_plugins
        expect(ohai.data[:message]).to eq("platform_specific_message")
      end
    end

    when_plugins_directory "contains v7 plugins only" do
      with_plugin("zoo.rb", <<~EOF)
        Ohai.plugin(:Zoo) do
          provides 'zoo'

          collect_data(:default) do
            zoo("animals")
          end
        end
      EOF

      with_plugin("park.rb", <<~EOF)
        Ohai.plugin(:Park) do
          provides 'park'
          collect_data(:default) do
            park("plants")
          end
        end
      EOF

      with_plugin("fails.rb", <<~EOF)
        Ohai.plugin(:Fails) do
          provides 'fails'
          collect_data(:default) do
            fail 'thing'
          end
        end
      EOF

      with_plugin("optional.rb", <<~EOF)
        Ohai.plugin(:Optional) do
          provides 'optional'
          optional true

          collect_data(:default) do
            optional("canteloupe")
          end
        end
      EOF

      it "collects data from all the plugins" do
        Ohai.config[:plugin_path] = [ path_to(".") ]
        ohai.all_plugins
        expect(ohai.data[:zoo]).to eq("animals")
        expect(ohai.data[:park]).to eq("plants")
        expect(ohai.data[:zoo]).to be_frozen
        expect(ohai.data[:park]).to be_frozen
      end

      it "writes an error to Ohai::Log" do
        Ohai.config[:plugin_path] = [ path_to(".") ]
        # Make sure the stubbing of runner is not overriden with reset_system during test
        allow(ohai).to receive(:reset_system)
        allow(ohai.instance_variable_get("@runner")).to receive(:run_plugin).and_raise(Ohai::Exceptions::AttributeNotFound)
        expect(ohai.logger).to receive(:error).with(/Encountered error while running plugins/)
        expect { ohai.all_plugins }.to raise_error(Ohai::Exceptions::AttributeNotFound)
      end

      describe "when using :disabled_plugins" do
        before do
          Ohai.config[:disabled_plugins] = [ :Zoo ]
        end

        after do
          Ohai.config[:disabled_plugins] = [ ]
        end

        it "does not run disabled plugins" do
          Ohai.config[:plugin_path] = [ path_to(".") ]
          ohai.all_plugins
          expect(ohai.data[:zoo]).to be_nil
          expect(ohai.data[:park]).to eq("plants")
        end
      end

      describe "when using :critical_plugins" do
        # if called from cli is true, we'll exit these tests
        let(:ohai) { Ohai::System.new }

        before do
          Ohai.config[:critical_plugins] = [ :Fails ]
        end

        after do
          Ohai.config[:critical_plugins] = []
        end

        it "fails when critical plugins fail" do
          Ohai.config[:plugin_path] = [ path_to(".") ]
          expect { ohai.all_plugins }.to raise_error(Ohai::Exceptions::CriticalPluginFailure,
            "The following Ohai plugins marked as critical failed: [:Fails]. Failing Chef run.")
        end
      end

      describe "when using :optional_plugins" do
        it "does not run optional plugins by default" do
          Ohai.config[:plugin_path] = [ path_to(".") ]
          ohai.all_plugins
          expect(ohai.data[:optional]).to be_nil
        end

        it "runs optional plugins when specifically enabled" do
          Ohai.config[:optional_plugins] = [ :Optional ]
          Ohai.config[:plugin_path] = [ path_to(".") ]
          ohai.all_plugins
          expect(ohai.data[:optional]).to eq("canteloupe")
        end

        it "runs optional plugins when all plugins are enabled" do
          Ohai.config[:run_all_plugins] = true
          Ohai.config[:plugin_path] = [ path_to(".") ]
          ohai.all_plugins
          expect(ohai.data[:optional]).to eq("canteloupe")
        end
      end
    end
  end

  describe "when Chef OHAI resource executes :reload action" do

    when_plugins_directory "contains a random plugin" do
      with_plugin("random.rb", <<-E)
        Ohai.plugin(:Random) do
          provides 'random'

          collect_data do
            random rand(1 << 32)
          end
        end
      E

      before do
        Ohai.config[:plugin_path] = [ path_to(".") ]
      end

      it "reruns the plugin providing the desired attributes" do
        ohai.all_plugins
        initial_value = ohai.data["random"]
        ohai.all_plugins
        updated_value = ohai.data["random"]
        expect(initial_value).not_to eq(updated_value)
      end

    end
  end

  describe "when running ohai for specific attributes" do
    when_plugins_directory "contains v7 plugins" do
      with_plugin("languages.rb", <<-E)
        Ohai.plugin(:Languages) do
          provides 'languages'

          collect_data do
            languages Mash.new
          end
        end
      E

      with_plugin("english.rb", <<-E)
        Ohai.plugin(:English) do
          provides 'languages/english'

          depends 'languages'

          collect_data do
            languages[:english] = Mash.new
            languages[:english][:version] = 2014
          end
        end
      E

      with_plugin("french.rb", <<-E)
        Ohai.plugin(:French) do
          provides 'languages/french'

          depends 'languages'

          collect_data do
            languages[:french] = Mash.new
            languages[:french][:version] = 2012
          end
        end
      E

      before do
        Ohai.config[:plugin_path] = [ path_to(".") ]
      end

      it "runs all the plugins when a top level attribute is specified" do
        ohai.all_plugins("languages")
        expect(ohai.data[:languages][:english][:version]).to eq(2014)
        expect(ohai.data[:languages][:french][:version]).to eq(2012)
      end

      it "runs the first parent when a non-existent child is specified" do
        ohai.all_plugins("languages/english/version")
        expect(ohai.data[:languages][:english][:version]).to eq(2014)
        expect(ohai.data[:languages][:french]).to be_nil
      end

      it "is able to run multiple plugins" do
        ohai.all_plugins(["languages/english", "languages/french"])
        expect(ohai.data[:languages][:english][:version]).to eq(2014)
        expect(ohai.data[:languages][:french][:version]).to eq(2012)
      end

    end
  end

  describe "when loading a specific plugin path" do
    when_plugins_directory "contains v7 plugins" do
      with_plugin("my_cookbook/canteloupe.rb", <<-E)
        Ohai.plugin(:Canteloupe) do
          provides 'canteloupe'

          collect_data do
            canteloupe Mash.new
          end
        end
      E

      with_plugin("english/english.rb", <<-E)
        Ohai.plugin(:English) do
          provides 'canteloupe/english'

          depends 'canteloupe'

          collect_data do
            canteloupe[:english] = Mash.new
            canteloupe[:english][:version] = 2014
          end
        end
      E

      with_plugin("french/french.rb", <<-E)
        Ohai.plugin(:French) do
          provides 'canteloupe/french'

          depends 'canteloupe'

          collect_data do
            canteloupe[:french] = Mash.new
            canteloupe[:french][:version] = 2012
          end
        end
      E

      it "runs all the plugins" do
        ohai.run_additional_plugins(@plugins_directory)
        expect(ohai.data[:canteloupe][:english][:version]).to eq(2014)
        expect(ohai.data[:canteloupe][:french][:version]).to eq(2012)
      end
    end
  end
end
