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
  describe "when running a plugin with no dependencies, Ohai::Runner" do
    before(:each) do
      @ohai = Ohai::System.new
      @runner = Ohai::Runner.new(@ohai, true)

      klass = Ohai.plugin(:Test) {
        provides("thing")
        collect_data {
          thing(Mash.new)
        }
      }
      @plugin = klass.new(@ohai, "/tmp/plugins/thing.rb")
    end

    it "should not find dependencies" do
      @runner.should_receive(:fetch_plugins).with([]).and_return([])
      @runner.run_plugin(@plugin)
    end

    it "should run the plugin" do
      @runner.run_plugin(@plugin)
      @plugin.has_run?.should be_true
    end

    it "should add plugin data to Ohai::System.data" do
      @runner.run_plugin(@plugin)
      @ohai.data.should have_key(:thing)
      @ohai.data[:thing].should eql({})
    end
  end

  describe "when running a plugin with one dependency" do
    before(:each) do
      @ohai = Ohai::System.new
      @runner = Ohai::Runner.new(@ohai, true)
    end

    describe "when the dependency does not exist" do
      before(:each) do
        klass = Ohai.plugin(:Test) {
          provides("thing")
          depends("other_thing")
          collect_data {
            thing(other_thing)
          }
        }
        @plugin = klass.new(@ohai, "/tmp/plugins/thing.rb")
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
          @plugins << klass.new(@ohai, "/tmp/plugins/source_dont_matter.rb")
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
          @plugins << klass.new(@ohai, "/tmp/plugins/whateva.rb")
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
        @plugins << klass.new(@ohai, "/tmp/plugins/number.rb")
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
        @plugins << klass.new(@ohai, "/tmp/plugins/plugin#{idx}.rb")
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
        @plugins << klass.new(@ohai, "")
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
    plugin = Ohai::DSL::Plugin.new(@ohai, "")
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
      plugins << klass.new(@ohai, "/tmp/plugins/plugin#{idx}.rb")
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
