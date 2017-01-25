#
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

require "tmpdir"

module IntegrationSupport
  def when_plugins_directory(description, &block)
    context "When the plugins directory #{description}" do

      before(:each) do
        @plugins_directory = Dir.mktmpdir("ohai-plugins")
      end

      after(:each) do
        if @plugins_directory
          begin
            FileUtils.remove_entry_secure(@plugins_directory)
          ensure
            @plugins_directory = nil
          end
        end
      end

      def with_plugin(plugin_path, contents) # rubocop:disable Lint/NestedMethodDefinition
        filename = path_to(plugin_path)
        dir = File.dirname(filename)
        FileUtils.mkdir_p(dir) unless dir == "."
        File.open(filename, "w") do |file|
          file.write(contents)
        end
      end

      def path_to(plugin_path) # rubocop:disable Lint/NestedMethodDefinition
        File.expand_path(plugin_path, @plugins_directory)
      end

      def self.with_plugin(plugin_path, contents) # rubocop:disable Lint/NestedMethodDefinition
        before :each do
          with_plugin(plugin_path, contents)
        end
      end

      instance_eval(&block)
    end
  end

end
