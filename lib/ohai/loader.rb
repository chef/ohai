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
require 'ohai/mixin/from_file'

module Ohai
  class Loader
    include Ohai::Mixin::FromFile

    def initialize(controller)
      @attributes = controller.attributes
      @v6_dependency_solver = controller.v6_dependency_solver
    end

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
          plugin = self.instance_eval(contents, plugin_path, 1)
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
        Ohai::Log.warn("[DEPRECATION] Plugin at #{plugin_path} is a version 6 plugin. Version 6 plugins will not be supported in future releases of Ohai. Please upgrage your plugin to version 7 plugin syntax. For more information visit here: XXX")
        plugin = Ohai.v6plugin do collect_contents contents end
        if plugin.nil?
          Ohai::Log.warn("Unable to load plugin at #{plugin_path}")
          return plugin
        end
      end

      @v6_dependency_solver[plugin_path] = plugin
      plugin
    end

    private

    def collect_provides(plugin)
      plugin_provides = plugin.provides_attrs
      
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
