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

require 'ohai/log'
require 'ohai/mash'
require 'ohai/dsl'

module Ohai
  class Loader

    def initialize(controller)
      @controller = controller
    end

    def load_plugin(plugin_path)
      plugin = nil

      # Read the contents of the plugin to understand if it's a V6 or V7 plugin.
      contents = ""
      begin
        contents << IO.read(plugin_path)
      rescue IOError, Errno::ENOENT
        Ohai::Log.warn("Unable to open or read plugin at #{plugin_path}")
        return plugin
      end

      # We assume that a plugin is a V7 plugin if it contains Ohai.plugin in its contents.
      if contents.include?("Ohai.plugin")
        plugin = load_v7_plugin(contents, plugin_path)
      else
        Ohai::Log.warn("[DEPRECATION] Plugin at #{plugin_path} is a version 6 plugin. \
Version 6 plugins will not be supported in future releases of Ohai. \
Please upgrade your plugin to version 7 plugin syntax. \
For more information visit here: docs.opscode.com/ohai_custom.html")

        plugin = load_v6_plugin(contents, plugin_path)
      end

      plugin
    end

    private

    def collect_provides(plugin)
      plugin_provides = plugin.class.provides_attrs
      @controller.provides_map.set_providers_for(plugin, plugin_provides)
    end

    def load_v6_plugin(contents, plugin_path)
      klass = Class.new(Ohai::DSL::Plugin::VersionVI) { collect_contents(contents) }
      klass.new(@controller, plugin_path)
    end

    def load_v7_plugin(contents, plugin_path)
      plugin = nil

      begin
        klass = eval(contents, TOPLEVEL_BINDING)
        plugin = klass.new(@controller.data) unless klass.nil?
      rescue SystemExit, Interrupt
        raise
      rescue Ohai::Exceptions::IllegalPluginDefinition => e 
        Ohai::Log.warn("Plugin at #{plugin_path} is not properly defined: #{e.inspect}")
      rescue NoMethodError => e
        Ohai::Log.warn("[UNSUPPORTED OPERATION] Plugin at #{plugin_path} used unsupported operation \'#{e.name.to_s}\'")
      rescue SyntaxError => e
        # grab the part of the error message that follows "<main>:line#: syntax error"
        # example: "<main>:3: syntax error, unexpected $end, expecting keyword_end" 
        # regex will grab ", unexpected $end, expecting keyword_end"
        message_regex = /(,[^,]+)+$/
        message = message_regex.match(e.message)[0]
        Ohai::Log.warn("Plugin at #{plugin_path} threw syntax error#{message}")
      rescue Exception, Errno::ENOENT => e
        Ohai::Log.warn("Plugin at #{plugin_path} threw exception #{e.inspect} #{e.backtrace.join("\n")}")
      end

      collect_provides(plugin) unless plugin.nil?

      plugin
    end

  end
end
