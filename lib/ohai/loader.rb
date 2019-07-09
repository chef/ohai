#
# Author:: Claire McQuin (<claire@chef.io>)
# Copyright:: Copyright (c) 2013-2019, Chef Software Inc.
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
require_relative "log"
require_relative "mash"
require_relative "dsl"
require "pathname" unless defined?(Pathname)

module Ohai

  # Ohai plugin loader. Finds all the plugins specified in the
  # Ohai.config :plugin_path (supports a single or multiple path setting
  # here), evaluates them and returns plugin objects.
  class Loader
    attr_reader :logger

    def initialize(controller)
      @controller = controller
      @logger = controller.logger.with_child(subsystem: "loader")
      @v7_plugin_classes = []
    end

    # Searches all plugin paths and returns an Array of file paths to plugins
    #
    # @param dir [Array, String] directory/directories to load plugins from
    # @return [Array<String>]
    def plugin_files_by_dir(plugin_dir = Ohai.config[:plugin_path])
      Array(plugin_dir).map do |path|
        if Dir.exist?(path)
          Ohai::Log.trace("Searching for Ohai plugins in #{path}")

          escaped = ChefConfig::PathHelper.escape_glob_dir(path)
          Dir[File.join(escaped, "**", "*.rb")]
        else
          Ohai::Log.debug("The plugin path #{path} does not exist. Skipping...")
          []
        end
      end.flatten
    end

    # loads all plugin classes
    #
    # @return [Array<String>]
    def load_all
      plugin_files_by_dir.each do |plugin_file|
        load_plugin_class(plugin_file)
      end

      collect_v7_plugins
    end

    # load additional plugins classes from a given directory
    # @param from [String] path to a directory with additional plugins to load
    def load_additional(from)
      from = [ Ohai.config[:plugin_path], from].flatten
      plugin_files_by_dir(from).collect do |plugin_file|
        logger.trace "Loading additional plugin: #{plugin_file}"
        plugin = load_plugin_class(plugin_file)
        load_v7_plugin(plugin)
      end
    end

    # Load a specified file as an ohai plugin and creates an instance of it.
    # Not used by ohai itself, but is used in the specs to load plugins for testing
    #
    # @private
    # @param plugin_path [String]
    def load_plugin(plugin_path)
      plugin_class = load_plugin_class(plugin_path)
      return nil unless plugin_class.is_a?(Class)

      if plugin_class < Ohai::DSL::Plugin::VersionVII
        load_v7_plugin(plugin_class)
      else
        raise Exceptions::IllegalPluginDefinition, "cannot create plugin of type #{plugin_class}"
      end
    end

    # load an ohai plugin object class from file
    # @param plugin_path String the path to the ohai plugin
    #
    # @return [Object] class object for the ohai plugin defined in the file
    def load_plugin_class(plugin_path)
      # Read the contents of the plugin to understand if it's a V6 or V7 plugin.
      contents = ""
      begin
        logger.trace("Loading plugin at #{plugin_path}")
        contents << IO.read(plugin_path)
      rescue IOError, Errno::ENOENT
        logger.warn("Unable to open or read plugin at #{plugin_path}")
        return nil
      end

      # We assume that a plugin is a V7 plugin if it contains Ohai.plugin in its contents.
      if contents.include?("Ohai.plugin")
        load_v7_plugin_class(contents, plugin_path)
      else
        raise Exceptions::IllegalPluginDefinition, "[DEPRECATION] Plugin at #{plugin_path}"\
        " is a version 6 plugin. Version 6 plugins are no longer supported by Ohai. This"\
        " plugin will need to be updated to the v7 Ohai plugin format. See"\
        " https://docs.chef.io/ohai_custom.html for v7 syntax."
      end
    end

    private

    def collect_provides(plugin)
      plugin_provides = plugin.class.provides_attrs
      @controller.provides_map.set_providers_for(plugin, plugin_provides)
    end

    def collect_v7_plugins
      @v7_plugin_classes.each do |plugin_class|
        load_v7_plugin(plugin_class)
      end
    end

    # load an Ohai v7 plugin class from a string of the object
    # @param contents [String] text of the plugin object
    # @param plugin_path [String] the path to the plugin file where the contents came from
    #
    # @return [Ohai::DSL::Plugin::VersionVII] Ohai plugin object
    def load_v7_plugin_class(contents, plugin_path)
      plugin_class = eval(contents, TOPLEVEL_BINDING, plugin_path) # rubocop: disable Security/Eval
      unless plugin_class.is_a?(Class) && plugin_class < Ohai::DSL::Plugin
        raise Ohai::Exceptions::IllegalPluginDefinition, "Plugin file cannot contain any statements after the plugin definition"
      end

      plugin_class.sources << plugin_path
      @v7_plugin_classes << plugin_class unless @v7_plugin_classes.include?(plugin_class)
      plugin_class
    rescue SystemExit, Interrupt # rubocop: disable Lint/ShadowedException
      raise
    rescue Ohai::Exceptions::InvalidPluginName => e
      logger.warn("Plugin Name Error: <#{plugin_path}>: #{e.message}")
    rescue Ohai::Exceptions::IllegalPluginDefinition => e
      logger.warn("Plugin Definition Error: <#{plugin_path}>: #{e.message}")
    rescue NoMethodError => e
      logger.warn("Plugin Method Error: <#{plugin_path}>: unsupported operation \'#{e.name}\'")
    rescue SyntaxError => e
      # split on occurrences of
      #    <env>: syntax error,
      #    <env>:##: syntax error,
      # to remove from error message
      parts = e.message.split(/<.*>[:[0-9]+]*: syntax error, /)
      parts.each do |part|
        next if part.length == 0

        logger.warn("Plugin Syntax Error: <#{plugin_path}>: #{part}")
      end
    rescue Exception => e
      logger.warn("Plugin Error: <#{plugin_path}>: #{e.message}")
      logger.trace("Plugin Error: <#{plugin_path}>: #{e.inspect}, #{e.backtrace.join('\n')}")
    end

    def load_v7_plugin(plugin_class)
      plugin = plugin_class.new(@controller.data, @controller.logger)
      collect_provides(plugin)
      plugin
    end

  end
end
