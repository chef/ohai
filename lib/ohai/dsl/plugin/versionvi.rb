#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Ohai
  module DSL
    class Plugin
      class VersionVI < Plugin
        attr_reader :version
        attr_reader :source

        def initialize(controller, plugin_path, plugin_dir_path)
          super(controller.data)
          @controller = controller
          @version = :version6
          @source = plugin_path
          @plugin_dir_path = plugin_dir_path
        end

        def name
          # Ohai V6 doesn't have any name specification for plugins.
          # So we are using the partial path to infer the name of the plugin
          partial_path = Pathname.new(@source).relative_path_from(Pathname.new(@plugin_dir_path)).to_s
          partial_path.chomp(".rb").gsub("/", "::")
        end

        def self.version
          :version6
        end

        def self.collect_contents(contents)
          define_method(:run_plugin) { self.instance_eval(contents) }
        end

        def provides(*paths)
          Ohai::Log.debug("Skipping provides '#{paths.join(",")}' for plugin '#{name}'")
        end

        def require_plugin(plugin_ref)
          @controller.require_plugin(plugin_ref)
        end

      end
    end
  end
end
