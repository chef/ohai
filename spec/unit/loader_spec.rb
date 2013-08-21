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

describe "Ohai::Loader" do
  before(:all) do
    @plugin_path = File.expand_path('../../data/plugins', __FILE__)
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

  describe "when loading v7 plugins" do
    context "should collect provides" do
      it "for a single attribute" do
        plugin = @loader.load_plugin(File.expand_path("loader/easy.rb", @plugin_path))
        plugin.provides_attrs.should eql(["easy"])
      end

      it "for an array of attributes" do
        plugin = @loader.load_plugin(File.expand_path("loader/medium.rb", @plugin_path))
        plugin.provides_attrs.sort.should eql(["medium", "medium/hard"].sort)
      end

      it "for all provided attributes" do
        plugin = @loader.load_plugin(File.expand_path("loader/hard.rb", @plugin_path))
        plugin.provides_attrs.sort.should eql(["this", "plugin", "provides", "a/lot", "of", "attributes"].sort)
      end
    end

    context "should collect depends" do
      it "if no dependencies" do
        plugin = @loader.load_plugin(File.expand_path("loader/easy.rb", @plugin_path))
        plugin.depends_attrs.should eql([])
      end

      it "for a single dependency" do
        plugin = @loader.load_plugin(File.expand_path("loader/medium.rb", @plugin_path))
        plugin.depends_attrs.should eql(["easy"])
      end

      it "for all attributes it depends on" do
        plugin = @loader.load_plugin(File.expand_path("loader/hard.rb", @plugin_path))
        plugin.depends_attrs.sort.should eql(["it/also", "depends", "on/a", "lot", "of", "other/attributes"].sort)
      end
    end

    it "should save the plugin an attribute is defined in" do
      plugin = @loader.load_plugin(File.expand_path("loader/easy.rb", @plugin_path))
      @ohai.attributes["easy"]["providers"].should eql([plugin])
    end
  end

  context "when loading v6 plugins" do
    it "should not include provided attributes" do
      @loader.load_plugin(File.expand_path("v6/languages.rb", @plugin_path))
      @ohai.attributes.has_key?(:languages).should be_false
    end
  end

  it "should load both v6 and v7 plugins" do
    path = File.expand_path(File.dirname(__FILE__) + '/../data/plugins/mix')
    Ohai::Config[:plugin_path] = [path]
    @ohai.load_plugins
    @ohai.v6_dependency_solver.keys.sort.should eql(Dir[File.join(path, '*')].sort)
  end  
end
