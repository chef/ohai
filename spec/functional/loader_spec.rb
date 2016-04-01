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

RSpec.describe "Ohai::Loader" do
  let(:loader) { Ohai::Loader.new(Ohai::System.new) }

  describe "#load_all" do
    context "when the plugin path contains backslash characters", :windows_only do
      let(:plugin_directory) { Dir.mktmpdir("plugins") }
      let(:plugin_path) { plugin_directory.tr("/", "\\") }

      before(:each) do
        Ohai.config[:plugin_path] = plugin_path

        plugin_content = <<-EOF
Ohai.plugin(:Foo) do
  provides 'foo'
end
EOF
        File.open(File.join(plugin_directory, "foo.rb"), "w+") do |f|
          f.write(plugin_content)
        end
      end

      after(:each) do
        FileUtils.rm_rf(plugin_directory)
      end

      it "loads all the plugins" do
        loader.load_all
        loaded_plugins = loader.instance_variable_get(:@v7_plugin_classes)
        loaded_plugins_names = loaded_plugins.map { |plugin| plugin.name }
        expect(loaded_plugins_names).to eq(["Ohai::NamedPlugin::Foo"])
      end
    end
  end
end
