#
# Author:: Claire McQuin (<claire@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

require_relative "../spec_helper.rb"

describe Ohai::Runner, "run_plugin" do
  let(:safe_run) { true }

  before(:each) do
    @ohai = Ohai::System.new
    @runner = Ohai::Runner.new(@ohai, safe_run)
  end

  describe "when running an invalid plugin" do
    it "should raise error" do
      expect { @runner.run_plugin(double("Ohai::NotPlugin")) }.to raise_error(Ohai::Exceptions::InvalidPlugin)
    end
  end

  describe "when running a plugin" do
    let(:plugin) { double("Ohai::DSL::Plugin", :kind_of? => true, :version => version, :name => :Test, :has_run? => has_run, :dependencies => [ ]) }
    let(:version) { :version7 }
    let(:has_run) { false }

    describe "version 7" do
      it "should call run_v7_plugin" do
        expect(@runner).to receive(:run_v7_plugin)
        @runner.run_plugin(plugin)
      end

      describe "if the plugin has run before" do
        let(:has_run) { true }

        it "should not run the plugin" do
          expect(plugin).not_to receive(:safe_run)
          @runner.run_plugin(plugin)
        end
      end
    end

    describe "version 6" do
      let(:version) { :version6 }

      it "should call run_v6_plugin" do
        expect(@runner).to receive(:run_v6_plugin)
        @runner.run_plugin(plugin)
      end

      describe "if the plugin has not run before" do
        describe "if safe_run is not set" do
          it "safe_run should be called" do
            expect(plugin).to receive(:safe_run)
            @runner.run_plugin(plugin)
          end
        end

        describe "if safe_run is set" do
          let(:safe_run) { false }

          it "run should be called" do
            expect(plugin).to receive(:run)
            @runner.run_plugin(plugin)
          end
        end
      end

      describe "if the plugin has run before" do
        let(:has_run) { true }

        it "should not run" do
          expect(plugin).not_to receive(:safe_run)
          @runner.run_plugin(plugin)
        end

      end
    end

    describe "invalid version" do
      let(:version) { :versionBla }

      it "should raise error" do
        expect { @runner.run_plugin(plugin) }.to raise_error(Ohai::Exceptions::InvalidPlugin)
      end
    end
  end

  describe "when running a plugin with no dependencies, Ohai::Runner" do
    let(:plugin) do
      klass = Ohai.plugin(:Test) do
        provides("thing")
        collect_data do
          thing(Mash.new)
        end
      end
      klass.new(@ohai.data)
    end

    it "should run the plugin" do
      @runner.run_plugin(plugin)
      expect(plugin.has_run?).to be true
    end

    it "should add plugin data to Ohai::System.data" do
      @runner.run_plugin(plugin)
      expect(@ohai.data).to have_key(:thing)
      expect(@ohai.data[:thing]).to eql({})
    end
  end

  describe "when running a plugin with one dependency" do
    describe "when the dependency does not exist" do
      before(:each) do
        klass = Ohai.plugin(:Test) do
          provides("thing")
          depends("other_thing")
          collect_data do
            thing(other_thing)
          end
        end
        @plugin = klass.new(@ohai.data)
      end

      it "should raise Ohai::Excpetions::AttributeNotFound" do
        expect { @runner.run_plugin(@plugin) }.to raise_error(Ohai::Exceptions::AttributeNotFound)
      end

      it "should not run the plugin" do
        expect { @runner.run_plugin(@plugin) }.to raise_error(Ohai::Exceptions::AttributeNotFound)
        expect(@plugin.has_run?).to be false
      end
    end

    describe "when the dependency has a single provider" do
      before(:each) do
        klass1 = Ohai.plugin(:Thing) do
          provides("thing")
          collect_data do
            thing("thang")
          end
        end
        klass2 = Ohai.plugin(:Other) do
          provides("other")
          depends("thing")
          collect_data do
            other(thing)
          end
        end

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
          expect(plugin.has_run?).to be true
        end
      end
    end

    describe "when the dependency has multiple providers" do
      before(:each) do
        klass1 = Ohai.plugin(:Thing) do
          provides("thing")
          collect_data do
            thing(Mash.new)
          end
        end
        klass2 = Ohai.plugin(:Other) do
          provides("other")
          depends("thing")
          collect_data do
            other(thing)
          end
        end

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
          expect(plugin.has_run?).to be true
        end
      end
    end
  end

  describe "when running a plugin with many dependencies" do
    before(:each) do
      @ohai = Ohai::System.new
      @runner = Ohai::Runner.new(@ohai, true)

      klass1 = Ohai.plugin(:One) do
        provides("one")
        collect_data do
          one(1)
        end
      end
      klass2 = Ohai.plugin(:Two) do
        provides("two")
        collect_data do
          two(2)
        end
      end
      klass3 = Ohai.plugin(:Three) do
        provides("three")
        depends("one", "two")
        collect_data do
          three(3)
        end
      end

      @plugins = []
      [klass1, klass2, klass3].each do |klass|
        @plugins << klass.new(@ohai.data)
      end
      @plugin1, @plugin2, @plugin3 = @plugins
      @ohai.provides_map.set_providers_for(@plugin1, %w{one two})
      @ohai.provides_map.set_providers_for(@plugin2, %w{one two})
    end

    it "should run the plugins" do
      @runner.run_plugin(@plugin3)
      @plugins.each do |plugin|
        expect(plugin.has_run?).to be true
      end
    end
  end

  describe "when a cycle is detected" do
    let(:runner) { Ohai::Runner.new(@ohai, true) }

    context "when there are no edges in the cycle (A->A)" do
      let(:plugin_class) do
        klass1 = Ohai.plugin(:Thing) do
          provides("thing")
          depends("thing")
          collect_data do
            thing(other)
          end
        end
      end
      let(:plugin) { plugin_class.new(@ohai.data) }

      it "ignores the cycle" do
        @ohai.provides_map.set_providers_for(plugin, ["thing"])

        expected_error_string = "Dependency cycle detected. Please refer to the following plugins: Thing, Other"
        runner.run_plugin(plugin) # should not raise
      end

    end

    context "when there is one edge in the cycle (A->B and B->A)" do
      before(:each) do
        klass1 = Ohai.plugin(:Thing) do
          provides("thing")
          depends("other")
          collect_data do
            thing(other)
          end
        end
        klass2 = Ohai.plugin(:Other) do
          provides("other")
          depends("thing")
          collect_data do
            other(thing)
          end
        end

        @plugins = []
        [klass1, klass2].each_with_index do |klass, idx|
          @plugins << klass.new(@ohai.data)
        end

        @plugin1, @plugin2 = @plugins
      end

      it "should raise Ohai::Exceptions::DependencyCycle" do
        allow(runner).to receive(:fetch_plugins).with(["thing"]).and_return([@plugin1])
        allow(runner).to receive(:fetch_plugins).with(["other"]).and_return([@plugin2])
        expected_error_string = "Dependency cycle detected. Please refer to the following plugins: Thing, Other"
        expect { runner.run_plugin(@plugin1) }.to raise_error(Ohai::Exceptions::DependencyCycle, expected_error_string)
      end
    end
  end

  describe "when A depends on B and C, and B depends on C" do
    before(:each) do
      @ohai = Ohai::System.new
      @runner = Ohai::Runner.new(@ohai, true)

      klass_a = Ohai.plugin(:A) do
        provides("A")
        depends("B", "C")
        collect_data {}
      end
      klass_b = Ohai.plugin(:B) do
        provides("B")
        depends("C")
        collect_data {}
      end
      klass_c = Ohai.plugin(:C) do
        provides("C")
        collect_data {}
      end

      @plugins = []
      [klass_a, klass_b, klass_c].each do |klass|
        @plugins << klass.new(@ohai.data)
      end
      @plugin_a, @plugin_b, @plugin_c = @plugins
    end

    it "should not detect a cycle when B is the first provider returned" do
      @ohai.provides_map.set_providers_for(@plugin_a, ["A"])
      @ohai.provides_map.set_providers_for(@plugin_b, ["B"])
      @ohai.provides_map.set_providers_for(@plugin_c, ["C"])

      expect(Ohai::Log).not_to receive(:error).with(/DependencyCycleError/)
      @runner.run_plugin(@plugin_a)

      @plugins.each do |plugin|
        expect(plugin.has_run?).to be true
      end
    end

    it "should not detect a cycle when C is the first provider returned" do
      @ohai.provides_map.set_providers_for(@plugin_a, ["A"])
      @ohai.provides_map.set_providers_for(@plugin_c, ["C"])
      @ohai.provides_map.set_providers_for(@plugin_b, ["B"])

      expect(Ohai::Log).not_to receive(:error).with(/DependencyCycleError/)
      @runner.run_plugin(@plugin_a)

      @plugins.each do |plugin|
        expect(plugin.has_run?).to be true
      end
    end
  end
end

describe Ohai::Runner, "fetch_plugins" do
  before(:each) do
    @provides_map = Ohai::ProvidesMap.new
    @data = Mash.new
    @ohai = double("Ohai::System", :data => @data, :provides_map => @provides_map)
    @runner = Ohai::Runner.new(@ohai, true)
  end

  it "should collect the provider" do
    plugin = Ohai::DSL::Plugin.new(@ohai.data)
    @ohai.provides_map.set_providers_for(plugin, ["top/middle/bottom"])

    dependency_providers = @runner.fetch_plugins(["top/middle/bottom"])
    expect(dependency_providers).to eql([plugin])
  end

  describe "when the attribute is not provided by any plugin" do
    describe "and some parent attribute has providers" do
      it "should return the providers for the parent" do
        plugin = Ohai::DSL::Plugin.new(@ohai.data)
        @provides_map.set_providers_for(plugin, ["test/attribute"])
        expect(@runner.fetch_plugins(["test/attribute/too_far"])).to eql([plugin])
      end
    end

    describe "and no parent attribute has providers" do
      it "should raise Ohai::Exceptions::AttributeNotFound exception" do
        # provides map is empty
        expect { @runner.fetch_plugins(["false/attribute"]) }.to raise_error(Ohai::Exceptions::AttributeNotFound, "No such attribute: 'false/attribute'")
      end
    end
  end

  it "should return unique providers" do
    plugin = Ohai::DSL::Plugin.new(@ohai.data)
    @provides_map.set_providers_for(plugin, ["test", "test/too_far/way_too_far"])
    expect(@runner.fetch_plugins(["test", "test/too_far/way_too_far"])).to eql([plugin])
  end
end

describe Ohai::Runner, "#get_cycle" do
  before(:each) do
    @ohai = Ohai::System.new
    @runner = Ohai::Runner.new(@ohai, true)

    klass1 = Ohai.plugin(:One) do
      provides("one")
      depends("two")
      collect_data do
        one(two)
      end
    end
    klass2 = Ohai.plugin(:Two) do
      provides("two")
      depends("one")
      collect_data do
        two(one)
      end
    end
    klass3 = Ohai.plugin(:Three) do
      provides("three")
      depends("two")
      collect_data do
        three(two)
      end
    end

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
    expect(cycle_names).to eql([@plugin1.name, @plugin2.name])
  end

  it "should return the sources for only the plugins in the cycle, when there are plugins before the cycle begins" do
    cycle = [@plugin3, @plugin1, @plugin2]
    cycle_start = @plugin1

    cycle_names = @runner.get_cycle(cycle, cycle_start)
    expect(cycle_names).to eql([@plugin1.name, @plugin2.name])
  end
end
