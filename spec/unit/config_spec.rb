#
# Author:: Claire McQuin (<claire@chef.io>)
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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

require_relative "../spec_helper"
require "ohai/config"

RSpec.describe Ohai::Config do

  describe "config_context :ohai" do
    describe "option :plugin" do
      it "gets configured with a value" do
        Ohai::Config.ohai[:plugin][:foo] = true
        expect(Ohai::Config.ohai[:plugin]).to have_key(:foo)
        expect(Ohai::Config.ohai[:plugin][:foo]).to be true
      end

      it "gets configured with a Hash" do
        value = { :bar => true, :baz => true }
        Ohai::Config.ohai[:plugin][:foo] = value
        expect(Ohai::Config.ohai[:plugin]).to have_key(:foo)
        expect(Ohai::Config.ohai[:plugin][:foo]).to eq(value)
      end

      it "raises an error if the plugin name is not a symbol" do
        expect { Ohai::Config.ohai[:plugin]["foo"] = false }.
          to raise_error(Ohai::Exceptions::PluginConfigError, /Expected Symbol/)
      end

      it "raises an error if the value Hash has non-Symbol key" do
        value = { :bar => true, "baz" => true }
        expect { Ohai::Config.ohai[:plugin][:foo] = value }.
          to raise_error(Ohai::Exceptions::PluginConfigError, /Expected Symbol/)
      end
    end
  end

  describe "Ohai.config" do
    it "returns the ohai config context" do
      expect(Ohai.config).to eq(Ohai::Config.ohai)
    end
  end
end
