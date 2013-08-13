#
# Author:: Claire McQuin (<claire@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

describe Ohai::Loader do
  before(:all) do
    @plugin_path = File.expand_path("../../data/plugins/loader", __FILE__)
  end

  before(:each) do
    @ohai = Ohai::System.new
    @loader = Ohai::Loader.new(@ohai)
  end

  context "initialize" do  
    it "should return an Ohai::Loader object" do
      @loader.should be_a_kind_of(Ohai::Loader)
    end
  end

  context "when loading a plugin" do
    it "should add the plugin class to Ohai::System's @plugins" do
      @loader.load_plugin(File.expand_path("easy.rb", @plugin_path), "easy")
      @ohai.plugins.has_key?(:easy).should be_true
    end

    it "should save the plugin source file" do
      @loader.load_plugin(File.expand_path("easy.rb", @plugin_path), "easy")
      @ohai.sources.has_key?(File.expand_path("easy.rb", @plugin_path)).should be_true
    end

    context "should collect provides" do
      it "for a single attribute" do
        @loader.load_plugin(File.expand_path("easy.rb", @plugin_path), "easy")
        @ohai.plugins[:easy][:plugin].provides_attrs.should eql(["easy"])
      end

      it "for an array of attributes" do
        @loader.load_plugin(File.expand_path("medium.rb", @plugin_path), "medium")
        @ohai.plugins[:medium][:plugin].provides_attrs.sort.should eql(["medium", "medium/hard"].sort)
      end

      it "for all provided attributes" do
        @loader.load_plugin(File.expand_path("hard.rb", @plugin_path), "hard")
        @ohai.plugins[:hard][:plugin].provides_attrs.sort.should eql(["this", "plugin", "provides", "a/lot", "of", "attributes"].sort)
      end
    end

    context "should collect depends" do
      it "if no dependencies" do
        @loader.load_plugin(File.expand_path("easy.rb", @plugin_path), "easy")
        @ohai.plugins[:easy][:depends].should eql([])
      end

      it "for a single dependency" do
        @loader.load_plugin(File.expand_path("medium.rb", @plugin_path), "medium")
        @ohai.plugins[:medium][:depends].should eql(["easy"])
      end

      it "for all attributes it depends on" do
        @loader.load_plugin(File.expand_path("hard.rb", @plugin_path), "hard")
        @ohai.plugins[:hard][:depends].sort.should eql(["it/also", "depends", "on/a", "lot", "of", "other/attributes"].sort)
      end
    end

    it "should save the plugin an attribute is defined in" do
      @loader.load_plugin(File.expand_path("easy.rb", @plugin_path), "easy")
      @ohai.attributes["easy"]["providers"].should eql(["easy"])
    end
  end
end
