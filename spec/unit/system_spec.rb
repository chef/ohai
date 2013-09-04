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
      @plugin_path = Ohai::Config[:plugin_path]
      Ohai::OS.stub(:collect_os).and_return("ubuntu")

      @ohai = Ohai::System.new
      klass = Ohai.plugin { }
      plugin = klass.new(@ohai, "/tmp/plugins/empty.rb")
      
      loader = double('loader')
      Ohai::Loader.stub(:new) { loader }
      loader.stub(:load_plugin).with("/tmp/plugins/empty.rb").and_return(plugin)
    end

    after(:each) do
      Ohai::Config[:plugin_path] = @plugin_path
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
      @ohai.v6_dependency_solver.should have_key("/tmp/plugins/empty.rb")
    end
  end

  describe "#run_plugins" do
    describe "when handling an error" do
      before(:each) do
        @ohai = Ohai::System.new
        klass = Ohai.plugin { }
        plugin = klass.new(@ohai, "/tmp/plugins/empty.rb")
        @ohai.stub(:collect_providers).and_return([plugin])
        
        @runner = double('runner')
        Ohai::Runner.stub(:new) { @runner }
      end

      describe "when a NoAttributeError is received" do
        it "should write an error to Ohai::Log" do
          @runner.stub(:run_plugin).and_raise(Ohai::NoAttributeError)
          Ohai::Log.should_receive(:error).with(/NoAttributeError/)
          expect { @ohai.run_plugins }.to raise_error(Ohai::NoAttributeError)
        end
      end

      describe "when a DependencyCycleError is received" do
        it "should write an error to Ohai::Log" do
          @runner.stub(:run_plugin).and_raise(Ohai::DependencyCycleError)
          Ohai::Log.should_receive(:error).with(/DependencyCycleError/)
          expect { @ohai.run_plugins }.to raise_error(Ohai::DependencyCycleError)
        end
      end
    end

    describe "when running all loaded plugins" do
      before(:each) do
        @ohai = Ohai::System.new

        klass = Ohai.plugin { provides("itself"); collect_data { itself("me") } }
        @plugins = []
        5.times do |x|
          @plugins << klass.new(@ohai, "/tmp/plugins/plugin#{x}.rb")
        end

        @ohai.stub(:collect_providers).and_return(@plugins)

        @runner = double('runner')
        Ohai::Runner.stub(:new) { @runner }
      end

      it "should run each plugin once from Ohai::System" do
        @plugins.each do |plugin|
          @runner.should_receive(:run_plugin).with(plugin, false)
        end
        @ohai.run_plugins
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
end
