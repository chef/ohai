#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Ohai::System, "initialize" do
  it "should return an Ohai::System object" do
    Ohai::System.new.should be_a_kind_of(Ohai::System)
  end

  it "should set @data to a Mash" do
    Ohai::System.new.data.should be_a_kind_of(Mash)
  end

  it "should set @seen_plugins to a Hash" do
    Ohai::System.new.seen_plugins.should be_a_kind_of(Hash)
  end
end

describe Ohai::System, "require_plugin" do
  tmp = ENV['TMPDIR'] || ENV['TMP'] || ENV['TEMP'] || '/tmp'

  before(:each) do
    @plugin_path = Ohai::Config[:plugin_path]
    Ohai::Config[:plugin_path] = [SPEC_PLUGIN_PATH]
    @ohai = Ohai::System.new
  end

  after(:each) do
    Ohai::Config[:plugin_path] = @plugin_path
  end

  it "should check each part of the Ohai::Config[:plugin_path] for the plugin_filename.rb" do
    plugin = @ohai.plugin_for("foo")
    plugin.file.should == File.expand_path("foo.rb", SPEC_PLUGIN_PATH)
  end

  it "should add a found plugin to the list of seen plugins" do
    @ohai.require_plugin("foo")
    @ohai.seen_plugins["foo"].should eql(true)
  end

  it "should return true if the plugin has been seen" do
    @ohai.seen_plugins["foo"] = true
    @ohai.require_plugin("foo")
  end

  it "should return true if the plugin has been loaded" do
    @ohai.require_plugin("foo").should eql(true)
  end

  it "should return false if the plugin is in the disabled plugins list" do
    Ohai::Config[:disabled_plugins] = [ "foo" ]
    Ohai::Log.should_receive(:debug).with("Skipping disabled plugin foo")
    @ohai.require_plugin("foo").should eql(false)
  end
end

describe Ohai::System, "all_plugins" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai.stub(:from_file).and_return(true)
    @ohai.stub(:require_plugin).and_return(false)
    @ohai.data[:os] = "ubuntu"
  end

  it "should load plugins when plugin_path has a trailing slash" do
    Ohai::Config[:plugin_path] = ["/tmp/plugins/"]
    File.stub(:expand_path).with("/tmp/plugins/").and_return("/tmp/plugins") # windows
    Dir.should_receive(:[]).with("/tmp/plugins/*").and_return(["/tmp/plugins/darius.rb"])
    Dir.should_receive(:[]).with("/tmp/plugins/ubuntu/**/*").and_return([])
    @ohai.should_receive(:require_plugin).with("darius")
    @ohai.all_plugins
  end
  
end
