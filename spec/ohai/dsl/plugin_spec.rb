#
#
#

require File.expand_path("../../../spec_helper.rb", __FILE__)

shared_examples "Ohai::DSL::Plugin" do
  context "#initialize" do
    it "should save the plugin source file" do
      plugin.source.should eql(source)
    end

    it "should set has_run? to false" do
      plugin.has_run?.should be_false
    end

    it "should set the correct plugin version" do
      plugin.version.should eql(version)
    end
  end

  context "#run" do
    it "should set has_run? to true" do
      plugin.stub(:run_plugin).and_return(true)
      plugin.run
      plugin.has_run?.should be_true
    end
  end

  context "when accessing data via method_missing" do
    it "should take a missing method and store the method name as a key, with its arguments as value\
s" do
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
  before(:each) do
    @name = :Test
  end

  it "should log a warning when a version 6 plugin with the same name exists" do
    name_str = @name.to_s.downcase
    Ohai.v6plugin(name_str) { }
    Ohai::Log.should_receive(:warn).with(/Already loaded version 6 plugin #{@name}/)
    Ohai.plugin(@name) { }
  end

  describe "#version" do
    it "should save the plugin version as :version7" do
      plugin = Ohai.plugin(@name) { }
      plugin.version.should eql(:version7)
    end
  end

  describe "#provides" do
    it "should collect a single attribute" do
      plugin = Ohai.plugin(@name) { provides("one") }
      plugin.provides_attrs.should eql(["one"])
    end

    it "should collect a list of attributes" do
      plugin = Ohai.plugin(@name) { provides("one", "two", "three") }
      plugin.provides_attrs.should eql(["one", "two", "three"])
    end

    it "should collect from multiple provides statements" do
      plugin = Ohai.plugin(@name) {
        provides("one")
        provides("two", "three")
        provides("four")
      }
      plugin.provides_attrs.should eql(["one", "two", "three", "four"])
    end

    it "should collect attributes across multiple plugin files" do
      plugin = Ohai.plugin(@name) { provides("one") }
      plugin = Ohai.plugin(@name) { provides("two", "three") }
      plugin.provides_attrs.should eql(["one", "two", "three"])
    end
  end

  describe "#depends" do
    it "should collect a single dependency" do
      plugin = Ohai.plugin(@name) { depends("one") }
      plugin.depends_attrs.should eql(["one"])
    end

    it "should collect a list of dependencies" do
      plugin = Ohai.plugin(@name) { depends("one", "two", "three") }
      plugin.depends_attrs.should eql(["one", "two", "three"])
    end

    it "should collect from multiple depends statements" do
      plugin = Ohai.plugin(@name) {
        depends("one")
        depends("two", "three")
        depends("four")
      }
      plugin.depends_attrs.should eql(["one", "two", "three", "four"])
    end

    it "should collect dependencies across multiple plugin files" do
      plugin = Ohai.plugin(@name) { depends("one") }
      plugin = Ohai.plugin(@name) { depends("two", "three") }
      plugin.depends_attrs.should eql(["one", "two", "three"])
    end
  end

  describe "#collect_data" do
    it "should save as :default if no platform is given" do
      plugin = Ohai.plugin(@name) { collect_data { } }
      plugin.data_collector.should have_key(:default)
    end

    it "should save a single given platform" do
      plugin = Ohai.plugin(@name) { collect_data(:ubuntu) { } }
      plugin.data_collector.should have_key(:ubuntu)
    end

    it "should save a list of platforms" do
      plugin = Ohai.plugin(@name) { collect_data(:freebsd, :netbsd, :openbsd) { } }
      [:freebsd, :netbsd, :openbsd].each do |platform|
        plugin.data_collector.should have_key(platform)
      end
    end

    it "should save multiple collect_data blocks" do
      plugin = Ohai.plugin(@name) {
        collect_data { }
        collect_data(:windows) { }
        collect_data(:darwin) { }
      }
      [:darwin, :default, :windows].each do |platform|
        plugin.data_collector.should have_key(platform)
      end
    end

    it "should save platforms across multiple plugins" do
      plugin = Ohai.plugin(@name) { collect_data { } }
      plugin = Ohai.plugin(@name) { collect_data(:aix, :sigar) { } }
      [:aix, :default, :sigar].each do |platform|
        plugin.data_collector.should have_key(platform)
      end
    end

    it "should log a warning if a platform has already been defined in the same plugin" do
      Ohai::Log.should_receive(:warn).with(/Already defined collect_data on platform default/)
      Ohai.plugin(@name) {
        collect_data { }
        collect_data { }
      }
    end

    it "should log a warning if a platform has already been defined in another plugin file" do
      Ohai.plugin(@name) { collect_data { } }
      Ohai::Log.should_receive(:warn).with(/Already defined collect_data on platform default/)
      Ohai.plugin(@name) { collect_data { } }
    end
  end

  describe "#provides (deprecated)" do
    it "should log a warning" do
      plugin = Ohai::DSL::Plugin::VersionVII.new(Ohai::System.new, "")
      Ohai::Log.should_receive(:warn).with(/[UNSUPPORTED OPERATION]/)
      plugin.provides("attribute")
    end
  end

  describe "#require_plugin (deprecated)" do
    it "should log a warning" do
      plugin = Ohai::DSL::Plugin::VersionVII.new(Ohai::System.new, "")
      Ohai::Log.should_receive(:warn).with(/[UNSUPPORTED OPERATION]/)
      plugin.require_plugin("plugin")
    end
  end

  it_behaves_like "Ohai::DSL::Plugin" do
    let (:ohai) { Ohai::System.new }
    let (:source) { "path/plugin.rb" }
    let (:plugin) { Ohai::DSL::Plugin::VersionVII.new(ohai, source) }
    let (:version) { :version7 }
  end
end

describe Ohai::DSL::Plugin::VersionVI do
  before(:each) do
    @name = "test"
    @name_sym = :Test
  end

  it "should log to debug if a plugin with the same name has been defined" do
    Ohai.plugin(@name_sym) { }
    Ohai::Log.should_receive(:debug).with(/Already loaded plugin #{@name_sym}/)
    Ohai.v6plugin(@name) { }
  end

  describe "#version" do
    it "should save the plugin version as :version6" do
      plugin = Ohai.v6plugin(@name) { }
      plugin.version.should eql(:version6)
    end
  end

  describe "#provides" do
    before(:each) do
      @ohai = Ohai::System.new
    end

    it "should collect a single attribute" do
      plugin = Ohai::DSL::Plugin::VersionVI.new(@ohai, "")
      plugin.provides("attribute")

      @ohai.attributes.should have_key(:attribute)
    end

    it "should collect a list of attributes" do
      plugin = Ohai::DSL::Plugin::VersionVI.new(@ohai, "")
      plugin.provides("attr1", "attr2", "attr3")

      [:attr1, :attr2, :attr3].each do |attr|
        @ohai.attributes.should have_key(attr)
      end
    end

    it "should collect subattributes of an attribute" do
      plugin = Ohai::DSL::Plugin::VersionVI.new(@ohai, "")
      plugin.provides("attr/subattr")

      @ohai.attributes.should have_key(:attr)
      @ohai.attributes[:attr].should have_key(:subattr)
    end

    it "should collect all unique providers for an attribute" do
      plugins = []
      3.times do
        p = Ohai::DSL::Plugin::VersionVI.new(@ohai, "")
        p.provides("attribute")
        plugins << p
      end

      @ohai.attributes[:attribute][:_providers].should eql(plugins)
    end
  end

  it_behaves_like "Ohai::DSL::Plugin" do
    let (:ohai) { Ohai::System.new }
    let (:source) { "path/plugin.rb" }
    let (:plugin) { Ohai::DSL::Plugin::VersionVI.new(ohai, source) }
    let (:version) { :version6 }
  end
end
