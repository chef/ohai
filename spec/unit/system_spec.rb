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
      Ohai::OS.stub(:collect_os).and_return("ubuntu")

      loader = double('@loader')
      Ohai::Loader.stub(:new) { loader }

      @ohai = Ohai::System.new
      klass = Ohai.plugin { }
      plugin = klass.new(@ohai, "/tmp/plugins/empty.rb")
      loader.stub(:load_plugin).with("/tmp/plugins/empty.rb").and_return(plugin)
    end

    it "should load plugins when plugin_path has a trailing slash" do
      Ohai::Config[:plugin_path] = ["/tmp/plugins/"]
      Dir.should_receive(:[]).with("/tmp/plugins/*").and_return(["/tmp/plugins/empty.rb"])
      Dir.should_receive(:[]).with("/tmp/plugins/ubuntu/**/*").and_return([])
      File.stub(:expand_path).with("/tmp/plugins/").and_return("/tmp/plugins")
      @ohai.load_plugins
    end

    it "should log debug message for already loaded plugin" do
      Ohai::Config[:plugin_path] = ["/tmp/plugins","/tmp/plugins"]
      Dir.should_receive(:[]).with("/tmp/plugins/*").twice.and_return(["/tmp/plugins/empty.rb"])
      Dir.should_receive(:[]).with("/tmp/plugins/ubuntu/**/*").twice.and_return([])
      File.stub(:expand_path).with("/tmp/plugins").and_return("/tmp/plugins")
      Ohai::Log.should_receive(:debug).with(/Already loaded plugin at/)
      @ohai.load_plugins
    end

    it "should add loaded plugins to @v6_dependency_solver" do
      Ohai::Config[:plugin_path] = ["/tmp/plugins"]
      Ohai::OS.stub(:collect_os).and_return("ubuntu")
      Dir.should_receive(:[]).with("/tmp/plugins/*").and_return(["/tmp/plugins/empty.rb"])
      Dir.should_receive(:[]).with("/tmp/plugins/ubuntu/**/*").and_return([])
      File.stub(:expand_path).with("/tmp/plugins").and_return("/tmp/plugins")
      @ohai.load_plugins
      @ohai.v6_dependency_solver.should have_key("empty")
    end
  end

  describe "#run_plugins" do
    describe "with v6 plugins only" do
      before(:each) do
        @ohai = Ohai::System.new
        @klass = Ohai.v6plugin { collect_contents("") }

        @plugins = []
        5.times do |x|
          @plugins << @klass.new(@ohai, "/tmp/plugins/plugin#{x}.rb")
        end

        ['one', 'two', 'three', 'four', 'five'].each_with_index do |plugin_name, idx|
          @ohai.v6_dependency_solver[plugin_name] = @plugins[idx]
        end

        @ohai.stub(:collect_providers).and_return([])
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
          klass = Ohai.plugin { }
          plugin = klass.new(@ohai, "/tmp/plugins/empty.rb")
          @ohai.stub(:collect_providers).and_return([plugin])
        end

        describe "when a NoAttributeError is received" do
          it "should write an error to Ohai::Log" do
            @runner.stub(:run_plugin).and_raise(Ohai::NoAttributeError)
            Ohai::Log.should_receive(:error).with(/NoAttributeError/)
            expect { @ohai.run_plugins }.to raise_error(Ohai::NoAttributeError)
          end
        end
      end
    end

    describe "when running all loaded plugins" do
      before(:each) do
        @runner = double('@runner')
        Ohai::Runner.stub(:new) { @runner }

        @ohai = Ohai::System.new

        klass = Ohai.plugin { provides("itself"); collect_data { itself("me") } }
        @plugins = []
        5.times do |x|
          @plugins << klass.new(@ohai, "/tmp/plugins/plugin#{x}.rb")
        end

        @ohai.stub(:collect_providers).and_return(@plugins)
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

        @plugin_path = Ohai::Config[:plugin_path]
        Ohai::Config[:plugin_path] = [File.expand_path(File.dirname(__FILE__) + '/../data/plugins')]
        @ohai.load_plugins

        @plugins = []
        @ohai.v6_dependency_solver.each { |plugin_name, plugin| @plugins << plugin }
      end

      after(:each) do
        Ohai::Config[:plugin_path] = @plugin_path
      end

      it "should run each plugin" do
        @ohai.run_plugins(true)
        @plugins.each { |plugin| plugin.has_run?.should be_true }
      end

      it "should collect all data" do
        @ohai.run_plugins(true)
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

  describe "#collect_providers" do
    before(:each) do
      @ohai = Ohai::System.new

      klass = Ohai.plugin { }
      @plugins = []
      4.times do
        @plugins << klass.new(@ohai, "")
      end
    end

    it "should find all the plugins providing attributes" do
      a = @ohai.attributes
      a[:zero] = Mash.new
      a[:zero][:providers] = [@plugins[0]]
      a[:one] = Mash.new
      a[:one][:providers] = [@plugins[1]]
      a[:one][:two] = Mash.new
      a[:one][:two][:providers] = [@plugins[2]]
      a[:stub] = Mash.new
      a[:stub][:three] = Mash.new
      a[:stub][:three][:providers] = [@plugins[3]]

      providers = @ohai.collect_providers(@ohai.attributes)
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

    after(:each) do
      Ohai::Config[:plugin_path] = @plugin_path
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
        v6klass = Ohai.v6plugin { collect_contents(v6string) }
        v7klass = Ohai.plugin { provides("message"); collect_data { message("hey.") } }
        @v6plugin = v6klass.new(@ohai, "/tmp/plugins/v6plugin.rb")
        @v7plugin = v7klass.new(@ohai, "/tmp/plugins/v7plugin.rb")

        @ohai.v6_dependency_solver['v6plugin'] = @v6plugin
        @ohai.v6_dependency_solver['v7plugin'] = @v7plugin
        @ohai.attributes[:message] = Mash.new
        @ohai.attributes[:message][:providers] = [@v7plugin]
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
        v6klass = Ohai.v6plugin { collect_contents(v6string) }
        v7klass = Ohai.plugin { provides("message"); depends("other"); collect_data{ message(other) } }
        otherklass = Ohai.plugin { provides("other"); collect_data{ other("o hai") } }

        @v6plugin = v6klass.new(@ohai, "/tmp/plugin/v6plugin.rb")
        @v7plugin = v7klass.new(@ohai, "/tmp/plugins/v7plugin.rb")
        @other = otherklass.new(@ohai, "/tmp/plugins/other.rb")

        vds = @ohai.v6_dependency_solver
        vds['v6plugin'] = @v6plugin
        vds['v7plugin'] = @v7plugin
        vds['other'] = @other

        a = @ohai.attributes
        a[:message] = Mash.new
        a[:message][:providers] = [@v7plugin]
        a[:other] = Mash.new
        a[:other][:providers] = [@other]
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
