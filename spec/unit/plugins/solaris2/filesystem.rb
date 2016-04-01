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

require_relative "../../../spec_helper"

describe Ohai::System, "Solaris2.X filesystem plugin" do
  let(:plugin) { get_plugin("solaris2/filesystem") }

  before(:each) do
    allow(plugin).to receive(:collect_os).and_return("solaris2")
  end

  describe "filesystem properties" do
    let(:plugin_config) { {} }

    before(:each) do
      @original_plugin_config = Ohai.config[:plugin]
      Ohai.config[:plugin] = plugin_config
      allow(plugin).to receive(:shell_out).with("df -Pka").and_return(mock_shell_out(0, "", ""))
      allow(plugin).to receive(:shell_out).with("df -na").and_return(mock_shell_out(0, "", ""))
      allow(plugin).to receive(:shell_out).with("mount").and_return(mock_shell_out(0, "", ""))
    end

    after(:each) do
      Ohai.config[:plugin] = @original_plugin_config
    end

    context "when 'zfs get' properties are not configured" do
      it "collects all filesystem properties" do
        expect(plugin).to receive(:shell_out).
          with("zfs get -p -H all").
          and_return(mock_shell_out(0, "", ""))
        plugin.run
      end
    end

    context "when 'zfs get' properties are configured" do
      shared_examples_for "configured zfs properties" do
        let(:plugin_config) do
          {
            :filesystem => {
              :zfs_properties => zfs_properties,
            },
          }
        end

        it "collects configured filesystem properties" do
          expect(plugin).to receive(:shell_out).
            with("zfs get -p -H #{expected_cmd}").
            and_return(mock_shell_out(0, "", ""))
          plugin.run
        end
      end

      context "as a String" do
        include_examples "configured zfs properties" do
          let(:zfs_properties) { "mountpoint,creation,available,used" }
          let(:expected_cmd) { "mountpoint,creation,available,used" }
        end
      end

      context "as an Array" do
        include_examples "configured zfs properties" do
          let(:zfs_properties) { %w{mountpoint creation available used} }
          let(:expected_cmd) { "mountpoint,creation,available,used" }
        end
      end
    end
  end
end
