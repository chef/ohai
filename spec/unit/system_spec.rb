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
  describe "#initialize" do
    before(:each) do
      @ohai = Ohai::System.new
    end

    it "should return an Ohai::System object" do
      @ohai.should be_a_kind_of(Ohai::System)
    end

    it "should set @attributes to a Mash" do
      @ohai.attributes.should be_a_kind_of(Mash)
    end

    it "should set @v6_dependency_solver to a Hash" do
      @ohai.v6_dependency_solver.should be_a_kind_of(Hash)
    end
  end

  describe "#load_plugins" do
    before(:each) do
      @loader = double('@loader')
      Ohai::Loader.stub(:new) { @loader }

      @ohai = Ohai::System.new
      @plugin_path = Ohai::Config[:plugin_path]
      Ohai::Mixin::OS.stub(:collect_os).and_return("ubuntu")

    end

    after(:each) do
      Ohai::Config[:plugin_path] = @plugin_path
    end

    describe "when plugin_path has a trailing slash" do
      before(:each) do
        plugin = Ohai::DSL::Plugin.new(@ohai, "/tmp/plugins/plugin.rb")
        @loader.stub(:load_plugin).with("/tmp/plugins/plugin.rb").and_return(plugin)
      end

      it "should load plugins" do
        Ohai::Config[:plugin_path] = ["/tmp/plugins/"]
        Dir.should_receive(:[]).with("/tmp/plugins/*").and_return(["/tmp/plugins/plugin.rb"])
        Dir.should_receive(:[]).with("/tmp/plugins/ubuntu/**/*").and_return([])
        File.stub(:expand_path).with("/tmp/plugins/").and_return("/tmp/plugins")
        @ohai.load_plugins
      end
    end

    describe "with v6 plugins only" do
      before(:each) do
        klass = Ohai.v6plugin { }
        plugin = klass.new(@ohai, "/tmp/plugins/v6.rb")
        @loader.stub(:load_plugin).with("/tmp/plugins/v6.rb").and_return(plugin)
      end

      it "should add the loaded plugin to dep solver" do
        Ohai::Config[:plugin_path] = ["/tmp/plugins"]
        Dir.should_receive(:[]).with("/tmp/plugins/*").and_return(["/tmp/plugins/v6.rb"])
        Dir.should_receive(:[]).with("/tmp/plugins/ubuntu/**/*").and_return([])
        File.stub(:expand_path).with("/tmp/plugins").and_return("/tmp/plugins")
        @ohai.load_plugins
        @ohai.v6_dependency_solver.should have_key("v6")
      end

      it "should log debug message for already loaded plugin_name" do
        Ohai::Config[:plugin_path] = ["/tmp/plugins","/tmp/plugins"]
        Dir.should_receive(:[]).with("/tmp/plugins/*").twice.and_return(["/tmp/plugins/v6.rb"])
        Dir.should_receive(:[]).with("/tmp/plugins/ubuntu/**/*").twice.and_return([])
        File.stub(:expand_path).with("/tmp/plugins").and_return("/tmp/plugins")
        Ohai::Log.should_receive(:debug).with(/Already loaded plugin v6/)
        @ohai.load_plugins
      end
    end

    describe "with v7 plugins only" do
      before(:each) do
        klass = Ohai.plugin(:Test) { }
        plugin = klass.new(@ohai, "/tmp/plugins/test.rb")
        @loader.stub(:load_plugin).with("/tmp/plugins/test.rb").and_return(plugin)
      end

      it "should not add plugin to dep solver" do
        Ohai::Config[:plugin_path] = ["/tmp/plugins"]
        Dir.should_receive(:[]).with("/tmp/plugins/*").and_return(["/tmp/plugins/test.rb"])
        Dir.should_receive(:[]).with("/tmp/plugins/ubuntu/**/*").and_return([])
        File.stub(:expand_path).with("/tmp/plugins").and_return("/tmp/plugins")
        @ohai.load_plugins
        @ohai.v6_dependency_solver.should_not have_key("test")
      end
    end

    describe "with v6 and v7 plugins" do
      describe "on the same path" do
        before(:each) do
          v7klass = Ohai.plugin(:Test) { }
          v7plugin = v7klass.new(@ohai, "/tmp/plugins/v7test.rb")
          @loader.stub(:load_plugin).with("/tmp/plugins/v7test.rb").and_return(v7plugin)

          v6klass = Ohai.v6plugin { }
          v6plugin = v6klass.new(@ohai, "/tmp/plugins/v6test.rb")
          @loader.stub(:load_plugin).with("/tmp/plugins/v6test.rb").and_return(v6plugin)
        end

        it "should load all plugins" do
          Ohai::Config[:plugin_path] = ["/tmp/plugins"]
          Dir.should_receive(:[]).with("/tmp/plugins/*").and_return(["/tmp/plugins/v6test.rb", "/tmp/plugins/v7test.rb"])
          Dir.should_receive(:[]).with("/tmp/plugins/ubuntu/**/*").and_return([])
          File.stub(:expand_path).with("/tmp/plugins").and_return("/tmp/plugins")
          @ohai.load_plugins
          @ohai.v6_dependency_solver.should have_key("v6test")
          Ohai::NamedPlugin.strict_const_defined?(:Test).should be_true
        end
      end

      describe "with duplicate plugin names" do
        before(:each) do
          v7klass = Ohai.plugin(:Test) { }
          v7plugin = v7klass.new(@ohai, "/tmp1/plugins/test.rb")
          @loader.stub(:load_plugin).with("/tmp1/plugins/test.rb").and_return(v7plugin)

          v6klass = Ohai.v6plugin { }
          v6plugin = v6klass.new(@ohai, "/tmp2/plugins/test.rb")
          @loader.stub(:load_plugin).with("/tmp2/plugins/test.rb").and_return(v6plugin)
        end

        it "should load both plugins when v7 path is first" do
          Ohai::Config[:plugin_path] = ["/tmp1/plugins", "/tmp2/plugins"]
          Ohai::Config[:plugin_path].each do |path|
            Dir.should_receive(:[]).with("#{path}/*").and_return(["#{path}/test.rb"])
            Dir.should_receive(:[]).with("#{path}/ubuntu/**/*").and_return([])
            File.stub(:expand_path).with(path).and_return(path)
          end
          @ohai.load_plugins
          @ohai.v6_dependency_solver.should have_key("test")
          Ohai::NamedPlugin.strict_const_defined?(:Test).should be_true
        end

        it "should load both plugins when v6 path is first" do
          Ohai::Config[:plugin_path] = ["/tmp2/plugins", "/tmp1/plugins"]
          Ohai::Config[:plugin_path].each do |path|
            Dir.should_receive(:[]).with("#{path}/*").and_return(["#{path}/test.rb"])
            Dir.should_receive(:[]).with("#{path}/ubuntu/**/*").and_return([])
            File.stub(:expand_path).with(path).and_return(path)
          end
          @ohai.load_plugins
          @ohai.v6_dependency_solver.should have_key("test")
          Ohai::NamedPlugin.strict_const_defined?(:Test).should be_true
        end
      end
    end
  end

  describe "#run_plugins" do
    describe "with v6 plugins only" do
      before(:each) do
        @ohai = Ohai::System.new

        @plugins = []
        @names = ['one', 'two', 'three', 'four', 'five']
        @names.each do |name|
          k = Ohai.v6plugin {
            collect_contents("")
          }
          p = k.new(@ohai, "/tmp/plugins/#{name}.rb")
          @ohai.v6_dependency_solver[name] = p
          @plugins << p
          @ohai.stub(:require_plugin).with(name, false) { p.safe_run }
        end

        @ohai.stub(:collect_plugins).and_return([])
      end

      after(:each) do
        @ohai.v6_dependency_solver.clear
      end

      it "should run all version 6 plugins" do
        @ohai.run_plugins
        @plugins.each do |plugin|
          plugin.has_run?.should be_true
        end
      end
    end

    describe "with v7 plugins only" do
      describe "when handling an error" do
        before(:each) do
          @runner = double('@runner')
          Ohai::Runner.stub(:new) { @runner }

          @ohai = Ohai::System.new
          klass = Ohai.plugin(:Empty) { }
          plugin = klass.new(@ohai, "/tmp/plugins/empty.rb")
          @ohai.stub(:collect_plugins).and_return([plugin])
        end

        describe "when AttributeNotFound is received" do
          it "should write an error to Ohai::Log" do
            @runner.stub(:run_plugin).and_raise(Ohai::Exceptions::AttributeNotFound)
            Ohai::Log.should_receive(:error).with(/Ohai::Exceptions::AttributeNotFound/)
            expect { @ohai.run_plugins }.to raise_error(Ohai::Exceptions::AttributeNotFound)
          end
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
          @plugins << klass.new(@ohai, "")
        end

        @ohai.stub(:collect_plugins).and_return(@plugins)
      end

      it "should run each plugin once from Ohai::System" do
        @plugins.each do |plugin|
          @runner.should_receive(:run_plugin).with(plugin, false)
        end
        @ohai.run_plugins
      end
    end

    describe "with v6 plugins that depend on v7 plugins" do
      before(:each) do
        @ohai = Ohai::System.new
        loader = Ohai::Loader.new(@ohai)

        messages = <<EOF
require_plugin 'v6message'
require_plugin 'v7message'

provides 'messages'

messages Mash.new
messages[:v6message] = v6message
messages[:v7message] = v7message
EOF
        v6message = <<EOF
provides 'v6message'
v6message "update me!"
EOF
        v7message = <<EOF
Ohai.plugin(:V7message) do
  provides 'v7message'

  collect_data(:default) do
    v7message "v7 plugins are awesome!"
  end
end
EOF
        # dummy stub for default behavior
        @ohai.stub(:require_plugin).and_return(false)

        @plugins = []
        [[messages, "messages"], [v6message, "v6message"], [v7message, "v7message"]].each do |contents, name|
          IO.stub(:read).with("/tmp/plugins/#{name}.rb").and_return(contents)
          plugin = loader.load_plugin("/tmp/plugins/#{name}.rb")
          @plugins << plugin
          @ohai.v6_dependency_solver[name] = plugin if plugin.version.eql?(:version6)
          @ohai.stub(:require_plugin).with(name) { plugin.safe_run unless plugin.has_run? }
          @ohai.stub(:require_plugin).with(name, false) { plugin.safe_run unless plugin.has_run? }
          @ohai.stub(:require_plugin).with(name, true) { plugin.safe_run }
        end
      end

      it "should run each plugin" do
        @ohai.run_plugins
        @plugins.each { |plugin| plugin.has_run?.should be_true }
      end

      it "should collect all data" do
        @ohai.run_plugins
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
        @plugins << k.new(@ohai, "")
      end
    end

    it "should find all the plugins providing attributes" do
      a = @ohai.attributes
      a[:zero] = Mash.new
      a[:zero][:_plugins] = [@plugins[0]]
      a[:one] = Mash.new
      a[:one][:_plugins] = [@plugins[1]]
      a[:one][:two] = Mash.new
      a[:one][:two][:_plugins] = [@plugins[2]]
      a[:stub] = Mash.new
      a[:stub][:three] = Mash.new
      a[:stub][:three][:_plugins] = [@plugins[3]]

      providers = @ohai.collect_plugins(@ohai.attributes)
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
      klass = Ohai.v6plugin { }
      @plugin = klass.new(@ohai, "/tmp/plugins/empty.rb")

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
        @ohai.v6_dependency_solver["empty"] = @plugin
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
      it "should look for a suitable plugin" do
        plugin = Ohai::DSL::Plugin::VersionVII.new(@ohai, "PLACEHOLDER.rb")
        plugin.stub(:run).and_return(true)
        klass = Ohai::DSL::Plugin::VersionVII
        klass.stub(:new).with(@ohai, "PLACEHOLDER.rb").and_return(plugin)

        @ohai.v6_dependency_solver.should_receive(:[]).with("test").and_return(nil)
        @ohai.should_receive(:get_v7_name).with("test").and_return("Test")
        Ohai::NamedPlugin.should_receive(:strict_const_defined?).with(:Test).and_return(true)
        Ohai::NamedPlugin.should_receive(:const_get).with(:Test).and_return(klass)

        @ohai.require_plugin("test")
      end

      it "should try to reload the plugin, if a suitable plugin is not found" do
        plugin = Ohai::DSL::Plugin::VersionVII.new(@ohai, "")
        plugin.stub(:run).and_return(true)

        @ohai.v6_dependency_solver.should_receive(:[]).with("test").and_return(nil)
        @ohai.should_receive(:get_v7_name).with("test").and_return("Test")
        Ohai::NamedPlugin.should_receive(:strict_const_defined?).with(:Test).and_return(false)
        @ohai.should_receive(:plugin_for).with("test").and_return(plugin)

        @ohai.require_plugin("test")
      end
    end

    context "when a v6 plugin requires a v7 plugin with dependencies" do
      before(:each) do
        v6string = <<EOF
provides 'v6attr'
require_plugin 'v7plugin'
v6attr message
EOF
        v6klass = Ohai.v6plugin { collect_contents(v6string) }
        v7klass = Ohai.plugin(:V7plugin) {
          provides("message")
          depends("other")
          collect_data{ message(other) }
        }
        otherklass = Ohai.plugin(:Other) {
          provides("other")
          collect_data{ other("o hai") }
        }

        @v6plugin = v6klass.new(@ohai, "/tmp/plugin/v6plugin.rb")
        @v7plugin = v7klass.new(@ohai, "/tmp/plugins/v7plugin.rb")
        @other = otherklass.new(@ohai, "/tmp/plugins/other.rb")

        vds = @ohai.v6_dependency_solver
        vds['v6plugin'] = @v6plugin
        vds['v7plugin'] = @v7plugin
        vds['other'] = @other

        a = @ohai.attributes
        a[:message] = Mash.new
        a[:message][:_plugins] = [@v7plugin]
        a[:other] = Mash.new
        a[:other][:_plugins] = [@other]
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

  describe "#get_v7_name" do
    before(:each) do
      @ohai = Ohai::System.new
    end

    it "should return the empty string if the name includes ::" do
      expect(@ohai.get_v7_name("linux::network")).to eql("")
    end

    it "should capitalize the name" do
      expect(@ohai.get_v7_name("test")).to eql("Test")
    end

    it "should capitalize each part of the name following an underscore" do
      expect(@ohai.get_v7_name("this_test_plugin")).to eql("ThisTestPlugin")
    end
  end

  describe "#plugin_for" do
    before(:each) do
      Ohai::Config[:plugin_path] = ["/tmp/plugins"]

      @loader = double('@loader')
      Ohai::Loader.stub(:new) { @loader }

      @ohai = Ohai::System.new
      @klass = Ohai.v6plugin { }
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
      plugin = @klass.new(@ohai, "/tmp/plugins/ubuntu/empty.rb")
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
