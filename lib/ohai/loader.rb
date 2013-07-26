#
#
#

require 'ohai/mash'
require 'ohai/dsl/plugin'
require 'ohai/mixin/from_file'

module Ohai
  class Loader
    include Ohai::Mixin::FromFile

    def initialize(controller)
      @metadata = controller.metadata
      @loaded_plugins = controller.loaded_plugins
    end

    def load_plugin(plugin_name)
      filename = "#{plugin_name.gsub("::", File::SEPARATOR)}.rb"
      plugin = nil

      # @todo: what to do with plugins found on multiple paths?
      # currently assumes one path per plugin (or, last loaded plugin
      # gets saved)
      Ohai::Config[:plugin_path].each do |path|
        check_path = File.expand_path(File.join(path, filename))
        if File.exist?(check_path)
          plugin = from_file(check_path)
          collect_metadata(plugin_name, check_path, plugin)
        end
      end

      # @todo: some better error handling here
      if plugin.nil?
        puts "Unable to load plugin #{plugin_name}!"
      else
        @loaded_plugins[plugin_name] = plugin
      end
    end

    private

    def collect_metadata(plugin_name, file, plugin)
      collect_provides(plugin_name, file, plugin.provides_attrs)
      # @todo: collect depends data and fill in to metadata
    end

    def collect_provides(plugin_name, file, attrs)
      attrs.each do |attr|
        parts = attr.split('/')
        m = @metadata
        unless parts.length == 0
          parts.shift if parts[0].length == 0
          parts.each do |part|
            m[part] ||= Mash.new
            m = m[part]
          end
        end

        %w{ _providers _plugin_name }.each do |key|
          m[key] ||= []
        end

        m[:_providers] << file
        m[:_plugin_name] << plugin_name
      end
    end

  end
end
