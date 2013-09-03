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
        @provides_one = <<EOF
Ohai.plugin do
  provides "thing"
end
EOF
        @provides_list = <<EOF
Ohai.plugin do
  provides "thing", "something", "otherthing"
end
EOF
        @provides_many = <<EOF
Ohai.plugin do
  provides "list", "something"
  provides "somethingelse"
end
EOF
      end

      it "should collect a single attribute" do
        klass = self.instance_eval(@provides_one)
        klass.provides_attrs.should eql(["thing"])
      end

      it "should collect a list of attributes" do
        klass = self.instance_eval(@provides_list)
        klass.provides_attrs.should eql(["thing", "something", "otherthing"])
      end

      it "should collect from multiple provides statements" do
        klass = self.instance_eval(@provides_many)
        klass.provides_attrs.should eql(["list", "something", "somethingelse"])
      end
    end

    describe "#self.depends_attrs" do
      before(:all) do
        @depends_none = <<EOF
Ohai.plugin do
end
EOF
        @depends_one = <<EOF
Ohai.plugin do
  depends "other"
end
EOF
        @depends_list = <<EOF
Ohai.plugin do
  depends "on", "list"
end
EOF
        @depends_many = <<EOF
Ohai.plugin do
  depends "on", "list"
  depends "single"
end
EOF
      end

      it "should return an empty array if no dependencies" do
        klass = self.instance_eval(@depends_none)
        klass.depends_attrs.should be_empty
      end

      it "should collect a single dependency" do
        klass = self.instance_eval(@depends_one)
        klass.depends_attrs.should eql(["other"])
      end

      it "should collect a list of dependencies" do
        klass = self.instance_eval(@depends_list)
        klass.depends_attrs.should eql(["on", "list"])
      end

      it "should collect from multiple depends statements" do
        klass = self.instance_eval(@depends_many)
        klass.depends_attrs.should eql(["on", "list", "single"])
      end
    end

    describe "#self.depends_os" do
      before(:all) do
        @depends_os = <<EOF
Ohai.plugin do
  depends_os "specific"
end
EOF
      end

      it "should append the OS to the attribute" do
        Ohai::OS.stub(:collect_os).and_return("ubuntu")
        klass = self.instance_eval(@depends_os)
        klass.depends_attrs.should eql(["ubuntu/specific"])
      end
    end

    describe "#self.collect_data" do
      before(:all) do
        @no_collect_data = <<EOF
Ohai.plugin do
end
EOF
        @collect_data = <<EOF
Ohai.plugin do
  provides "math"
  collect_data do
    math "is awesome"
  end
end
EOF
      end

      it "should not define run_plugin if no collect data block exists" do
        klass = self.instance_eval(@no_collect_data)
        klass.method_defined?(:run_plugin).should be_false
      end

      it "should define run_plugin if a collect data block exists" do
        klass = self.instance_eval(@collect_data)
        klass.method_defined?(:run_plugin).should be_true
      end
    end

    it "should raise a NoMethodError when encountering \'require_plugin\'" do
      bad_plugin_string = <<EOF
Ohai.plugin do
  require_plugin "other"
end
EOF
      expect { self.instance_eval(bad_plugin_string) }.to raise_error(NoMethodError)
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
      klass = self.instance_eval(bad_plugin_string)
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
      klass = self.instance_eval(bad_plugin_string)
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
