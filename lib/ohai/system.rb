#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2008-2017, Chef Software Inc.
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

require "ohai/loader"
require "ohai/log"
require "ohai/mash"
require "ohai/runner"
require "ohai/dsl"
require "ohai/mixin/command"
require "ohai/mixin/os"
require "ohai/mixin/string"
require "ohai/mixin/constant_helper"
require "ohai/provides_map"
require "ohai/hints"
require "mixlib/shellout"
require "ohai/config"

module Ohai
  class System
    include Ohai::Mixin::ConstantHelper

    attr_accessor :data
    attr_reader :config
    attr_reader :provides_map
    attr_reader :logger

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

    def reset_system
      @data = Mash.new
      @provides_map = ProvidesMap.new

      configure_ohai
      configure_logging if @cli

      @loader = Ohai::Loader.new(self)
      @runner = Ohai::Runner.new(self, true)

      Ohai::Hints.refresh_hints

      # Remove the previously defined plugins
      recursive_remove_constants(Ohai::NamedPlugin)
    end

    def [](key)
      @data[key]
    end

    def all_plugins(attribute_filter = nil)
      # Reset the system when all_plugins is called since this function
      # can be run multiple times in order to pick up any changes in the
      # config or plugins with Chef.
      reset_system

      load_plugins
      run_plugins(true, attribute_filter)
    end

    def load_plugins
      @loader.load_all
    end

    def run_plugins(safe = false, attribute_filter = nil)
      begin
        @provides_map.all_plugins(attribute_filter).each do |plugin|
          @runner.run_plugin(plugin)
        end
      rescue Ohai::Exceptions::AttributeNotFound, Ohai::Exceptions::DependencyCycle => e
        logger.error("Encountered error while running plugins: #{e.inspect}")
        raise
      end
      critical_failed = Ohai::Config.ohai[:critical_plugins] & @runner.failed_plugins
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

    def run_additional_plugins(plugin_path)
      @loader.load_additional(plugin_path).each do |plugin|
        logger.trace "Running plugin #{plugin}"
        @runner.run_plugin(plugin)
      end

      freeze_strings!
    end

    # Re-runs plugins that provide the attributes specified by
    # +attribute_filter+. If +attribute_filter+ is not given, re-runs all
    # plugins.
    #
    # Note that dependencies will not be re-run, so you must specify all of the
    # attributes you want refreshed in the +attribute_filter+
    #
    # This method takes a naive approach to v6 plugins: it simply re-runs all
    # of them whenever called.
    def refresh_plugins(attribute_filter = nil)
      Ohai::Hints.refresh_hints
      @provides_map.all_plugins(attribute_filter).each do |plugin|
        plugin.reset!
      end
      run_plugins(true, attribute_filter)
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
        Ohai.config[:directory].each do |dir|
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
  end
end
