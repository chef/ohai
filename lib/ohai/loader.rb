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
require 'ohai/dsl/plugin'

module Ohai
  class Loader

    def initialize(controller)
      @controller = controller
      @attributes = controller.attributes
    end

    # @note: plugin_name is used only by version 6 plugins and is the
    # unique part of the file name from Ohai::Config[:plugin_path]
    def load_plugin(plugin_path, plugin_name=nil)
      plugin = nil

      contents = ""
      begin
        contents << IO.read(plugin_path)
      rescue IOError, Errno::ENOENT
        Ohai::Log.warn("Unable to open or read plugin at #{plugin_path}")
        return plugin
      end

      if contents.include?("Ohai.plugin")
        begin
          klass = eval(contents, TOPLEVEL_BINDING)
          plugin = klass.new(@controller, plugin_path) unless klass.nil?
        rescue SystemExit, Interrupt
          raise
        rescue NoMethodError => e
          Ohai::Log.warn("[UNSUPPORTED OPERATION] Plugin at #{plugin_path} used unsupported operation \'#{e.name.to_s}\'")
        rescue Exception, Errno::ENOENT => e
          Ohai::Log.warn("Plugin at #{plugin_path} threw exception #{e.inspect} #{e.backtrace.join("\n")}")
        end

        return plugin if plugin.nil?
        collect_provides(plugin)
      else
        Ohai::Log.warn("[DEPRECATION] Plugin at #{plugin_path} is a version 6 plugin. Version 6 plugins will not be supported in future releases of Ohai. Please upgrage your plugin to version 7 plugin syntax. For more information visit here: docs.opscode.com/ohai_custom.html")
        klass = Ohai.v6plugin(plugin_name) { collect_contents(contents) }
        plugin = klass.new(@controller, plugin_path)
      end

      plugin
    end

    def collect_provides(plugin)
      plugin_provides = plugin.class.provides_attrs
      
      plugin_provides.each do |attr|
        parts = attr.split('/')
        a = @attributes
        unless parts.length == 0
          parts.shift if parts[0].length == 0
          parts.each do |part|
            a[part] ||= Mash.new
            a = a[part]
          end
        end

        a[:providers] ||= []
        a[:providers] << plugin
      end
    end

  end
end
