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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path("../../../spec_helper", __FILE__)
tmp = ENV['TMPDIR'] || ENV['TMP'] || ENV['TEMP'] || '/tmp'

shared_examples "Ohai::DSL::Plugin" do
  before(:each) do
    @ohai = ohai
    @plugin = instance.new(@ohai)
  end

  context "when accessing data via method_missing" do
    it "should take a missing method and store the method name as a key, with its arguments as values" do
      @plugin.guns_n_roses("chinese democracy")
      @plugin.data["guns_n_roses"].should eql("chinese democracy")
    end

    it "should return the current value of the method name" do
      @plugin.guns_n_roses("chinese democracy").should eql("chinese democracy")
    end

    it "should allow you to get the value of a key by calling method_missing with no arguments" do
      @plugin.guns_n_roses("chinese democracy")
      @plugin.guns_n_roses.should eql("chinese democracy")
    end
  end

  context "when checking attribute existence" do
    before(:each) do
      @plugin.metallica("death magnetic")
    end

    it "should return true if an attribute exists with the given name" do
      @plugin.attribute?("metallica").should eql(true)
    end

    it "should return false if an attribute does not exist with the given name" do
      @plugin.attribute?("alice in chains").should eql(false)
    end
  end

  context "when setting attributes" do
    it "should let you set an attribute" do
      @plugin.set_attribute(:tea, "is soothing")
      @plugin.data["tea"].should eql("is soothing")
    end
  end

  context "when getting attributes" do
    before(:each) do
      @plugin.set_attribute(:tea, "is soothing")
    end

    it "should let you get an attribute" do
      @plugin.get_attribute("tea").should eql("is soothing")
    end
  end
end

describe "VersionVII" do
  before(:all) do
    begin
      Dir.mkdir("#{tmp}/plugins")
    rescue Errno::EEXIST
      # ingore
    end
    v7plugin = File.open("#{tmp}/plugins/v7plugin.rb", "w+")
    v7plugin.write("Ohai.plugin do\n\tprovides \"version\"\n\tcollect_data do\n\t\tversion \"seven\"\n\tend\nend\n")
    v7plugin.close
  end

  after(:all) do
    File.delete("#{tmp}/plugins/v7plugin.rb")
    begin
      Dir.delete("#{tmp}/plugins")
    rescue
      # ignore
    end
  end

  before(:each) do
    @ohai = Ohai::System.new
    loader = Ohai::Loader.new(@ohai)
    @instance = loader.load_plugin("#{tmp}/plugins/v7plugin.rb")
  end

  context "after loading" do
    it "should have version :version7" do
      @instance.version.should eql(:version7)
    end

    it "should return which attributes it provides" do
      @instance.provides_attrs.should eql(["version"])
    end

    it "should return which attributes it depends on" do
      @instance.depends_attrs.should eql([])
    end
  end

  it_behaves_like "Ohai::DSL::Plugin" do
    let (:ohai) { @ohai }
    let (:instance) { @instance }
  end
end

describe "VersionVI" do
  before(:all) do
    begin
      Dir.mkdir("#{tmp}/plugins")
    rescue Errno::EEXIST
      # ingore
    end
    v6plugin = File.open("#{tmp}/plugins/v6plugin.rb", "w+")
    v6plugin.write("provides \"version\"\n\tversion \"six\"\nend\n")
    v6plugin.close
  end

  before(:each) do
    @ohai = Ohai::System.new
    loader = Ohai::Loader.new(@ohai)

    Ohai::Log.should_receive(:warn).with(/DEPRECATION/)
    @instance = loader.load_plugin("#{tmp}/plugins/v6plugin.rb")
  end

  after(:all) do
    File.delete("#{tmp}/plugins/v6plugin.rb")
    begin
      Dir.delete("#{tmp}/plugins")
    rescue
      # ignore
    end
  end

  context "after loading" do
    it "should have version :version6" do
      @instance.version.should eql(:version6)
    end

    it "should not have any attributes listed" do
      @ohai.attributes.should_not have_key("version")
    end
  end

  it_behaves_like "Ohai::DSL::Plugin" do
    let (:ohai) { @ohai }
    let (:instance) { @instance }
  end
end
