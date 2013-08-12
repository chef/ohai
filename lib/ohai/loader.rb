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
      @plugins = controller.plugins
      @sources = controller.sources
    end

    def load_plugin(plugin_path, plugin_name=nil)
      clean_up(plugin_path) if @sources.has_key?(plugin_path)
      
      plugin = nil

      begin
        plugin = from_file(plugin_path)
      rescue SystemExit, Interrupt
        raise
      rescue Exception, Errno::ENOENT => e
        Ohai::Log.debug("Plugin #{plugin_name} threw exception #{e.inspect} #{e.backtrace.join("\n")}")
        return
      end

      if plugin.nil?
        Ohai::Log.debug("Unable to load plugin at #{plugin_path}")
        return
      end

      plugin_key = plugin_name || plugin.name 
      register_plugin(plugin, plugin_path, plugin_key)
      collect_provides(plugin, plugin_key)
    end

    private

    def clean_up(file)
      key = @sources[file]
      @plugins[key][:provides].each do |attr|
        @attributes[attr][:providers].delete(key)
      end

      @plugins.delete(key)
      @sources.delete(file)
    end

    def register_plugin(plugin, file, plugin_key)
      @plugins[plugin_key] ||= Mash.new
      @sources[file] = plugin_key

      p = @plugins[plugin_key]
      p[:plugin] = plugin
      p[:provides] = plugin.provides_attrs
      p[:depends] = plugin.depends_attrs
    end
    

    def collect_provides(plugin, plugin_key)
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
        a[:providers] << plugin_key
      end
    end

  end
end
