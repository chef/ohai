#
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
require "ohai/plugin_config"

describe "Ohai::PluginConfig" do

  describe "#[]=" do

    let(:plugin_config) { Ohai::PluginConfig.new }

    shared_examples_for "success" do

      it "sets the value" do
        plugin_config[key] = value
        expect(plugin_config).to have_key(key)
        expect(plugin_config[key]).to eq(value)
      end

    end

    shared_examples_for "failure" do

      it "raises an error" do
        expect { plugin_config[key] = value }.
          to raise_error(Ohai::Exceptions::PluginConfigError, /Expected Symbol/)
      end

    end

    describe "when the key is a Symbol" do

      let(:key) { :foo }

      describe "when the value is a Hash" do

        describe "when all Hash keys are symbols" do

          let(:value) do
            {
              :bar0 => true,
              :bar1 => [ :baz0, :baz1, :baz2 ],
              :bar2 => { :qux0 => true, :qux1 => false },
            }
          end

          include_examples "success"

        end

        describe "when some top-level Hash key is not a symbol" do

          let(:value) do
            {
              :bar0 => true,
              "bar1" => [ :baz0, :baz1, :baz2 ],
              :bar2 => { :qux0 => true, :qux1 => false },
            }
          end

          include_examples "failure"

        end

        describe "when some nested Hash key is not a symbol" do

          let(:value) do
            {
              :bar0 => true,
              :bar1 => [ :baz0, :baz1, :baz2 ],
              :bar2 => { :qux0 => true, "qux1" => false },
            }
          end

          include_examples "failure"

        end

      end

      describe "when the value is not a Hash" do

        let(:value) { true }

        include_examples "success"

      end

    end

    describe "when the key is not a Symbol" do

      let(:key) { "foo" }
      let(:value) { false }

      include_examples "failure"

    end

  end

end
