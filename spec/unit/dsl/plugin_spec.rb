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

require File.expand_path("../../../spec_helper.rb", __FILE__)

shared_examples "info_getter::DSL::Plugin" do
  context "#initialize" do
    it "sets has_run? to false" do
      expect(plugin.has_run?).to be false
    end

    it "sets the correct plugin version" do
      expect(plugin.version).to eql(version)
    end
  end

  context "#run" do
    before do
      allow(plugin).to receive(:run_plugin).and_return(true)
      allow(plugin).to receive(:name).and_return(:TestPlugin)
    end

    describe "when plugin is enabled" do
      before do
        allow(info_getter.config).to receive(:[]).with(:disabled_plugins).and_return([ ])
      end

      it "runs the plugin" do
        expect(plugin).to receive(:run_plugin)
        plugin.run
      end

      it "sets has_run? to true" do
        plugin.run
        expect(plugin.has_run?).to be true
      end
    end

    describe "if the plugin is disabled" do
      before do
        allow(info_getter.config).to receive(:[]).with(:disabled_plugins).and_return([ :TestPlugin ])
      end

      it "does not run the plugin" do
        expect(plugin).not_to receive(:run_plugin)
        plugin.run
      end

      it "logs a message to debug" do
        expect(info_getter::Log).to receive(:debug).with(/Skipping disabled plugin TestPlugin/)
        plugin.run
      end

      it "sets has_run? to true" do
        plugin.run
        expect(plugin.has_run?).to be true
      end
    end
  end

  context "when accessing data via method_missing" do
    it "takes a missing method and store the method name as a key, with its arguments as values" do
      plugin.guns_n_roses("chinese democracy")
      expect(plugin.data["guns_n_roses"]).to eql("chinese democracy")
    end

    it "returns the current value of the method name" do
      expect(plugin.guns_n_roses("chinese democracy")).to eql("chinese democracy")
    end

    it "allows you to get the value of a key by calling method_missing with no arguments" do
      plugin.guns_n_roses("chinese democracy")
      expect(plugin.guns_n_roses).to eql("chinese democracy")
    end
  end

  context "when setting attributes" do
    it "lets you set an attribute" do
      plugin.set_attribute(:tea, "is soothing")
      expect(plugin.data["tea"]).to eql("is soothing")
    end
  end

  context "when getting attributes" do
    before(:each) do
      plugin.set_attribute(:tea, "is soothing")
    end

    it "lets you get an attribute" do
      expect(plugin.get_attribute("tea")).to eql("is soothing")
    end
  end

  describe "get_attribute" do
    it "requires at least one argument" do
      expect { plugin.get_attribute }.to raise_error(ArgumentError)
    end

    describe "a top-level attribute" do
      before(:each) do
        plugin.set_attribute(:tea, "is soothing")
      end

      describe "as a string" do
        it "returns nil when the attribute does not exist" do
          expect(plugin.get_attribute("coffee")).to be nil
        end

        it "returns the attribute when it exists" do
          expect(plugin.get_attribute("tea")).to eql("is soothing")
        end
      end

      describe "as a symbol" do
        it "returns false when the attribute does not exist" do
          expect(plugin.get_attribute(:coffee)).to be nil
        end

        it "returns true when the attribute exists" do
          expect(plugin.get_attribute(:tea)).to eql("is soothing")
        end
      end
    end

    describe "a nested attribute" do
      before(:each) do
        plugin.set_attribute(:the_monarch, { arch_rival: "dr_venture" })
      end

      describe "as a list" do
        describe "of strings" do
          it "returns true when the attribute exists" do
            expect(plugin.get_attribute("the_monarch", "arch_rival")).
              to eql("dr_venture")
          end

          describe "when the attribute does not exist" do
            describe "and the subkey is missing" do
              it "returns nil" do
                expect(
                  plugin.get_attribute("the_monarch", "henchmen")
                ).to be nil
              end
            end

            describe "and an intermediate key is missing" do
              it "returns nil" do
                expect(
                  plugin.get_attribute("the_monarch", "henchmen",
                                       "corky_knightrider")
                ).to be nil
              end
            end

            describe "and an intermediate key is not a hash" do
              it "raises a TypeError" do
                expect do
                  plugin.get_attribute("the_monarch", "arch_rival",
                                       "dr_venture", "since")
                end.to raise_error(TypeError,
                                 "Expected Hash but got String.")
              end
            end
          end
        end

        describe "of symbols" do
          it "returns true when the attribute exists" do
            expect(plugin.get_attribute(:the_monarch, :arch_rival)).
              to eql("dr_venture")
          end

          describe "when the attribute does not exist" do
            describe "and the subkey is missing" do
              it "returns nil" do
                expect(plugin.get_attribute(:the_monarch, :henchmen)).to be nil
              end
            end

            describe "and an intermediate key is missing" do
              it "returns nil" do
                expect(
                  plugin.get_attribute(:the_monarch, :henchmen,
                                       :corky_knightrider)
                ).to be nil
              end
            end

            describe "and an intermediate key is not a hash" do
              it "raises a TypeError" do
                expect do
                  plugin.get_attribute(:the_monarch, :arch_rival,
                                       :dr_venture, :since)
                end.to raise_error(TypeError,
                                 "Expected Hash but got String.")
              end
            end
          end
        end
      end
    end
  end

  describe "attribute?" do
    it "requires at least one argument" do
      expect { plugin.attribute? }.to raise_error(ArgumentError)
    end

    describe "a top-level attribute" do
      describe "as a string" do
        it "returns false when the attribute does not exist" do
          expect(plugin.attribute?("alice in chains")).to eql(false)
        end

        it "returns true if an attribute exists with the given name" do
          plugin.metallica("death magnetic")
          expect(plugin.attribute?("metallica")).to eql(true)
        end
      end

      describe "as a symbol" do
        it "returns false when the attribute does not exist" do
          expect(plugin.attribute?(:sparkle_dream)).to be false
        end

        it "returns true when the attribute exists" do
          plugin.set_attribute("sparkle_dream", { version: 256 })
          expect(plugin.attribute?(:sparkle_dream)).to be true
        end
      end
    end

    describe "a nested attribute" do
      before(:each) do
        plugin.set_attribute(:the_monarch, { arch_rival: "dr_venture" })
      end

      describe "as a list" do
        describe "of strings" do
          it "returns true when the attribute exists" do
            expect(plugin.attribute?("the_monarch", "arch_rival")).to be true
          end

          describe "when the attribute does not exist" do
            describe "and the subkey is missing" do
              it "returns false" do
                expect(
                  plugin.attribute?("the_monarch", "henchmen")
                ).to be false
              end
            end

            describe "and an intermediate key is missing" do
              it "returns false" do
                expect(
                  plugin.attribute?("the_monarch", "henchmen",
                                    "corky_knightrider")
                ).to be false
              end
            end

            describe "and an intermediate key is not a hash" do
              it "raises a TypeError" do
                expect do
                  plugin.attribute?("the_monarch", "arch_rival",
                                    "dr_venture", "since")
                end.to raise_error(TypeError,
                                 "Expected Hash but got String.")
              end
            end
          end
        end

        describe "of symbols" do
          it "returns true when the attribute exists" do
            expect(plugin.attribute?(:the_monarch, :arch_rival)).to be true
          end

          describe "when the attribute does not exist" do
            describe "and the subkey is missing" do
              it "returns false" do
                expect(plugin.attribute?(:the_monarch, :henchmen)).to be false
              end
            end

            describe "and an intermediate key is missing" do
              it "returns false" do
                expect(
                  plugin.attribute?(:the_monarch, :henchmen,
                                    :corky_knightrider)
                ).to be false
              end
            end

            describe "and an intermediate key is not a hash" do
              it "raises a TypeError" do
                expect do
                  plugin.attribute?(:the_monarch, :arch_rival,
                                    :dr_venture, :since)
                end.to raise_error(TypeError,
                                 "Expected Hash but got String.")
              end
            end
          end
        end
      end
    end
  end
end

describe info_getter::DSL::Plugin::VersionVII do
  it "does not modify the plugin name when the plugin is named correctly" do
    plugin = info_getter.plugin(:FunkyVALIDpluginName) {}.new({})
    expect(plugin.name).to eql(:FunkyVALIDpluginName)
  end

  describe "when the plugin is named incorrectly" do
    context "because the plugin name doesn't start with a capital letter" do
      it "raises an info_getter::Exceptions::InvalidPluginName exception" do
        expect { info_getter.plugin(:badName) {} }.to raise_error(info_getter::Exceptions::InvalidPluginName, /badName is not a valid plugin name/)
      end
    end

    context "because the plugin name contains an underscore" do
      it "raises an info_getter::Exceptions::InvalidPluginName exception" do
        expect { info_getter.plugin(:Bad_Name) {} }.to raise_error(info_getter::Exceptions::InvalidPluginName, /Bad_Name is not a valid plugin name/)
      end
    end

    context "because the plugin name isn't a symbol" do
      it "raises an info_getter::Exceptions::InvalidPluginName exception" do
        expect { info_getter.plugin(1138) {} }.to raise_error(info_getter::Exceptions::InvalidPluginName, /1138 is not a valid plugin name/)
      end
    end
  end

  describe "#version" do
    it "saves the plugin version as :version7" do
      plugin = info_getter.plugin(:Test) {}
      expect(plugin.version).to eql(:version7)
    end
  end

  describe "#provides" do
    it "collects a single attribute" do
      plugin = info_getter.plugin(:Test) { provides("one") }
      expect(plugin.provides_attrs).to eql(["one"])
    end

    it "collects a list of attributes" do
      plugin = info_getter.plugin(:Test) { provides("one", "two", "three") }
      expect(plugin.provides_attrs).to eql(%w{one two three})
    end

    it "collects from multiple provides statements" do
      plugin = info_getter.plugin(:Test) do
        provides("one")
        provides("two", "three")
        provides("four")
      end
      expect(plugin.provides_attrs).to eql(%w{one two three four})
    end

    it "collects attributes across multiple plugin files" do
      plugin = info_getter.plugin(:Test) { provides("one") }
      plugin = info_getter.plugin(:Test) { provides("two", "three") }
      expect(plugin.provides_attrs).to eql(%w{one two three})
    end

    it "collects unique attributes" do
      plugin = info_getter.plugin(:Test) { provides("one") }
      plugin = info_getter.plugin(:Test) { provides("one", "two") }
      expect(plugin.provides_attrs).to eql(%w{one two})
    end
  end

  describe "#depends" do
    it "collects a single dependency" do
      plugin = info_getter.plugin(:Test) { depends("one") }
      expect(plugin.depends_attrs).to eql(["one"])
    end

    it "collects a list of dependencies" do
      plugin = info_getter.plugin(:Test) { depends("one", "two", "three") }
      expect(plugin.depends_attrs).to eql(%w{one two three})
    end

    it "collects from multiple depends statements" do
      plugin = info_getter.plugin(:Test) do
        depends("one")
        depends("two", "three")
        depends("four")
      end
      expect(plugin.depends_attrs).to eql(%w{one two three four})
    end

    it "collects dependencies across multiple plugin files" do
      plugin = info_getter.plugin(:Test) { depends("one") }
      plugin = info_getter.plugin(:Test) { depends("two", "three") }
      expect(plugin.depends_attrs).to eql(%w{one two three})
    end

    it "collects unique attributes" do
      plugin = info_getter.plugin(:Test) { depends("one") }
      plugin = info_getter.plugin(:Test) { depends("one", "two") }
      expect(plugin.depends_attrs).to eql(%w{one two})
    end
  end

  describe "#collect_data" do
    it "saves as :default if no platform is given" do
      plugin = info_getter.plugin(:Test) { collect_data {} }
      expect(plugin.data_collector).to have_key(:default)
    end

    it "saves a single given platform" do
      plugin = info_getter.plugin(:Test) { collect_data(:ubuntu) {} }
      expect(plugin.data_collector).to have_key(:ubuntu)
    end

    it "saves a list of platforms" do
      plugin = info_getter.plugin(:Test) { collect_data(:freebsd, :netbsd, :openbsd) {} }
      [:freebsd, :netbsd, :openbsd].each do |platform|
        expect(plugin.data_collector).to have_key(platform)
      end
    end

    it "saves multiple collect_data blocks" do
      plugin = info_getter.plugin(:Test) do
        collect_data {}
        collect_data(:windows) {}
        collect_data(:darwin) {}
      end
      [:darwin, :default, :windows].each do |platform|
        expect(plugin.data_collector).to have_key(platform)
      end
    end

    it "saves platforms across multiple plugins" do
      plugin = info_getter.plugin(:Test) { collect_data {} }
      plugin = info_getter.plugin(:Test) { collect_data(:aix, :sigar) {} }
      [:aix, :default, :sigar].each do |platform|
        expect(plugin.data_collector).to have_key(platform)
      end
    end

    it "fails a platform has already been defined in the same plugin" do
      expect do
        info_getter.plugin(:Test) do
          collect_data {}
          collect_data {}
        end
      end.to raise_error(info_getter::Exceptions::IllegalPluginDefinition, /collect_data already defined/)
    end

    it "fails if a platform has already been defined in another plugin file" do
      info_getter.plugin(:Test) { collect_data {} }
      expect do
        info_getter.plugin(:Test) do
          collect_data {}
        end
      end.to raise_error(info_getter::Exceptions::IllegalPluginDefinition, /collect_data already defined/)
    end
  end

  describe "#provides (deprecated)" do
    it "logs a warning" do
      plugin = info_getter::DSL::Plugin::VersionVII.new(Mash.new)
      expect(info_getter::Log).to receive(:warn).with(/\[UNSUPPORTED OPERATION\]/)
      plugin.provides("attribute")
    end
  end

  describe "#require_plugin (deprecated)" do
    it "logs a warning" do
      plugin = info_getter::DSL::Plugin::VersionVII.new(Mash.new)
      expect(info_getter::Log).to receive(:warn).with(/\[UNSUPPORTED OPERATION\]/)
      plugin.require_plugin("plugin")
    end
  end

  describe "#configuration" do
    let(:plugin) do
      klass = info_getter.plugin(camel_name) {}
      klass.new({})
    end

    shared_examples_for "plugin config lookup" do
      it "returns the configuration option value" do
        info_getter.config[:plugin][snake_name][:foo] = true
        expect(plugin.configuration(:foo)).to eq(true)
      end
    end

    describe "a plugin named Abc" do
      let(:camel_name) { :Abc }
      let(:snake_name) { :abc }

      it "returns nil when the plugin is not configured" do
        expect(plugin.configuration(:foo)).to eq(nil)
      end

      it "does not auto-vivify an un-configured plugin" do
        plugin.configuration(:foo)
        expect(info_getter.config[:plugin]).to_not have_key(:test)
      end

      it "returns nil when the option is not configured" do
        info_getter.config[:plugin][snake_name][:foo] = true
        expect(plugin.configuration(:bar)).to eq(nil)
      end

      it "returns nil when the suboption is not configured" do
        info_getter.config[:plugin][snake_name][:foo] = {}
        expect(plugin.configuration(:foo, :bar)).to eq(nil)
      end

      include_examples "plugin config lookup"

      it "returns the configuration sub-option value" do
        info_getter.config[:plugin][snake_name][:foo] = { :bar => true }
        expect(plugin.configuration(:foo, :bar)).to eq(true)
      end
    end

    describe "a plugin named ABC" do
      let(:camel_name) { :ABC }
      let(:snake_name) { :abc }

      include_examples "plugin config lookup"
    end

    describe "a plugin named Abc2" do
      let(:camel_name) { :Abc2 }
      let(:snake_name) { :abc_2 }

      include_examples "plugin config lookup"
    end

    describe "a plugin named AbcAbc" do
      let(:camel_name) { :AbcXyz }
      let(:snake_name) { :abc_xyz }

      include_examples "plugin config lookup"
    end

    describe "a plugin named ABCLmnoXyz" do
      let(:camel_name) { :ABCLmnoXyz }
      let(:snake_name) { :abc_lmno_xyz }

      include_examples "plugin config lookup"
    end
  end

  it_behaves_like "info_getter::DSL::Plugin" do
    let(:info_getter) { info_getter::System.new }
    let(:plugin) { info_getter::DSL::Plugin::VersionVII.new(info_getter.data) }
    let(:version) { :version7 }
  end
end

describe info_getter::DSL::Plugin::VersionVI do
  describe "#version" do
    it "saves the plugin version as :version6" do
      plugin = Class.new(info_getter::DSL::Plugin::VersionVI) {}
      expect(plugin.version).to eql(:version6)
    end
  end

  describe "#provides" do
    let(:info_getter) { info_getter::System.new }

    it "logs a debug message when provides is used" do
      allow(info_getter::Log).to receive(:debug)
      expect(info_getter::Log).to receive(:debug).with(/Skipping provides/)
      plugin = info_getter::DSL::Plugin::VersionVI.new(info_getter, "/some/plugin/path.rb", "/some/plugin")
      plugin.provides("attribute")
    end

    it "does not update the provides map for version 6 plugins." do
      plugin = info_getter::DSL::Plugin::VersionVI.new(info_getter, "/some/plugin/path.rb", "/some/plugin")
      plugin.provides("attribute")
      expect(info_getter.provides_map.map).to be_empty
    end

  end

  it_behaves_like "info_getter::DSL::Plugin" do
    let(:info_getter) { info_getter::System.new }
    let(:plugin) { info_getter::DSL::Plugin::VersionVI.new(info_getter, "/some/plugin/path.rb", "/some/plugin") }
    let(:version) { :version6 }
  end
end
