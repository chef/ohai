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

describe "Ohai::System" do
  extend IntegrationSupport

  describe "#initialize" do
    before(:each) do
      @ohai = Ohai::System.new
    end

    it "should return an Ohai::System object" do
      @ohai.should be_a_kind_of(Ohai::System)
    end

    it "should set @attributes to a ProvidesMap" do
      @ohai.provides_map.should be_a_kind_of(Ohai::ProvidesMap)
    end

    it "should set @v6_dependency_solver to a Hash" do
      @ohai.v6_dependency_solver.should be_a_kind_of(Hash)
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
      @ohai = Ohai::System.new
      @original_config = Ohai::Config[:plugin_path]
      Ohai::Config[:plugin_path] = [ path_to(".") ]
    end

    it "load_plugins() should load all the plugins" do
      @ohai.load_plugins
      @ohai.provides_map.map.keys.should include("seals")
      @ohai.v6_dependency_solver.keys.should include("lake")
      Ohai::NamedPlugin.const_get(:Zoo).should == Ohai::NamedPlugin::Zoo
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
      @ohai = Ohai::System.new
      @original_config = Ohai::Config[:plugin_path]
      Ohai::Config[:plugin_path] = [ path_to("repo1"), path_to("repo2") ]
    end

    after do
      Ohai::Config[:plugin_path] = @original_config
    end

    it "load_plugins() should load all the plugins" do
      @ohai.load_plugins
      @ohai.provides_map.map.keys.should include("seals")
      @ohai.provides_map.map.keys.should include("crabs")
      @ohai.v6_dependency_solver.keys.should include("lake")
      @ohai.v6_dependency_solver.keys.should include("mountain")
      Ohai::NamedPlugin.const_get(:Zoo).should == Ohai::NamedPlugin::Zoo
      Ohai::NamedPlugin.const_get(:Nature).should == Ohai::NamedPlugin::Nature
    end
  end

  describe "#run_plugins" do
    describe "with v6 plugins only" do
      before(:each) do
        @ohai = Ohai::System.new

        @plugins = []
        @names = ['one', 'two', 'three', 'four', 'five']
        @names.each do |name|
          k = Class.new(Ohai::DSL::Plugin::VersionVI) {
            collect_contents("")
          }
          p = k.new(@ohai, "some/plugin/path.rb")
          @ohai.v6_dependency_solver[name] = p
          @plugins << p
        end

        @ohai.stub(:collect_plugins).and_return([])
      end

      after(:each) do
        @ohai.v6_dependency_solver.clear
      end

      it "should run all version 6 plugins" do
        @ohai.run_plugins(true)
        @plugins.each do |plugin|
          plugin.has_run?.should be_true
        end
      end

      it "should force plugins to run again if force is set to true" do
        @plugins.each do |plugin|
          plugin.stub(:has_run?).and_return(:true)
          plugin.should_receive(:safe_run)
        end

        @ohai.run_plugins(true, true)
      end
    end

    describe "with v7 plugins only" do
      describe "when handling an error" do
        before(:each) do
          @runner = double('@runner')
          Ohai::Runner.stub(:new) { @runner }

          @ohai = Ohai::System.new
          klass = Ohai.plugin(:Empty) { }
          plugin = klass.new(@ohai.data)
          @ohai.provides_map.should_receive(:all_plugins).and_return([plugin])
        end

        describe "when AttributeNotFound is received" do
          it "should write an error to Ohai::Log" do
            @runner.stub(:run_plugin).and_raise(Ohai::Exceptions::AttributeNotFound)
            Ohai::Log.should_receive(:error).with(/Ohai::Exceptions::AttributeNotFound/)
            expect { @ohai.run_plugins }.to raise_error(Ohai::Exceptions::AttributeNotFound)
          end
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
        let(:v6_plugin) { v6_plugin_class.new(ohai_system, "/v6_plugin.rb") }

        before do
          ohai_system.stub(:load_plugins) # TODO: temporary hack - don't run unrelated plugins...
          [ primary_plugin, dependency_plugin_one, dependency_plugin_two, unrelated_plugin].each do |plugin|
            plugin_provides = plugin.class.provides_attrs
            ohai_system.provides_map.set_providers_for(plugin, plugin_provides)
          end

          ohai_system.v6_dependency_solver["v6_plugin"] = v6_plugin

          ohai_system.all_plugins("primary")
        end

        # This behavior choice is somewhat arbitrary, based on what creates the
        # least code complexity in legacy v6 plugin format support. Once we
        # ship 7.0, though, we need to stick to the same behavior.
        it "runs v6 plugins" do
          expect(v6_plugin.has_run?).to be_true
        end

        it "runs plugins that provide the requested attributes" do
          expect(primary_plugin.has_run?).to be_true
        end

        it "runs dependencies of plugins that provide requested attributes" do
          expect(dependency_plugin_one.has_run?).to be_true
          expect(dependency_plugin_two.has_run?).to be_true
        end

        it "does not run plugins that are irrelevant to the requested attributes" do
          expect(unrelated_plugin.has_run?).to be_false
        end

      end
    end

    describe "when running all loaded plugins" do
      before(:each) do
        @runner = double('@runner')
        Ohai::Runner.stub(:new) { @runner }

        @ohai = Ohai::System.new

        @names = [:One, :Two, :Three, :Four, :Five]

        klasses = []
        @names.each do |name|
          klasses << Ohai.plugin(name) {
            provides("itself")
            collect_data {
              itself("me")
            }
          }
        end

        @plugins = []
        klasses.each do |klass|
          @plugins << klass.new(@ohai.data)
        end

        @ohai.provides_map.should_receive(:all_plugins).and_return(@plugins)
      end

      it "should run each plugin once from Ohai::System" do
        @plugins.each do |plugin|
          @runner.should_receive(:run_plugin).with(plugin, false)
        end
        @ohai.run_plugins
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
    puts "I'm running now."
    v7message "v7 plugins are awesome!"
  end
end
EOF

      before do
        @ohai = Ohai::System.new
        @original_config = Ohai::Config[:plugin_path]
        Ohai::Config[:plugin_path] = [ path_to(".") ]
      end

      after do
         Ohai::Config[:plugin_path] = @original_config
      end

      it "should collect all data" do
        pending("Requires some changes to require_plugin() which will be changed in a seperate PR as a next step.")
        @ohai.all_plugins
        [:v6message, :v7message, :messages].each do |attribute|
          @ohai.data.should have_key(attribute)
        end

        @ohai.data[:v6message].should eql("update me!")
        @ohai.data[:v7message].should eql("v7 plugins are awesome!")
        [:v6message, :v7message].each do |subattr|
          @ohai.data[:messages].should have_key(subattr)
          @ohai.data[:messages][subattr].should eql(@ohai.data[subattr])
        end
      end
    end
  end

  describe "#collect_plugins" do
    before(:each) do
      @ohai = Ohai::System.new

      @names = [:Zero, :One, :Two, :Three]
      @plugins = []
      @names.each do |name|
        k = Ohai.plugin(name) { }
        @plugins << k.new(@ohai.data)
      end
    end

    it "should find all the plugins providing attributes" do
      provides_map = @ohai.provides_map
      provides_map.set_providers_for(@plugins[0], ["zero"])
      provides_map.set_providers_for(@plugins[1], ["one"])
      provides_map.set_providers_for(@plugins[2], ["two"])
      provides_map.set_providers_for(@plugins[3], ["stub/three"])

      providers = provides_map.all_plugins
      providers.size.should eql(@plugins.size)
      @plugins.each do |plugin|
        providers.include?(plugin).should be_true
      end
    end
  end

  describe "#require_plugin" do
    before(:each) do
      @plugin_path = Ohai::Config[:plugin_path]
      Ohai::Config[:plugin_path] = ["/tmp/plugins"]

      @ohai = Ohai::System.new
      klass = Class.new(Ohai::DSL::Plugin::VersionVI) { }
      @plugin = klass.new(@ohai, "some/plugin/path.rb")

      @ohai.stub(:plugin_for).with("empty").and_return(@plugin)
    end

    it "should immediately return if force is false and the plugin has already run" do
      @ohai.v6_dependency_solver['empty'] = @plugin
      @plugin.stub(:has_run?).and_return(true)

      @ohai.should_not_receive(:plugin_for).with("empty")
      @ohai.require_plugin("empty", true).should be_true
    end

    context "when a plugin is disabled" do
      before(:each) do
        Ohai::Config[:disabled_plugins] = ["empty"]
      end

      it "should not run the plugin" do
        Ohai::Log.should_receive(:debug).with(/Skipping disabled plugin/)
        @ohai.should_not_receive(:plugin_for).with("empty")
        @ohai.require_plugin("empty").should be_false
      end

      it "should not run the plugin even if force is true" do
        Ohai::Log.should_receive(:debug).with(/Skipping disabled plugin/)
        @ohai.should_not_receive(:plugin_for).with("empty")
        @ohai.require_plugin("empty", true).should be_false
      end
    end

    it "should check for the plugin in v6_dependency_solver first" do
      @ohai.v6_dependency_solver['empty'] = @plugin
      @ohai.should_not_receive(:plugin_for).with("empty")
      @plugin.stub(:safe_run).and_return(true)
      @ohai.require_plugin("empty").should be_true
    end

    it "should load the plugin if not already loaded" do
      @ohai.stub(:plugin_for).with("empty").and_return(@plugin)
      @ohai.should_receive(:plugin_for).with("empty")
      @plugin.stub(:safe_run).and_return(true)
      @ohai.require_plugin("empty").should be_true
    end

    it "should run the plugin if the plugin has not yet run" do
      @ohai.stub(:plugin_for).with("empty").and_return(@plugin)
      @plugin.stub(:safe_run).and_return(true)
      @ohai.require_plugin("empty").should be_true
    end

    it "should log a message to debug if a plugin cannot be found" do
      @ohai.stub(:plugin_for).with("fake").and_return(nil)
      Ohai::Log.should_receive(:debug).with(/No fake found in/)
      @ohai.require_plugin("fake")
    end

    context "when a v6 plugin requires a v7 plugin" do
      before(:each) do
        v6string = <<EOF
provides 'v6attr'
require_plugin 'v7plugin'
v6attr message
EOF
        v6klass = Class.new(Ohai::DSL::Plugin::VersionVI) { collect_contents(v6string) }
        v7klass = Ohai.plugin(:V7plugin) {
          provides("message")
          collect_data { message("hey.") }
        }
        @v6plugin = v6klass.new(@ohai, "some/plugin/path.rb")
        @v7plugin = v7klass.new(@ohai.data)

        @ohai.v6_dependency_solver['v6plugin'] = @v6plugin
        @ohai.v6_dependency_solver['v7plugin'] = @v7plugin
        @ohai.provides_map.set_providers_for(@v7plugin, ["message"])
      end

      it "should run the plugin it requires" do
        @ohai.require_plugin('v6plugin')
        @v7plugin.has_run?.should be_true
        @v6plugin.has_run?.should be_true
      end

      it "should be able to access the data set by the v7 plugin" do
        @ohai.require_plugin('v6plugin')
        @ohai.data.should have_key(:message)
        @ohai.data[:message].should eql("hey.")
        @ohai.data.should have_key(:v6attr)
        @ohai.data[:v6attr].should eql("hey.")
      end
    end

    context "when a v6 plugin requires a v7 plugin with dependencies" do
      before(:each) do
        v6string = <<EOF
provides 'v6attr'
require_plugin 'v7plugin'
v6attr message
EOF
        v6klass = Class.new(Ohai::DSL::Plugin::VersionVI) { collect_contents(v6string) }
        v7klass = Ohai.plugin(:V7plugin) {
          provides("message")
          depends("other")
          collect_data{ message(other) }
        }
        otherklass = Ohai.plugin(:Other) {
          provides("other")
          collect_data{ other("o hai") }
        }

        @v6plugin = v6klass.new(@ohai, "some/plugin/path.rb")
        @v7plugin = v7klass.new(@ohai.data)
        @other = otherklass.new(@ohai.data)

        vds = @ohai.v6_dependency_solver
        vds['v6plugin'] = @v6plugin
        vds['v7plugin'] = @v7plugin
        vds['other'] = @other

        dependency_map = @ohai.provides_map
        #dependency_map[:message][:_plugins] = [@v7plugin]
        dependency_map.set_providers_for(@v7plugin, ["message"])
        #dependency_map[:other][:_plugins] = [@other]
        dependency_map.set_providers_for(@other, ["other"])
      end

      it "should resolve the v7 plugin dependencies" do
        @ohai.require_plugin('v6plugin')
        [@v6plugin, @v7plugin, @other].each do |plugin|
          plugin.has_run?.should be_true
        end
      end

      it "should set all collected data properly" do
        @ohai.require_plugin('v6plugin')
        d = @ohai.data
        d.should have_key(:other)
        d.should have_key(:message)
        d.should have_key(:v6attr)
        [:other, :message, :v6attr].each do |attr|
          d[attr].should eql("o hai")
        end
      end
    end
  end

  describe "#plugin_for" do
    before(:each) do
      Ohai::Config[:plugin_path] = ["/tmp/plugins"]

      @loader = double('@loader')
      Ohai::Loader.stub(:new) { @loader }

      @ohai = Ohai::System.new
      @klass = Class.new(Ohai::DSL::Plugin::VersionVI) { }
    end

    it "should find a plugin with a simple name" do
      plugin = @klass.new(@ohai, "/tmp/plugins/empty.rb")
      File.stub(:join).with("/tmp/plugins", "empty.rb").and_return("/tmp/plugins/empty.rb")
      File.stub(:expand_path).with("/tmp/plugins/empty.rb").and_return("/tmp/plugins/empty.rb")
      File.stub(:exist?).with("/tmp/plugins/empty.rb").and_return(true)
      @loader.stub(:load_plugin).with("/tmp/plugins/empty.rb").and_return(plugin)

      found_plugin = @ohai.plugin_for("empty")
      found_plugin.should eql(plugin)
    end

    it "should find a plugin with a complex name" do
      plugin = @klass.new(@ohai, "/tmp/plugins/empty.rb")
      File.stub(:join).with("/tmp/plugins", "ubuntu/empty.rb").and_return("/tmp/plugins/ubuntu/empty.rb")
      File.stub(:expand_path).with("/tmp/plugins/ubuntu/empty.rb").and_return("/tmp/plugins/ubuntu/empty.rb")
      File.stub(:exist?).with("/tmp/plugins/ubuntu/empty.rb").and_return(true)
      @loader.stub(:load_plugin).with("/tmp/plugins/ubuntu/empty.rb").and_return(plugin)

      found_plugin = @ohai.plugin_for("ubuntu::empty")
      found_plugin.should eql(plugin)
    end

    it "should return nil if a plugin is not found" do
      File.stub(:join).with("/tmp/plugins", "fake.rb").and_return("/tmp/plugins/fake.rb")
      File.stub(:expand_path).with("/tmp/plugins/fake.rb").and_return("/tmp/plugins/fake.rb")
      File.should_receive(:exist?).with("/tmp/plugins/fake.rb").and_return(false)

      @ohai.plugin_for("fake").should be_nil
    end

    it "should add the plugin to the v6_dependency_solver" do
      plugin = @klass.new(@ohai, "/tmp/plugins/empty.rb")
      File.stub(:join).with("/tmp/plugins", "empty.rb").and_return("/tmp/plugins/empty.rb")
      File.stub(:expand_path).with("/tmp/plugins/empty.rb").and_return("/tmp/plugins/empty.rb")
      File.stub(:exist?).with("/tmp/plugins/empty.rb").and_return(true)
      @loader.stub(:load_plugin).with("/tmp/plugins/empty.rb").and_return(plugin)

      @ohai.plugin_for("empty")
      @ohai.v6_dependency_solver.should have_key('empty')
      @ohai.v6_dependency_solver['empty'].should eql(plugin)
    end
  end
end
