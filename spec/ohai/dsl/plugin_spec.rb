#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Claire McQuin (<claire@opscode.com>)
# Copyright:: Copyright (c) 2008, 2012, 2013 Opscode, Inc.
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or  implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path("../../../spec_helper", __FILE__)

shared_examples "Ohai::DSL::Plugin" do
  it "should save the plugin source file" do
    @plugin.source.should eql(source)
  end

  it "should set has_run? to false" do
    @plugin.has_run?.should be_false
  end

  it "should set has_run? to true after running the plugin" do
    @plugin.stub(:run_plugin).and_return(true)
    @plugin.run
    @plugin.has_run?.should be_true
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
  describe "when loaded" do
    describe "#self.provides_attrs" do
      before(:all) do
        @provides_one = Ohai.plugin { provides("thing") }
        @provides_list = Ohai.plugin { provides("thing", "something", "otherthing") }
        @provides_many = Ohai.plugin { provides("list", "something"); provides("somethingelse") }
      end

      it "should collect a single attribute" do
        @provides_one.provides_attrs.should eql(["thing"])
      end

      it "should collect a list of attributes" do
        @provides_list.provides_attrs.should eql(["thing", "something", "otherthing"])
      end

      it "should collect from multiple provides statements" do
        @provides_many.provides_attrs.should eql(["list", "something", "somethingelse"])
      end
    end

    describe "#self.depends_attrs" do
      before(:all) do
        @depends_none = Ohai.plugin { }
        @depends_one = Ohai.plugin { depends("other") }
        @depends_list = Ohai.plugin { depends("on", "list") }
        @depends_many = Ohai.plugin { depends("on", "list"); depends("single") }
      end

      it "should return an empty array if no dependencies" do
        @depends_none.depends_attrs.should be_empty
      end

      it "should collect a single dependency" do
        @depends_one.depends_attrs.should eql(["other"])
      end

      it "should collect a list of dependencies" do
        @depends_list.depends_attrs.should eql(["on", "list"])
      end

      it "should collect from multiple depends statements" do
        @depends_many.depends_attrs.should eql(["on", "list", "single"])
      end
    end

    describe "#self.depends_os" do
      before(:all) do
        Ohai::OS.stub(:collect_os).and_return("ubuntu")
        @depends_os = Ohai.plugin { depends_os("specific") }
      end

      it "should append the OS to the attribute" do
        @depends_os.depends_attrs.should eql(["ubuntu/specific"])
      end
    end

    describe "#self.collect_data" do
      before(:all) do
        @no_collect_data = Ohai.plugin { }
        @collect_data = Ohai.plugin { provides "math"; collect_data { math("is awesome") } }
      end

      it "should not define run_plugin if no collect data block exists" do
        @no_collect_data.method_defined?(:run_plugin).should be_false
      end

      it "should define run_plugin if a collect data block exists" do
        @collect_data.method_defined?(:run_plugin).should be_true
      end
    end

    it "should raise a NoMethodError when encountering \'require_plugin\'" do
      bad_plugin_string = <<EOF
Ohai.plugin do
  require_plugin "other"
end
EOF
      expect { eval(bad_plugin_string, TOPLEVEL_BINDING) }.to raise_error(NoMethodError)
    end
  end

  describe "when initialized" do
    before(:each) do
      @ohai = Ohai::System.new
      @source = "/tmp/plugins/simple.rb"
      @plugin = Ohai::DSL::Plugin::VersionVII.new(@ohai, @source)
    end

    it "should be a :version7 plugin" do
      @plugin.version.should eql(:version7)
    end

    it "should log a deprecation warning when calling require_plugin from collect_data" do
      bad_plugin_string = <<EOF
Ohai.plugin do
  provides "bad"
  collect_data do
    require_plugin "other"
  end
end
EOF
      klass = eval(bad_plugin_string, TOPLEVEL_BINDING)
      plugin = klass.new(@ohai, "/tmp/plugins/bad_plugin.rb")
      Ohai::Log.should_receive(:warn).with(/[UNSUPPORTED OPERATION]+\'require_plugin\'/)
      plugin.run
    end

    it "should log a deprecation warning when calling provides from collect_data" do
      bad_plugin_string = <<EOF
Ohai.plugin do
  collect_data do
    provides "bad"
  end
end
EOF
      klass = eval(bad_plugin_string, TOPLEVEL_BINDING)
      plugin = klass.new(@ohai, "/tmp/plugins/bad_plugin.rb")
      Ohai::Log.should_receive(:warn).with(/[UNSUPPORTED OPERATION]+\'provides\'/)
      plugin.run
    end

    it_behaves_like "Ohai::DSL::Plugin" do
      let(:ohai) { @ohai }
      let(:source) { @source }
      let(:plugin) { @plugin }
    end
  end
end

describe Ohai::DSL::Plugin::VersionVI do
  describe "when loaded" do
    before(:all) do
      @contents = <<EOF
provides "thing"
depends "otherthing"

thing "gets set"
end
EOF
    end

    it "should define run_plugin with contents string" do
      klass = Ohai.v6plugin { collect_contents(@contents) }
      klass.method_defined?(:run_plugin).should be_true
    end
  end

  describe "when initialized" do
    before(:each) do
      @ohai = Ohai::System.new
      @source = "/tmp/plugins/simple.rb"
      @plugin = Ohai::DSL::Plugin::VersionVI.new(@ohai, @source)
    end

    it "should be a :version6 plugin" do
      @plugin.version.should eql(:version6)
    end

    it_behaves_like "Ohai::DSL::Plugin" do
      let(:ohai) { @ohai }
      let(:source) { @source }
      let(:plugin) { @plugin }
    end
  end
end
