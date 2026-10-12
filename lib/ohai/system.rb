# frozen_string_literal: true
#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "version"
require_relative "loader"
require_relative "log"
require_relative "mash"
require_relative "runner"
require_relative "dsl"
require_relative "mixin/shell_out"
require_relative "mixin/os"
require_relative "mixin/string"
require_relative "mixin/constant_helper"
require_relative "provides_map"
require_relative "hints"
require_relative "config"
require_relative "train_transport"
require "ffi_yajl" unless defined?(FFI_Yajl)
require "cgi" unless defined?(CGI)

module Ohai
  # The class used by Ohai::Application and Chef to actually collect data
  class System
    include Ohai::Mixin::ConstantHelper

    attr_accessor :data
    attr_reader :config
    attr_reader :provides_map
    attr_reader :logger
    attr_writer :transport_connection

    # the cli flag is used to determine if we're being constructed by
    # something like chef-client (which doesn't set this flag) and
    # which sets up its own loggers, or if we're coming from Ohai::Application
    # and therefore need to configure Ohai's own logger.
    def initialize(config = {})
      @cli = config[:invoked_from_cli]
      @plugin_path = ""
      @config = config
      @failed_plugins = []
      @logger = config[:logger] || Ohai::Log.with_child
      @logger.metadata = { system: "ohai", version: Ohai::VERSION }
      reset_system
    end

    # clears the current collected data, clears the provides map for plugins,
    # refreshes hints, and reconfigures ohai. In short this gets Ohai into a first run state
    #
    # @return [void]
    def reset_system
      @data = Mash.new
      @provides_map = ProvidesMap.new
      @plugins_ran = false

      configure_ohai
      configure_logging if @cli

      @loader = Ohai::Loader.new(self)

      Ohai::Hints.refresh_hints

      # Remove the previously defined plugins
      recursive_remove_constants(Ohai::NamedPlugin)
    end

    def runner
      @runner ||=
        Ohai::Runner.new(self, true).tap do |runner|
          runner.transport_connection = transport_connection unless transport_connection.nil?
        end
    end

    def [](key)
      @data[key]
    end

    # Resets the system and loads then runs the plugins. This is the primary method called
    # to run the system.
    #
    # @param [Array<String>] attribute_filter the attributes to run. All will be run if not specified
    #
    # @return [void]
    def all_plugins(attribute_filter = nil)
      # Reset the system when all_plugins is called since this function
      # can be run multiple times in order to pick up any changes in the
      # config or plugins with Chef.
      reset_system

      load_plugins
      run_plugins(true, attribute_filter)
      @plugins_ran = true
    end

    # Add a platform-selected plugin directory before the next plugin run.
    #
    # @param path [String] directory containing additional Ohai plugins
    # @return [Boolean] true when the path was newly added
    def add_platform_plugin_path(path)
      path = File.expand_path(path)
      return false unless Dir.exist?(path)
      return false if Ohai.config[:plugin_path].include?(path)

      Ohai.config[:plugin_path] << path
      true
    end

    # @return [Boolean] whether a plugin run has completed for this system
    def plugins_ran?
      @plugins_ran
    end

    # load all plugins by calling Ohai::Loader.load_all
    #
    # @see Ohai::Loader.load_all
    def load_plugins
      @loader.load_all
    end

    # get backend parameters for target mode
    #
    # @return [Train::Transport]
    def transport_connection
      @transport_connection ||= Ohai::TrainTransport.new(logger).build_transport&.connection
    end

    # run all plugins or those that match the attribute filter is provided
    #
    # @param safe [Boolean]
    # @param [Array<String>] attribute_filter the attributes to run. All will be run if not specified
    #
    # @return [Mash]
    def run_plugins(safe = false, attribute_filter = nil)
      begin
        @provides_map.all_plugins(attribute_filter).each do |plugin|
          runner.run_plugin(plugin)
        end
        transport_connection.close unless transport_connection.nil?
      rescue Ohai::Exceptions::AttributeNotFound, Ohai::Exceptions::DependencyCycle => e
        logger.error("Encountered error while running plugins: #{e.inspect}")
        raise
      end
      critical_failed = Ohai::Config.ohai[:critical_plugins] & runner.failed_plugins
      unless critical_failed.empty?
        msg = "The following Ohai plugins marked as critical failed: #{critical_failed}"
        if @cli
          logger.error(msg)
          exit(true)
        else
          raise Ohai::Exceptions::CriticalPluginFailure, "#{msg}. Failing Chef run."
        end
      end

      # Freeze all strings.
      freeze_strings!
    end

    # @param [String] plugin_path
    #
    # @return [void]
    #
    def run_additional_plugins(plugin_path, include_default: true)
      paths = include_default ? [Ohai.config[:plugin_path], plugin_path].flatten : Array(plugin_path)
      @loader.load_additional(paths, include_default: false).each do |plugin|
        logger.trace "Running plugin #{plugin}"
        runner.run_plugin(plugin)
      end

      freeze_strings!
    end

    # Return platform attributes exposed by the target transport before the
    # full Ohai run. This lets Chef select platform-specific plugins early
    # enough to replace host-only collectors.
    #
    # @return [Hash]
    def target_platform_attributes
      connection = transport_connection
      return {} unless connection && connection.respond_to?(:platform)

      platform = connection.platform
      platform_name = scalar_platform_value(platform_value(platform, :name))
      platform_name ||= scalar_platform_value(platform_value(platform, :platform))
      platform_name ||= scalar_platform_value(platform_value(platform, :os))
      platform_name ||= platform if platform.is_a?(String) || platform.is_a?(Symbol)

      attributes = {}
      attributes[:platform] = platform_name unless platform_name.nil?
      attributes[:platform_family] = platform_value(platform, :family)
      attributes[:os] = platform_value(platform, :os) || platform_name
      attributes.delete_if { |_key, value| value.nil? || value.to_s.empty? }
    rescue StandardError => e
      logger.debug("Unable to read target platform attributes from transport: #{e.class}: #{e.message}")
      {}
    end

    #
    # Serialize this object as a hash
    #
    def to_json
      FFI_Yajl::Encoder.new.encode(@data)
    end

    #
    # Pretty Print this object as JSON
    #
    def json_pretty_print(item = nil)
      FFI_Yajl::Encoder.new(pretty: true, validate_utf8: false).encode(item || @data)
    end

    def attributes_print(a)
      data = @data
      a.split("/").each do |part|
        data = data[part]
      end
      raise ArgumentError, "I cannot find an attribute named #{a}!" if data.nil?

      case data
      when Hash, Mash, Array, Integer
        json_pretty_print(data)
      when String
        if data.respond_to?(:lines)
          json_pretty_print(data.lines.to_a)
        else
          json_pretty_print(data.to_a)
        end
      else
        raise ArgumentError, "I can only generate JSON for Hashes, Mashes, Arrays and Strings. You fed me a #{data.class}!"
      end
    end

    private

    def configure_ohai
      Ohai.config.merge!(@config)

      # add any additional CLI passed directories to the plugin path excluding duplicates
      unless Ohai.config[:directory].nil?
        # make sure the directory config is an array since it could be a string set in client.rb
        Array(Ohai.config[:directory]).each do |dir|
          next if Ohai.config[:plugin_path].include?(dir)

          Ohai.config[:plugin_path] << dir
        end
      end

      logger.debug("Running Ohai with the following configuration: #{Ohai.config.configuration}")
    end

    def configure_logging
      if Ohai.config[:log_level] == :auto
        Ohai::Log.level = :info
      else
        Ohai::Log.level = Ohai.config[:log_level]
      end
    end

    # Freeze all string values in @data. This makes them immutable and saves
    # a bit of RAM.
    #
    # @api private
    # @return [void]
    def freeze_strings!
      # Recursive visitor pattern helper.
      visitor = lambda do |val|
        case val
        when Hash
          val.each_value { |v| visitor.call(v) }
        when Array
          val.each { |v| visitor.call(v) }
        when String
          val.freeze
        end
      end
      visitor.call(@data)
    end

    # Extract additional backend parameters from Target Mode URL.
    #
    # @api private
    # @return [Hash]
    def backend_parameters
      uri = URI.parse(config[:target])
      return {} unless uri.query

      CGI.parse(uri.query).map { |k, v| [k.to_sym, v.first] }.to_h
    end

    def platform_value(platform, attribute)
      value = platform.public_send(attribute) if platform.respond_to?(attribute)
      if value.nil? && platform.respond_to?(:[])
        begin
          value = platform[attribute]
          value = platform[attribute.to_s] if value.nil?
        rescue IndexError, NameError, TypeError
          value = nil
        end
      end
      return nil if value.nil? || value.to_s.empty? || value.to_s == "unknown"

      value
    end

    def scalar_platform_value(value)
      value if value.is_a?(String) || value.is_a?(Symbol)
    end
  end
end
