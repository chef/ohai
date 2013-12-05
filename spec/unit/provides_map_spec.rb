#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License. You may
# obtain a copy of the license at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either expressed or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Ohai::ProvidesMap do

  let(:ohai_system) { Ohai::System.new }
  let(:provides_map) { Ohai::ProvidesMap.new }
  let(:plugin_1) { Ohai::DSL::Plugin.new(ohai_system, "") }
  let(:plugin_2) { Ohai::DSL::Plugin.new(ohai_system, "") }
  let(:plugin_3) { Ohai::DSL::Plugin.new(ohai_system, "") }
  let(:plugin_4) { Ohai::DSL::Plugin.new(ohai_system, "") }

  describe "when looking up providing plugins for a single attribute" do
    describe "when only one plugin provides the attribute" do
      before do
        provides_map.set_providers_for(plugin_1, ["single"])
      end

      it "should return the provider" do
        expect(provides_map.find_providers_for(["single"])).to eq([plugin_1])
      end
    end

    describe "when multiple plugins provide the attribute" do
      before do
        provides_map.set_providers_for(plugin_1, ["single"])
        provides_map.set_providers_for(plugin_2, ["single"])
      end

      it "should return all providers" do
        expect(provides_map.find_providers_for(["single"])).to eq([plugin_1, plugin_2])
      end
    end
  end

  describe "when looking up providing plugins for multiple attributes" do
    describe "when a different plugin provides each attribute" do

      before do
        provides_map.set_providers_for(plugin_1, ["one"])
        provides_map.set_providers_for(plugin_2, ["two"])
      end

      it "should return each provider" do
        expect(provides_map.find_providers_for(["one", "two"])).to eq([plugin_1, plugin_2])
      end
    end

    describe "when one plugin provides both requested attributes" do

      before do
        provides_map.set_providers_for(plugin_1, ["one"])
        provides_map.set_providers_for(plugin_1, ["one_again"])
      end

      it "should return unique providers" do
        expect(provides_map.find_providers_for(["one", "one_again"])).to eq([plugin_1])
      end
    end
  end

  describe "when looking up providers for multi-level attributes" do
    before do
      provides_map.set_providers_for(plugin_1, ["top/middle/bottom"])
    end

    it "should collect the provider" do
      expect(provides_map.find_providers_for(["top/middle/bottom"])).to eq([plugin_1])
    end
  end

  describe "when listing all plugins" do
    before(:each) do
      provides_map.set_providers_for(plugin_1, ["one"])
      provides_map.set_providers_for(plugin_2, ["two"])
      provides_map.set_providers_for(plugin_3, ["stub/three"])
      provides_map.set_providers_for(plugin_4, ["foo/bar/four", "also/this/four"])
    end

    it "should find all the plugins providing attributes" do

      all_plugins = provides_map.all_plugins
      expect(all_plugins).to have(4).plugins
      expect(all_plugins).to include(plugin_1)
      expect(all_plugins).to include(plugin_2)
      expect(all_plugins).to include(plugin_3)
      expect(all_plugins).to include(plugin_4)
    end
  end

end

