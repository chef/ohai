#
# Author:: Claire McQuin (<claire@chef.io>)
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "chef-config/path_helper"
require "ohai/log"
require "ohai/mash"
require "ohai/dsl"
require "pathname"

module Ohai

  # Ohai plugin loader. Finds all the plugins in your
  # `Ohai.config[:plugin_path]` (supports a single or multiple path setting
  # here), evaluates them and returns plugin objects.
  class Loader

    # Simple struct like objects to track the path of a plugin and the root
    # directory of plugins in which we found it. We don't care about the
    # relative paths of v7 plugins, but in v6 plugins, dependencies are
    # specified by calling `require_plugin` with a relative path. To manage
    # this, we track the path and root of each file as we discover them so we
    # can feed this into the v6 "dependency solver" as we load them.
    PluginFile = Struct.new(:path, :plugin_root) do

      # Finds all the *.rb files under the configured paths in :plugin_path
      def self.find_all_in(plugin_dir)
        unless Dir.exist?(plugin_dir)
          Ohai::Log.info("The plugin path #{plugin_dir} does not exist. Skipping...")
          return []
        end

        Ohai::Log.debug("Searching for Ohai plugins in #{plugin_dir}")

        # escape_glob_dir does not exist in 12.7 or below
        if ChefConfig::PathHelper.respond_to?(:escape_glob_dir)
          escaped = ChefConfig::PathHelper.escape_glob_dir(plugin_dir)
        else
          escaped = ChefConfig::PathHelper.escape_glob(plugin_dir)
        end
        Dir[File.join(escaped, "**", "*.rb")].map do |file|
          new(file, plugin_dir)
        end
      end
    end

    # Simple struct to track a v6 plugin's class, file path, and the root of
    # the plugin dir from which it was loaded.
    V6PluginClass = Struct.new(:plugin_class, :plugin_path, :plugin_dir_path)

    def initialize(controller)
      @controller = controller
      @v6_plugin_classes = []
      @v7_plugin_classes = []
    end

    # Searches all plugin paths and returns an Array of PluginFile objects
    # representing each plugin file.
    def plugin_files_by_dir(dir = Ohai.config[:plugin_path])
      Array(dir).inject([]) do |plugin_files, plugin_path|
        plugin_files + PluginFile.find_all_in(plugin_path)
      end
    end

    def load_all
      plugin_files_by_dir.each do |plugin_file|
        load_plugin_class(plugin_file.path, plugin_file.plugin_root)
      end

      collect_v6_plugins
      collect_v7_plugins
    end

    def load_additional(from)
      from = [ Ohai.config[:plugin_path], from].flatten
      plugin_files_by_dir(from).collect do |plugin_file|
        Ohai::Log.debug "Loading additional plugin: #{plugin_file}"
        plugin = load_plugin_class(plugin_file.path, plugin_file.plugin_root)
        load_v7_plugin(plugin)
      end
    end

    # Load a specified file as an ohai plugin and creates an instance of it.
    # Not used by ohai itself, but can be used to load a plugin for testing
    # purposes.
    # plugin_dir_path is required when loading a v6 plugin.
    def load_plugin(plugin_path, plugin_dir_path = nil)
      plugin_class = load_plugin_class(plugin_path, plugin_dir_path)
      return nil unless plugin_class.kind_of?(Class)
      case
      when plugin_class < Ohai::DSL::Plugin::VersionVI
        load_v6_plugin(plugin_class, plugin_path, plugin_dir_path)
      when plugin_class < Ohai::DSL::Plugin::VersionVII
        load_v7_plugin(plugin_class)
      else
        raise Exceptions::IllegalPluginDefinition, "cannot create plugin of type #{plugin_class}"
      end
    end

    # Reads the file specified by `plugin_path` and returns a class object for
    # the ohai plugin defined therein.
    #
    # If `plugin_dir_path` is given, and the file at `plugin_path` is a v6
    # plugin, the 'relative path' of the plugin (used by `require_plugin()`) is
    # computed by finding the relative path from `plugin_dir_path` to `plugin_path`
    def load_plugin_class(plugin_path, plugin_dir_path = nil)
      # Read the contents of the plugin to understand if it's a V6 or V7 plugin.
      contents = ""
      begin
        Ohai::Log.debug("Loading plugin at #{plugin_path}")
        contents << IO.read(plugin_path)
      rescue IOError, Errno::ENOENT
        Ohai::Log.warn("Unable to open or read plugin at #{plugin_path}")
        return nil
      end

      # We assume that a plugin is a V7 plugin if it contains Ohai.plugin in its contents.
      if contents.include?("Ohai.plugin")
        load_v7_plugin_class(contents, plugin_path)
      else
        Ohai::Log.warn("[DEPRECATION] Plugin at #{plugin_path} is a version 6 plugin. \
Version 6 plugins will not be supported in Chef/Ohai 14. \
Please upgrade your plugin to version 7 plugin format. \
For more information visit here: docs.chef.io/ohai_custom.html")

        load_v6_plugin_class(contents, plugin_path, plugin_dir_path)
      end
    end

    private

    def collect_provides(plugin)
      plugin_provides = plugin.class.provides_attrs
      @controller.provides_map.set_providers_for(plugin, plugin_provides)
    end

    def v6_dependency_solver
      @controller.v6_dependency_solver
    end

    def collect_v6_plugins
      @v6_plugin_classes.each do |plugin_spec|
        plugin = load_v6_plugin(plugin_spec.plugin_class, plugin_spec.plugin_path, plugin_spec.plugin_dir_path)
        loaded_v6_plugin(plugin, plugin_spec.plugin_path, plugin_spec.plugin_dir_path)
      end
    end

    def collect_v7_plugins
      @v7_plugin_classes.each do |plugin_class|
        load_v7_plugin(plugin_class)
      end
    end

    def load_v6_plugin_class(contents, plugin_path, plugin_dir_path)
      plugin_class = Class.new(Ohai::DSL::Plugin::VersionVI) { collect_contents(contents) }
      @v6_plugin_classes << V6PluginClass.new(plugin_class, plugin_path, plugin_dir_path)
      plugin_class
    end

    def load_v6_plugin(plugin_class, plugin_path, plugin_dir_path)
      plugin_class.new(@controller, plugin_path, plugin_dir_path)
    end

    # Capture the plugin in @v6_dependency_solver if it is a V6 plugin
    # to be able to resolve V6 dependencies later on.
    # We are using the partial path in the dep solver as a key.
    def loaded_v6_plugin(plugin, plugin_file_path, plugin_dir_path)
      partial_path = Pathname.new(plugin_file_path).relative_path_from(Pathname.new(plugin_dir_path)).to_s

      unless v6_dependency_solver.has_key?(partial_path)
        v6_dependency_solver[partial_path] = plugin
      else
        Ohai::Log.debug("Plugin '#{plugin_file_path}' is already loaded.")
      end
    end

    def load_v7_plugin_class(contents, plugin_path)
      plugin_class = eval(contents, TOPLEVEL_BINDING, plugin_path)
      unless plugin_class.kind_of?(Class) && plugin_class < Ohai::DSL::Plugin
        raise Ohai::Exceptions::IllegalPluginDefinition, "Plugin file cannot contain any statements after the plugin definition"
      end
      plugin_class.sources << plugin_path
      @v7_plugin_classes << plugin_class unless @v7_plugin_classes.include?(plugin_class)
      plugin_class
    rescue SystemExit, Interrupt
      raise
    rescue Ohai::Exceptions::InvalidPluginName => e
      Ohai::Log.warn("Plugin Name Error: <#{plugin_path}>: #{e.message}")
    rescue Ohai::Exceptions::IllegalPluginDefinition => e
      Ohai::Log.warn("Plugin Definition Error: <#{plugin_path}>: #{e.message}")
    rescue NoMethodError => e
      Ohai::Log.warn("Plugin Method Error: <#{plugin_path}>: unsupported operation \'#{e.name}\'")
    rescue SyntaxError => e
      # split on occurrences of
      #    <env>: syntax error,
      #    <env>:##: syntax error,
      # to remove from error message
      parts = e.message.split(/<.*>[:[0-9]+]*: syntax error, /)
      parts.each do |part|
        next if part.length == 0
        Ohai::Log.warn("Plugin Syntax Error: <#{plugin_path}>: #{part}")
      end
    rescue Exception, Errno::ENOENT => e
      Ohai::Log.warn("Plugin Error: <#{plugin_path}>: #{e.message}")
      Ohai::Log.debug("Plugin Error: <#{plugin_path}>: #{e.inspect}, #{e.backtrace.join('\n')}")
    end

    def load_v7_plugin(plugin_class)
      plugin = plugin_class.new(@controller.data)
      collect_provides(plugin)
      plugin
    end

  end
end
