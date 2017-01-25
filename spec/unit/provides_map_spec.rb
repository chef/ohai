#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

require_relative "../spec_helper.rb"

describe Ohai::ProvidesMap do

  let(:ohai_system) { Ohai::System.new }
  let(:provides_map) { Ohai::ProvidesMap.new }
  let(:plugin_1) { Ohai::DSL::Plugin.new(ohai_system.data) }
  let(:plugin_2) { Ohai::DSL::Plugin.new(ohai_system.data) }
  let(:plugin_3) { Ohai::DSL::Plugin.new(ohai_system.data) }
  let(:plugin_4) { Ohai::DSL::Plugin.new(ohai_system.data) }

  describe "when looking up providing plugins for a single attribute" do
    describe "when the attribute does not exist" do
      it "should raise Ohai::Exceptions::AttributeNotFound error" do
        expect { provides_map.find_providers_for(["single"]) }.to raise_error(Ohai::Exceptions::AttributeNotFound, "No such attribute: 'single'")
      end
    end

    describe "when the attribute does not have a provider" do
      it "should raise Ohai::Exceptions::ProviderNotFound error" do
        provides_map.set_providers_for(plugin_1, ["first/second"])
        expect { provides_map.find_providers_for(["first"]) }.to raise_error(Ohai::Exceptions::ProviderNotFound, "Cannot find plugin providing attribute: 'first'")
      end
    end

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
        expect(provides_map.find_providers_for(%w{one two})).to eq([plugin_1, plugin_2])
      end
    end

    describe "when one plugin provides both requested attributes" do

      before do
        provides_map.set_providers_for(plugin_1, ["one"])
        provides_map.set_providers_for(plugin_1, ["one_again"])
      end

      it "should return unique providers" do
        expect(provides_map.find_providers_for(%w{one one_again})).to eq([plugin_1])
      end
    end
  end

  describe "when looking up providers for multi-level attributes" do
    describe "when the full attribute exists in the map" do
      before do
        provides_map.set_providers_for(plugin_1, ["top/middle/bottom"])
      end

      it "should collect the provider" do
        expect(provides_map.find_providers_for(["top/middle/bottom"])).to eq([plugin_1])
      end
    end
  end

  describe "when setting multi-level attributes" do
    describe "when the attribute contains //" do
      it "should raise an Ohai::Exceptions::AttributeSyntaxError" do
        expect { provides_map.set_providers_for(plugin_1, ["this/plugin//is/bad"]) }.to raise_error(Ohai::Exceptions::AttributeSyntaxError, "Attribute contains duplicate '/' characters: this/plugin//is/bad")
      end
    end

    describe "when the attribute has a trailing slash" do
      it "should raise an Ohai::Exceptions::AttributeSyntaxError" do
        expect { provides_map.set_providers_for(plugin_1, ["this/plugin/is/bad/"]) }.to raise_error(Ohai::Exceptions::AttributeSyntaxError, "Attribute contains a trailing '/': this/plugin/is/bad/")
      end
    end
  end

  describe "when looking for providers of attributes specified in CLI" do
    before do
      provides_map.set_providers_for(plugin_1, ["cat/whiskers"])
      provides_map.set_providers_for(plugin_2, ["cat/paws", "cat/paws/toes"])
      provides_map.set_providers_for(plugin_3, ["cat/mouth/teeth"])
    end

    it "should find providers for subattributes if any exists when the attribute doesn't have a provider" do
      providers = provides_map.deep_find_providers_for(["cat"])
      expect(providers).to have(3).plugins
      expect(providers).to include(plugin_1)
      expect(providers).to include(plugin_2)
      expect(providers).to include(plugin_3)
    end

    it "should find providers for the first parent attribute when the attribute or any subattributes doesn't have a provider" do
      providers = provides_map.deep_find_providers_for(["cat/paws/front"])
      expect(providers).to eq([plugin_2])
    end
  end

  describe "when looking for the closest providers" do
    describe "and the full attribute is provided" do
      before do
        provides_map.set_providers_for(plugin_1, ["do/not/eat/metal"])
      end

      it "should return the provider of the full attribute" do
        expect(provides_map.find_closest_providers_for(["do/not/eat/metal"])).to eql([plugin_1])
      end
    end

    describe "and the full attribute is not provided" do
      before do
        provides_map.set_providers_for(plugin_1, ["do/not/eat"])
      end

      it "should not raise error if a parent attribute is provided" do
        expect { provides_map.find_closest_providers_for(["do/not/eat/plastic"]) }.not_to raise_error
      end

      it "should return the providers of the closest parent attribute" do
        provides_map.set_providers_for(plugin_2, ["do/not"]) # set a less-specific parent
        expect(provides_map.find_closest_providers_for(["do/not/eat/glass"])).to eql([plugin_1])
      end

      it "should raise error if the least-specific parent is not an attribute" do
        expect { provides_map.find_closest_providers_for(["please/eat/your/vegetables"]) }.to raise_error(Ohai::Exceptions::AttributeNotFound, "No such attribute: 'please/eat/your/vegetables'")
      end

      it "should raise error if no parent attribute has a provider" do
        expect { provides_map.find_closest_providers_for(["do/not"]) }.to raise_error(Ohai::Exceptions::ProviderNotFound, "Cannot find plugin providing attribute: 'do/not'")
      end
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

    describe "with an attribute filter" do
      it "finds plugins with a single level of attribute" do
        expect(provides_map.all_plugins("one")).to eq([plugin_1])
      end

      it "finds plugins with an exact match for multiple levels of attribute" do
        expect(provides_map.all_plugins("stub/three")).to eq([plugin_3])
      end

      it "finds plugins that provide subattributes of the requested path" do
        expect(provides_map.all_plugins("stub")).to eq([plugin_3])
        expect(provides_map.all_plugins("foo/bar")).to eq([plugin_4])
      end
    end
  end

end
