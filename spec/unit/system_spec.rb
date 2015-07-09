#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Claire McQuin (<claire@opscode.com>)
# Copyright:: Copyright (c) 2008, 2013 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'ohai/mixin/os'

describe "Ohai::System" do
  extend IntegrationSupport

  let(:ohai) { Ohai::System.new }

  describe "#initialize" do
    it "should return an Ohai::System object" do
      expect(ohai).to be_a_kind_of(Ohai::System)
    end

    it "should set @attributes to a ProvidesMap" do
      expect(ohai.provides_map).to be_a_kind_of(Ohai::ProvidesMap)
    end

    it "should set @v6_dependency_solver to a Hash" do
      expect(ohai.v6_dependency_solver).to be_a_kind_of(Hash)
    end
  end

  when_plugins_directory "contains v6 and v7 plugins" do
    with_plugin("zoo.rb", <<EOF)
Ohai.plugin(:Zoo) do
  provides 'seals'
end
EOF

    with_plugin("lake.rb", <<EOF)
provides 'fish'
EOF

    before do
      Ohai.config[:plugin_path] = [ path_to(".") ]
    end

    it "load_plugins() should load all the plugins" do
      ohai.load_plugins
      expect(ohai.provides_map.map.keys).to include("seals")
      expect(ohai.v6_dependency_solver.keys).to include("lake.rb")
      expect(Ohai::NamedPlugin.const_get(:Zoo)).to eq(Ohai::NamedPlugin::Zoo)
    end
  end

  when_plugins_directory "contains directories inside" do
    with_plugin("repo1/zoo.rb", <<EOF)
Ohai.plugin(:Zoo) do
  provides 'seals'
end
EOF

    with_plugin("repo1/lake.rb", <<EOF)
provides 'fish'
EOF

    with_plugin("repo2/nature.rb", <<EOF)
Ohai.plugin(:Nature) do
  provides 'crabs'
end
EOF

    with_plugin("repo2/mountain.rb", <<EOF)
provides 'bear'
EOF

    before do
      Ohai.config[:plugin_path] = [ path_to("repo1"), path_to("repo2") ]
    end

    it "load_plugins() should load all the plugins" do
      ohai.load_plugins
      expect(ohai.provides_map.map.keys).to include("seals")
      expect(ohai.provides_map.map.keys).to include("crabs")
      expect(ohai.v6_dependency_solver.keys).to include("lake.rb")
      expect(ohai.v6_dependency_solver.keys).to include("mountain.rb")
      expect(Ohai::NamedPlugin.const_get(:Zoo)).to eq(Ohai::NamedPlugin::Zoo)
      expect(Ohai::NamedPlugin.const_get(:Nature)).to eq(Ohai::NamedPlugin::Nature)
    end

  end

  describe "when running plugins" do
    when_plugins_directory "contains v6 plugins only" do
      with_plugin("zoo.rb", <<EOF)
provides 'zoo'
zoo("animals")
EOF

      with_plugin("park.rb", <<EOF)
provides 'park'
park("plants")
EOF

      it "should collect data from all the plugins" do
        Ohai.config[:plugin_path] = [ path_to(".") ]
        ohai.all_plugins
        expect(ohai.data[:zoo]).to eq("animals")
        expect(ohai.data[:park]).to eq("plants")
      end

      describe "when using :disabled_plugins" do
        before do
          Ohai.config[:disabled_plugins] = [ "zoo" ]
        end

        after do
          Ohai.config[:disabled_plugins] = [ ]
        end

        it "shouldn't run disabled version 6 plugins" do
          Ohai.config[:plugin_path] = [ path_to(".") ]
          ohai.all_plugins
          expect(ohai.data[:zoo]).to be_nil
          expect(ohai.data[:park]).to eq("plants")
        end
      end

      describe "when running in whitelist mode" do
        let(:ohai_system) { Ohai::System.new }

        let(:primary_plugin_class) do
          Ohai.plugin(:Primary) do
            provides "primary"
            depends "dependency/one"
            depends "dependency/two"
            collect_data {}
          end
        end

        let(:dependency_plugin_one_class) do
          Ohai.plugin(:DependencyOne) do
            provides "dependency/one"
            collect_data {}
          end
        end

        let(:dependency_plugin_two_class) do
          Ohai.plugin(:DependencyTwo) do
            provides "dependency/two"
            collect_data {}
          end
        end

        let(:unrelated_plugin_class) do
          Ohai.plugin(:Unrelated) do
            provides "whatever"
            collect_data {}
          end
        end

        let(:v6_plugin_class) do
          Class.new(Ohai::DSL::Plugin::VersionVI) { collect_contents("v6_key('v6_data')") }
        end

        let(:primary_plugin) { primary_plugin_class.new(ohai_system) }
        let(:dependency_plugin_one) { dependency_plugin_one_class.new(ohai_system) }
        let(:dependency_plugin_two) { dependency_plugin_two_class.new(ohai_system) }
        let(:unrelated_plugin) { unrelated_plugin_class.new(ohai_system) }
        let(:v6_plugin) { v6_plugin_class.new(ohai_system, "/v6_plugin.rb", "/") }

        before do
          allow(ohai_system).to receive(:load_plugins) # TODO: temporary hack - don't run unrelated plugins...
          [ primary_plugin, dependency_plugin_one, dependency_plugin_two, unrelated_plugin].each do |plugin|
            plugin_provides = plugin.class.provides_attrs
            ohai_system.provides_map.set_providers_for(plugin, plugin_provides)
          end

          ohai_system.v6_dependency_solver["v6_plugin"] = v6_plugin

          # Instead of calling all plugins we call load and run directly so that the information we setup is not cleared by all_plugins
          ohai_system.load_plugins
          ohai_system.run_plugins(true, "primary")
        end

        # This behavior choice is somewhat arbitrary, based on what creates the
        # least code complexity in legacy v6 plugin format support. Once we
        # ship 7.0, though, we need to stick to the same behavior.
        it "runs v6 plugins" do
          expect(v6_plugin.has_run?).to be true
        end

        it "runs plugins that provide the requested attributes" do
          expect(primary_plugin.has_run?).to be true
        end

        it "runs dependencies of plugins that provide requested attributes" do
          expect(dependency_plugin_one.has_run?).to be true
          expect(dependency_plugin_two.has_run?).to be true
        end

        it "does not run plugins that are irrelevant to the requested attributes" do
          expect(unrelated_plugin.has_run?).to be false
        end

      end
    end

    when_plugins_directory "contains a v7 plugins with :default and platform specific blocks" do
      with_plugin("message.rb", <<EOF)
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

      it "should collect platform specific" do
        Ohai.config[:plugin_path] = [ path_to(".") ]
        ohai.all_plugins
        expect(ohai.data[:message]).to eq("platform_specific_message")
      end
    end

    when_plugins_directory "contains v7 plugins only" do
      with_plugin("zoo.rb", <<EOF)
Ohai.plugin(:Zoo) do
  provides 'zoo'

  collect_data(:default) do
    zoo("animals")
  end
end
EOF

      with_plugin("park.rb", <<EOF)
Ohai.plugin(:Park) do
  provides 'park'
  collect_data(:default) do
    park("plants")
  end
end
EOF

      it "should collect data from all the plugins" do
        Ohai.config[:plugin_path] = [ path_to(".") ]
        ohai.all_plugins
        expect(ohai.data[:zoo]).to eq("animals")
        expect(ohai.data[:park]).to eq("plants")
      end

      it "should write an error to Ohai::Log" do
        Ohai.config[:plugin_path] = [ path_to(".") ]
        # Make sure the stubbing of runner is not overriden with reset_system during test
        allow(ohai).to receive(:reset_system)
        allow(ohai.instance_variable_get("@runner")).to receive(:run_plugin).and_raise(Ohai::Exceptions::AttributeNotFound)
        expect(Ohai::Log).to receive(:error).with(/Encountered error while running plugins/)
        expect { ohai.all_plugins }.to raise_error(Ohai::Exceptions::AttributeNotFound)
      end

      describe "when using :disabled_plugins" do
        before do
          Ohai.config[:disabled_plugins] = [ :Zoo ]
        end

        after do
          Ohai.config[:disabled_plugins] = [ ]
        end

        it "shouldn't run disabled plugins" do
          Ohai.config[:plugin_path] = [ path_to(".") ]
          ohai.all_plugins
          expect(ohai.data[:zoo]).to be_nil
          expect(ohai.data[:park]).to eq("plants")
        end
      end
    end

    when_plugins_directory "contains v6 & v7 plugins in different directories" do
      with_plugin("my_plugins/zoo.rb", <<EOF)
Ohai.plugin(:Zoo) do
  provides 'zoo'

  collect_data(:default) do
    zoo("animals")
  end
end
EOF

      with_plugin("my_plugins/nature.rb", <<EOF)
Ohai.plugin(:Nature) do
  provides 'nature'

  collect_data(:default) do
    nature("cougars")
  end
end
EOF

      with_plugin("my_plugins/park.rb", <<EOF)
provides 'park'
park("plants")
EOF

      with_plugin("my_plugins/home.rb", <<EOF)
provides 'home'
home("dog")
EOF

      describe "when using :disabled_plugins" do
        before do
          Ohai.config[:disabled_plugins] = [ :Zoo, 'my_plugins::park' ]
        end

        after do
          Ohai.config[:disabled_plugins] = [ ]
        end

        it "shouldn't run disabled plugins" do
          Ohai.config[:plugin_path] = [ path_to(".") ]
          ohai.all_plugins
          expect(ohai.data[:zoo]).to be_nil
          expect(ohai.data[:nature]).to eq("cougars")
          expect(ohai.data[:park]).to be_nil
          expect(ohai.data[:home]).to eq("dog")
        end
      end
    end

    when_plugins_directory "contains v6 plugins that depend on v7 plugins" do
      with_plugin("messages.rb", <<EOF)
require_plugin 'v6message'
require_plugin 'v7message'

provides 'messages'

messages Mash.new
messages[:v6message] = v6message
messages[:v7message] = v7message
EOF

      with_plugin("v6message.rb", <<EOF)
provides 'v6message'
v6message "update me!"
EOF

      with_plugin("v7message.rb", <<EOF)
Ohai.plugin(:V7message) do
  provides 'v7message'

  collect_data(:default) do
    v7message "v7 plugins are awesome!"
  end
end
EOF

      before do
        Ohai.config[:plugin_path] = [ path_to(".") ]
      end

      it "should collect all data" do
        ohai.all_plugins
        [:v6message, :v7message, :messages].each do |attribute|
          expect(ohai.data).to have_key(attribute)
        end

        expect(ohai.data[:v6message]).to eql("update me!")
        expect(ohai.data[:v7message]).to eql("v7 plugins are awesome!")
        [:v6message, :v7message].each do |subattr|
          expect(ohai.data[:messages]).to have_key(subattr)
          expect(ohai.data[:messages][subattr]).to eql(ohai.data[subattr])
        end
      end
    end
  end

  describe "require_plugin()" do
    when_plugins_directory "contains v6 and v7 plugin with the same name" do
      with_plugin("message.rb", <<EOF)
provides 'message'

message "From Version 6"
EOF

      with_plugin("v7/message.rb", <<EOF)
Ohai.plugin(:Message) do
  provides 'message'

  collect_data(:default) do
    message "From Version 7"
  end
end
EOF

      before do
        Ohai.config[:plugin_path] = [ path_to(".") ]
      end

      it "version 6 should run" do
        ohai.load_plugins
        ohai.require_plugin("message")
        expect(ohai.data[:message]).to eql("From Version 6")
      end
    end

    when_plugins_directory "a v6 plugin that requires a v7 plugin with dependencies" do
      with_plugin("message.rb", <<EOF)
provides 'message'

require_plugin 'v7message'

message Mash.new
message[:v6message] = "Hellos from 6"
message[:copy_message] = v7message
EOF

      with_plugin("v7message.rb", <<EOF)
Ohai.plugin(:V7message) do
  provides 'v7message'
  depends 'zoo'

  collect_data(:default) do
    v7message ("Hellos from 7: " + zoo)
  end
end
EOF

      with_plugin("zoo.rb", <<EOF)
Ohai.plugin(:Zoo) do
  provides 'zoo'

  collect_data(:default) do
    zoo "animals"
  end
end
EOF

      before do
        Ohai.config[:plugin_path] = [ path_to(".") ]
      end

      it "should collect all the data properly" do
        ohai.all_plugins
        expect(ohai.data[:v7message]).to eq("Hellos from 7: animals")
        expect(ohai.data[:zoo]).to eq("animals")
        expect(ohai.data[:message][:v6message]).to eq("Hellos from 6")
        expect(ohai.data[:message][:copy_message]).to eq("Hellos from 7: animals")
      end
    end

    when_plugins_directory "a v6 plugin that requires non-existing v7 plugin" do
      with_plugin("message.rb", <<EOF)
provides 'message'

require_plugin 'v7message'

message v7message
EOF

      before do
        Ohai.config[:plugin_path] = [ path_to(".") ]
      end

      it "should raise DependencyNotFound" do
        expect { ohai.all_plugins }.to raise_error(Ohai::Exceptions::DependencyNotFound)
      end
    end
  end

  describe "when Chef OHAI resource executes :reload action" do

    when_plugins_directory "contains a v6 plugin" do
      with_plugin("a_v6plugin.rb", <<-E)
        plugin_data Mash.new
        plugin_data[:foo] = :bar
      E

      before do
        Ohai.config[:plugin_path] = [ path_to(".") ]
      end

      it "reloads only the v6 plugin when given a specific plugin to load" do
        ohai.all_plugins
        expect { ohai.all_plugins("a_v6plugin") }.not_to raise_error
      end

    end

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

      it "should rerun the plugin providing the desired attributes" do
        ohai.all_plugins
        initial_value = ohai.data["random"]
        ohai.all_plugins
        updated_value = ohai.data["random"]
        expect(initial_value).not_to eq(updated_value)
      end

    end
  end

  describe "when refreshing plugins" do
    when_plugins_directory "contains v7 plugins" do
      with_plugin("desired.rb", <<-E)
        Ohai.plugin(:DesiredPlugin) do
          provides 'desired_attr'
          depends 'depended_attr'

          collect_data do
            desired_attr "hello"
            self[:desired_attr_count] ||= 0
            self[:desired_attr_count] += 1
          end
        end
      E

      with_plugin("depended.rb", <<-E)
        Ohai.plugin(:DependedPlugin) do
          provides 'depended_attr'

          collect_data do
            depended_attr "hello"
            self[:depended_attr_count] ||= 0
            self[:depended_attr_count] += 1
          end
        end
      E

      with_plugin("other.rb", <<-E)
        Ohai.plugin(:OtherPlugin) do
          provides 'other_attr'

          collect_data do
            other_attr "hello"
            self[:other_attr_count] ||= 0
            self[:other_attr_count] += 1
          end
        end
      E

      before do
        Ohai.config[:plugin_path] = [ path_to(".") ]
        Ohai::Log.init(STDOUT)
        Ohai::Log.level = :debug
        ohai.all_plugins
      end

      it "should rerun the plugin providing the desired attributes" do
        expect(ohai.data[:desired_attr_count]).to eq(1)
        ohai.refresh_plugins("desired_attr")
        expect(ohai.data[:desired_attr_count]).to eq(2)
      end

      it "should not re-run dependencies of the plugin providing the desired attributes" do
        expect(ohai.data[:depended_attr_count]).to eq(1)
        ohai.refresh_plugins("desired_attr")
        expect(ohai.data[:depended_attr_count]).to eq(1)
      end

      it "should not re-run plugins unrelated to the plugin providing the desired attributes" do
        expect(ohai.data[:other_attr_count]).to eq(1)
        ohai.refresh_plugins("desired_attr")
        expect(ohai.data[:other_attr_count]).to eq(1)
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

      it "should run all the plugins when a top level attribute is specified" do
        ohai.all_plugins("languages")
        expect(ohai.data[:languages][:english][:version]).to eq(2014)
        expect(ohai.data[:languages][:french][:version]).to eq(2012)
      end

      it "should run the first parent when a non-existent child is specified" do
        ohai.all_plugins("languages/english/version")
        expect(ohai.data[:languages][:english][:version]).to eq(2014)
        expect(ohai.data[:languages][:french]).to be_nil
      end

      it "should be able to run multiple plugins" do
        ohai.all_plugins(["languages/english", "languages/french"])
        expect(ohai.data[:languages][:english][:version]).to eq(2014)
        expect(ohai.data[:languages][:french][:version]).to eq(2012)
      end

    end
  end

end
