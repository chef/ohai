#
#
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
    end

    def load_plugin(plugin_path, plugin_name=nil)
      plugin = nil
      
      plugin = from_file(plugin_path)
      if plugin.nil?
        Ohai::Log.debug("Unable to load plugin at #{plugin_path}")
        return
      end

      plugin_key = plugin_name || plugin.name
      register_plugin(plugin, plugin_path, plugin_key)
      collect_provides(plugin, plugin_key)
    end

    private

    def register_plugin(plugin, file, plugin_key)
      @plugins[plugin_key] ||= Mash.new

      p = @plugins[plugin_key]
      p[:plugin] = plugin
      p[:source] = file
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

        a[:_providers] ||= []
        a[:_providers] << plugin_key
      end
    end

  end
end
