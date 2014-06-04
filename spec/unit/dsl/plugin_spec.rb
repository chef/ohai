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

require File.expand_path("../../../spec_helper.rb", __FILE__)

shared_examples "Ohai::DSL::Plugin" do
  context "#initialize" do
    it "should set has_run? to false" do
      plugin.has_run?.should be_false
    end

    it "should set the correct plugin version" do
      plugin.version.should eql(version)
    end
  end

  context "#run" do
    before do
      plugin.stub(:run_plugin).and_return(true)
      plugin.stub(:name).and_return(:TestPlugin)
    end

    describe "when plugin is enabled" do
      before do
        Ohai::Config.stub(:[]).with(:disabled_plugins).and_return([ ])
      end

      it "should run the plugin" do
        plugin.should_receive(:run_plugin)
        plugin.run
      end

      it "should set has_run? to true" do
        plugin.run
        plugin.has_run?.should be_true
      end
    end

    describe "if the plugin is disabled" do
      before do
        Ohai::Config.stub(:[]).with(:disabled_plugins).and_return([ :TestPlugin ])
      end

      it "should not run the plugin" do
        plugin.should_not_receive(:run_plugin)
        plugin.run
      end

      it "should log a message to debug" do
        Ohai::Log.should_receive(:debug).with(/Skipping disabled plugin TestPlugin/)
        plugin.run
      end

      it "should set has_run? to true" do
        plugin.run
        plugin.has_run?.should be_true
      end
    end
  end

  context "when accessing data via method_missing" do
    it "should take a missing method and store the method name as a key, with its arguments as values" do
      plugin.guns_n_roses("chinese democracy")
      plugin.data["guns_n_roses"].should eql("chinese democracy")
    end

    it "should return the current value of the method name" do
      plugin.guns_n_roses("chinese democracy").should eql("chinese democracy")
    end

    it "should allow you to get the value of a key by calling method_missing with no arguments" do
      plugin.guns_n_roses("chinese democracy")
      plugin.guns_n_roses.should eql("chinese democracy")
    end
  end

  context "when checking attribute existence" do
    before(:each) do
      plugin.metallica("death magnetic")
    end

    it "should return true if an attribute exists with the given name" do
      plugin.attribute?("metallica").should eql(true)
    end

    it "should return false if an attribute does not exist with the given name" do
      plugin.attribute?("alice in chains").should eql(false)
    end
  end

  context "when setting attributes" do
    it "should let you set an attribute" do
      plugin.set_attribute(:tea, "is soothing")
      plugin.data["tea"].should eql("is soothing")
    end
  end

  context "when getting attributes" do
    before(:each) do
      plugin.set_attribute(:tea, "is soothing")
    end

    it "should let you get an attribute" do
      plugin.get_attribute("tea").should eql("is soothing")
    end
  end
end

describe Ohai::DSL::Plugin::VersionVII do
  it "should not modify the plugin name when the plugin is named correctly" do
    plugin = Ohai.plugin(:FunkyVALIDpluginName) { }.new({ })
    plugin.name.should eql(:FunkyVALIDpluginName)
  end

  describe "when the plugin is named incorrectly" do
    context "because the plugin name doesn't start with a capital letter" do
      it "should raise an Ohai::Exceptions::InvalidPluginName exception" do
        expect{ Ohai.plugin(:badName) { } }.to raise_error(Ohai::Exceptions::InvalidPluginName, /badName is not a valid plugin name/)
      end
    end

    context "because the plugin name contains an underscore" do
      it "should raise an Ohai::Exceptions::InvalidPluginName exception" do
        expect{ Ohai.plugin(:Bad_Name) { } }.to raise_error(Ohai::Exceptions::InvalidPluginName, /Bad_Name is not a valid plugin name/)
      end
    end

    context "because the plugin name isn't a symbol" do
      it "should raise an Ohai::Exceptions::InvalidPluginName exception" do
        expect{ Ohai.plugin(1138) { } }.to raise_error(Ohai::Exceptions::InvalidPluginName, /1138 is not a valid plugin name/)
      end
    end
  end

  describe "#version" do
    it "should save the plugin version as :version7" do
      plugin = Ohai.plugin(:Test) { }
      plugin.version.should eql(:version7)
    end
  end

  describe "#provides" do
    it "should collect a single attribute" do
      plugin = Ohai.plugin(:Test) { provides("one") }
      plugin.provides_attrs.should eql(["one"])
    end

    it "should collect a list of attributes" do
      plugin = Ohai.plugin(:Test) { provides("one", "two", "three") }
      plugin.provides_attrs.should eql(["one", "two", "three"])
    end

    it "should collect from multiple provides statements" do
      plugin = Ohai.plugin(:Test) {
        provides("one")
        provides("two", "three")
        provides("four")
      }
      plugin.provides_attrs.should eql(["one", "two", "three", "four"])
    end

    it "should collect attributes across multiple plugin files" do
      plugin = Ohai.plugin(:Test) { provides("one") }
      plugin = Ohai.plugin(:Test) { provides("two", "three") }
      plugin.provides_attrs.should eql(["one", "two", "three"])
    end

    it "should collect unique attributes" do
      plugin = Ohai.plugin(:Test) { provides("one") }
      plugin = Ohai.plugin(:Test) { provides("one", "two") }
      plugin.provides_attrs.should eql(["one", "two"])
    end
  end

  describe "#depends" do
    it "should collect a single dependency" do
      plugin = Ohai.plugin(:Test) { depends("one") }
      plugin.depends_attrs.should eql(["one"])
    end

    it "should collect a list of dependencies" do
      plugin = Ohai.plugin(:Test) { depends("one", "two", "three") }
      plugin.depends_attrs.should eql(["one", "two", "three"])
    end

    it "should collect from multiple depends statements" do
      plugin = Ohai.plugin(:Test) {
        depends("one")
        depends("two", "three")
        depends("four")
      }
      plugin.depends_attrs.should eql(["one", "two", "three", "four"])
    end

    it "should collect dependencies across multiple plugin files" do
      plugin = Ohai.plugin(:Test) { depends("one") }
      plugin = Ohai.plugin(:Test) { depends("two", "three") }
      plugin.depends_attrs.should eql(["one", "two", "three"])
    end

    it "should collect unique attributes" do
      plugin = Ohai.plugin(:Test) { depends("one") }
      plugin = Ohai.plugin(:Test) { depends("one", "two") }
      plugin.depends_attrs.should eql(["one", "two"])
    end
  end

  describe "#collect_data" do
    it "should save as :default if no platform is given" do
      plugin = Ohai.plugin(:Test) { collect_data { } }
      plugin.data_collector.should have_key(:default)
    end

    it "should save a single given platform" do
      plugin = Ohai.plugin(:Test) { collect_data(:ubuntu) { } }
      plugin.data_collector.should have_key(:ubuntu)
    end

    it "should save a list of platforms" do
      plugin = Ohai.plugin(:Test) { collect_data(:freebsd, :netbsd, :openbsd) { } }
      [:freebsd, :netbsd, :openbsd].each do |platform|
        plugin.data_collector.should have_key(platform)
      end
    end

    it "should save multiple collect_data blocks" do
      plugin = Ohai.plugin(:Test) {
        collect_data { }
        collect_data(:windows) { }
        collect_data(:darwin) { }
      }
      [:darwin, :default, :windows].each do |platform|
        plugin.data_collector.should have_key(platform)
      end
    end

    it "should save platforms across multiple plugins" do
      plugin = Ohai.plugin(:Test) { collect_data { } }
      plugin = Ohai.plugin(:Test) { collect_data(:aix, :sigar) { } }
      [:aix, :default, :sigar].each do |platform|
        plugin.data_collector.should have_key(platform)
      end
    end

    it "should fail a platform has already been defined in the same plugin" do
      expect {
        Ohai.plugin(:Test) {
          collect_data { }
          collect_data { }
        }
      }.to raise_error(Ohai::Exceptions::IllegalPluginDefinition, /collect_data already defined/)
    end

    it "should fail if a platform has already been defined in another plugin file" do
      Ohai.plugin(:Test) { collect_data { } }
      expect {
        Ohai.plugin(:Test) {
          collect_data { }
        }
      }.to raise_error(Ohai::Exceptions::IllegalPluginDefinition, /collect_data already defined/)
    end
  end

  describe "#provides (deprecated)" do
    it "should log a warning" do
      plugin = Ohai::DSL::Plugin::VersionVII.new(Mash.new)
      Ohai::Log.should_receive(:warn).with(/\[UNSUPPORTED OPERATION\]/)
      plugin.provides("attribute")
    end
  end

  describe "#require_plugin (deprecated)" do
    it "should log a warning" do
      plugin = Ohai::DSL::Plugin::VersionVII.new(Mash.new)
      Ohai::Log.should_receive(:warn).with(/\[UNSUPPORTED OPERATION\]/)
      plugin.require_plugin("plugin")
    end
  end

  it_behaves_like "Ohai::DSL::Plugin" do
    let(:ohai) { Ohai::System.new }
    let(:plugin) { Ohai::DSL::Plugin::VersionVII.new(ohai.data) }
    let(:version) { :version7 }
  end
end

describe Ohai::DSL::Plugin::VersionVI do
  describe "#version" do
    it "should save the plugin version as :version6" do
      plugin = Class.new(Ohai::DSL::Plugin::VersionVI) { }
      plugin.version.should eql(:version6)
    end
  end

  describe "#provides" do
    before(:each) do
      @ohai = Ohai::System.new
    end

    it "should log a debug message when provides is used" do
      Ohai::Log.should_receive(:debug).with(/Skipping provides/)
      plugin = Ohai::DSL::Plugin::VersionVI.new(@ohai, "/some/plugin/path.rb", "/some/plugin")
      plugin.provides("attribute")
    end

    it "should not update the provides map for version 6 plugins." do
      plugin = Ohai::DSL::Plugin::VersionVI.new(@ohai, "/some/plugin/path.rb", "/some/plugin")
      plugin.provides("attribute")
      @ohai.provides_map.map.should be_empty
    end

  end

  it_behaves_like "Ohai::DSL::Plugin" do
    let(:ohai) { Ohai::System.new }
    let(:plugin) { Ohai::DSL::Plugin::VersionVI.new(ohai, "/some/plugin/path.rb", "/some/plugin") }
    let(:version) { :version6 }
  end
end
