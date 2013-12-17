#
# Author:: Claire McQuin (<claire@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License. You may
# obtain a copy of the license at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either expressed or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Ohai::Runner, "run_plugin" do
  let(:safe_run) { true }

  before(:each) do
    @ohai = Ohai::System.new
    @runner = Ohai::Runner.new(@ohai, safe_run)
  end

  describe "when running an invalid plugin" do
    it "should raise error" do
      lambda { @runner.run_plugin(double("Ohai::NotPlugin")) }.should raise_error(ArgumentError)
    end
  end

  describe "when running a plugin" do
    let(:plugin) { double("Ohai::DSL::Plugin", :kind_of? => true, :version => version, :name => "Test", :has_run? => has_run, :dependencies => [ ]) }
    let(:version) { :version7 }
    let(:has_run) { false }

    describe "version 7" do
      it "should call run_v7_plugin" do
        @runner.should_receive(:run_v7_plugin)
        @runner.run_plugin(plugin)
      end

      describe "if the plugin has run before" do
        let(:has_run) { true }

        it "plugin should not run when run_plugin is not forced" do
          plugin.should_not_receive(:safe_run)
          @runner.run_plugin(plugin)
        end

        it "plugin should run when run_plugin is not forced" do
          plugin.should_receive(:safe_run)
          @runner.run_plugin(plugin, true)
        end

        describe "if the plugin is disabled" do
          it "should not run the plugin" do
            Ohai::Config.should_receive(:[]).with(:disabled_plugins).and_return(["Test"])
            @runner.should_not_receive(:run_v7_plugin)
            @runner.run_plugin(plugin)
          end
        end
      end
    end

    describe "version 6" do
      let(:version) { :version6 }

      it "should call run_v6_plugin" do
        @runner.should_receive(:run_v6_plugin)
        @runner.run_plugin(plugin)
      end

      describe "if the plugin has not run before" do
        describe "if safe_run is not set" do
          it "safe_run should be called" do
            plugin.should_receive(:safe_run)
            @runner.run_plugin(plugin)
          end
        end

        describe "if safe_run is set" do
          let(:safe_run) { false }

          it "run should be called" do
            plugin.should_receive(:run)
            @runner.run_plugin(plugin)
          end
        end
      end

      describe "if the plugin has run before" do
        let(:has_run) { true }

        it "plugin should not run when run_plugin is not forced" do
          plugin.should_not_receive(:safe_run)
          @runner.run_plugin(plugin)
        end

        it "plugin should run when run_plugin is not forced" do
          plugin.should_receive(:safe_run)
          @runner.run_plugin(plugin, true)
        end
      end

      describe "if the plugin is disabled" do
        it "should not run the plugin" do
          Ohai::Config.should_receive(:[]).with(:disabled_plugins).and_return(["Test"])
          @runner.should_not_receive(:run_v7_plugin)
            @runner.run_plugin(plugin)
        end
      end
    end

    describe "invalid version" do
      let(:version) { :versionBla }

      it "should raise error" do
        lambda { @runner.run_plugin(plugin) }.should raise_error(ArgumentError)
      end
    end

    describe "when plugin is disabled" do
      before do
        Ohai::Config.should_receive(:[]).with(:disabled_plugins).and_return(["Test"])
      end

      it "should not run the plugin" do
        @runner.should_not_receive(:run_v7_plugin)
        @runner.run_plugin(plugin)
      end
    end
  end

  describe "when running a plugin with no dependencies, Ohai::Runner" do
    let(:plugin) {
      klass = Ohai.plugin(:Test) {
        provides("thing")
        collect_data {
          thing(Mash.new)
        }
      }
      klass.new(@ohai.data)
    }

    it "should run the plugin" do
      @runner.run_plugin(plugin)
      plugin.has_run?.should be_true
    end

    it "should add plugin data to Ohai::System.data" do
      @runner.run_plugin(plugin)
      @ohai.data.should have_key(:thing)
      @ohai.data[:thing].should eql({})
    end
  end

  describe "when running a plugin with one dependency" do
    describe "when the dependency does not exist" do
      before(:each) do
        klass = Ohai.plugin(:Test) {
          provides("thing")
          depends("other_thing")
          collect_data {
            thing(other_thing)
          }
        }
        @plugin = klass.new(@ohai.data)
      end

      it "should raise Ohai::Excpetions::AttributeNotFound" do
        expect { @runner.run_plugin(@plugin) }.to raise_error(Ohai::Exceptions::AttributeNotFound)
      end

      it "should not run the plugin" do
        expect { @runner.run_plugin(@plugin) }.to raise_error(Ohai::Exceptions::AttributeNotFound)
        @plugin.has_run?.should be_false
      end
    end

    describe "when the dependency has a single provider" do
      before(:each) do
        klass1 = Ohai.plugin(:Thing) {
          provides("thing")
          collect_data {
            thing("thang")
          }
        }
        klass2 = Ohai.plugin(:Other) {
          provides("other")
          depends("thing")
          collect_data {
            other(thing)
          }
        }

        @plugins = []
        [klass1, klass2].each do |klass|
          @plugins << klass.new(@ohai.data)
        end
        @plugin1, @plugin2 = @plugins

        @ohai.provides_map.set_providers_for(@plugin1, ["thing"])
      end

      it "should run the plugins" do
        @runner.run_plugin(@plugin2)
        @plugins.each do |plugin|
          plugin.has_run?.should be_true
        end
      end
    end

    describe "when the dependency has multiple providers" do
      before(:each) do
        klass1 = Ohai.plugin(:Thing) {
          provides("thing")
          collect_data {
            thing(Mash.new)
          }
        }
        klass2 = Ohai.plugin(:Other) {
          provides("other")
          depends("thing")
          collect_data {
            other(thing)
          }
        }

        @plugins = []
        [klass1, klass1, klass2].each do |klass|
          @plugins << klass.new(@ohai.data)
        end
        @plugin1, @plugin2, @plugin3 = @plugins

        @ohai.provides_map.set_providers_for(@plugin1, ["thing"])
        @ohai.provides_map.set_providers_for(@plugin2, ["thing"])
      end

      it "should run the plugins" do
        @runner.run_plugin(@plugin3)
        @plugins.each do |plugin|
          plugin.has_run?.should be_true
        end
      end
    end
  end

  describe "when running a plugin with many dependencies" do
    before(:each) do
      @ohai = Ohai::System.new
      @runner = Ohai::Runner.new(@ohai, true)

      klass1 = Ohai.plugin(:One) {
        provides("one")
        collect_data {
          one(1)
        }
      }
      klass2 = Ohai.plugin(:Two) {
        provides("two")
        collect_data {
          two(2)
        }
      }
      klass3 = Ohai.plugin(:Three) {
        provides("three")
        depends("one", "two")
        collect_data {
          three(3)
        }
      }

      @plugins = []
      [klass1, klass2, klass3].each do |klass|
        @plugins << klass.new(@ohai.data)
      end
      @plugin1, @plugin2, @plugin3 = @plugins
      @ohai.provides_map.set_providers_for(@plugin1, ["one", "two"])
      @ohai.provides_map.set_providers_for(@plugin2, ["one", "two"])
    end

    it "should run the plugins" do
      @runner.run_plugin(@plugin3)
      @plugins.each do |plugin|
        plugin.has_run?.should be_true
      end
    end
  end

  describe "when a cycle is detected" do
    before(:each) do
      @ohai = Ohai::System.new
      @runner = Ohai::Runner.new(@ohai, true)

      klass1 = Ohai.plugin(:Thing) {
        provides("thing")
        depends("other")
        collect_data {
          thing(other)
        }
      }
      klass2 = Ohai.plugin(:Other) {
        provides("other")
        depends("thing")
        collect_data {
          other(thing)
        }
      }

      @plugins = []
      [klass1, klass2].each_with_index do |klass, idx|
        @plugins << klass.new(@ohai.data)
      end
      @plugin1, @plugin2 = @plugins
    end

    it "should raise Ohai::Exceptions::DependencyCycle" do
      @runner.stub(:fetch_plugins).with(["thing"]).and_return([@plugin1])
      @runner.stub(:fetch_plugins).with(["other"]).and_return([@plugin2])
      expect { @runner.run_plugin(@plugin1) }.to raise_error(Ohai::Exceptions::DependencyCycle)
    end
  end

  describe "when A depends on B and C, and B depends on C" do
    before(:each) do
      @ohai = Ohai::System.new
      @runner = Ohai::Runner.new(@ohai, true)

      klassA = Ohai.plugin(:A) {
        provides("A")
        depends("B", "C")
        collect_data { }
      }
      klassB = Ohai.plugin(:B) {
        provides("B")
        depends("C")
        collect_data { }
      }
      klassC = Ohai.plugin(:C) {
        provides("C")
        collect_data { }
      }

      @plugins = []
      [klassA, klassB, klassC].each do |klass|
        @plugins << klass.new(@ohai.data)
      end
      @pluginA, @pluginB, @pluginC = @plugins
    end

    it "should not detect a cycle when B is the first provider returned" do
      @ohai.provides_map.set_providers_for(@pluginA, ["A"])
      @ohai.provides_map.set_providers_for(@pluginB, ["B"])
      @ohai.provides_map.set_providers_for(@pluginC, ["C"])

      Ohai::Log.should_not_receive(:error).with(/DependencyCycleError/)
      @runner.run_plugin(@pluginA)

      @plugins.each do |plugin|
        plugin.has_run?.should be_true
      end
    end

    it "should not detect a cycle when C is the first provider returned" do
      @ohai.provides_map.set_providers_for(@pluginA, ["A"])
      @ohai.provides_map.set_providers_for(@pluginC, ["C"])
      @ohai.provides_map.set_providers_for(@pluginB, ["B"])

      Ohai::Log.should_not_receive(:error).with(/DependencyCycleError/)
      @runner.run_plugin(@pluginA)

      @plugins.each do |plugin|
        plugin.has_run?.should be_true
      end
    end
  end
end

describe Ohai::Runner, "fetch_plugins" do
  before(:each) do
    @ohai = Ohai::System.new
    @runner = Ohai::Runner.new(@ohai, true)
  end

  it "should collect the provider" do
    plugin = Ohai::DSL::Plugin.new(@ohai.data)
    @ohai.provides_map.set_providers_for(plugin, ["top/middle/bottom"])

    dependency_providers = @runner.fetch_plugins(["top/middle/bottom"])
    dependency_providers.should eql([plugin])
  end
end

describe Ohai::Runner, "#get_cycle" do
  before(:each) do
    @ohai = Ohai::System.new
    @runner = Ohai::Runner.new(@ohai, true)

    klass1 = Ohai.plugin(:One) {
      provides("one")
      depends("two")
      collect_data {
        one(two)
      }
    }
    klass2 = Ohai.plugin(:Two) {
      provides("two")
      depends("one")
      collect_data {
        two(one)
      }
    }
    klass3 = Ohai.plugin(:Three) {
      provides("three")
      depends("two")
      collect_data {
        three(two)
      }
    }

    plugins = []
    [klass1, klass2, klass3].each_with_index do |klass, idx|
      plugins << klass.new(@ohai.data)
    end
    @plugin1, @plugin2, @plugin3 = plugins
  end

  it "should return the sources for the plugins in the cycle, when given an exact cycle" do
    cycle = [@plugin1, @plugin2]
    cycle_start = @plugin1

    cycle_names = @runner.get_cycle(cycle, cycle_start)
    cycle_names.should eql([@plugin1.name, @plugin2.name])
  end

  it "should return the sources for only the plugins in the cycle, when there are plugins before the cycle begins" do
    cycle = [@plugin3, @plugin1, @plugin2]
    cycle_start = @plugin1

    cycle_names = @runner.get_cycle(cycle, cycle_start)
    cycle_names.should eql([@plugin1.name, @plugin2.name])
  end
end
