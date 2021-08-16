# frozen_string_literal: true
#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Claire McQuin (<claire@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../mixin/os"
require_relative "../mixin/shell_out"
require_relative "../mixin/seconds_to_human"
require_relative "../mixin/which"
require_relative "../mixin/train_helpers"
require_relative "../hints"

module Ohai

  # For plugin namespacing
  module NamedPlugin

    # Is the plugin a Symbol starting with a capital letter that has no underscores
    #
    # @param name [String] the plugin name
    # @return [Boolean]
    def self.valid_name?(name)
      name.is_a?(Symbol) && name.to_s.match(/^[^A-Z]|_/).nil?
    end

    # @return [Boolean]
    def self.strict_const_defined?(const)
      const_defined?(const, false)
    end
  end

  # @param name [String]
  def self.plugin(name, &block)
    raise Ohai::Exceptions::InvalidPluginName, "#{name} is not a valid plugin name. A valid plugin name is a symbol which begins with a capital letter and contains no underscores" unless NamedPlugin.valid_name?(name)

    plugin = nil

    # avoid already initialized constant warnings if already defined
    if NamedPlugin.strict_const_defined?(name)
      plugin = NamedPlugin.const_get(name)
      plugin.class_eval(&block)
    else
      klass = Class.new(DSL::Plugin::VersionVII, &block)
      plugin = NamedPlugin.const_set(name, klass)
    end

    plugin
  end

  # Cross platform /dev/null to support testability
  #
  # @return [String]
  def self.dev_null
    if RUBY_PLATFORM.match?(/mswin|mingw|windows/)
      "NUL"
    else
      "/dev/null"
    end
  end

  # Extracted abs_path to support testability:
  # This method gets overridden at test time, to force the shell to check
  # ohai/spec/unit/path/original/absolute/path/to/exe
  def self.abs_path( abs_path )
    abs_path
  end

  module DSL
    class Plugin

      include Ohai::Mixin::OS
      include Ohai::Mixin::ShellOut
      include Ohai::Mixin::SecondsToHuman
      include Ohai::Mixin::Which
      include Ohai::Mixin::TrainHelpers

      attr_reader :data
      attr_reader :failed
      attr_reader :logger
      attr_accessor :transport_connection

      def initialize(data, logger)
        @data = data
        @logger = logger.with_child({ subsystem: "plugin", plugin: name })
        @has_run = false
        @failed = false
      end

      def target_mode?
        !!@transport_connection
      end

      def run
        @has_run = true

        if Ohai.config[:disabled_plugins].include?(name)
          logger.trace("Skipping disabled plugin #{name}")
        else
          run_plugin
        end
      end

      def has_run?
        @has_run
      end

      def reset!
        @has_run = false
      end

      def [](key)
        @data[key]
      end

      def []=(key, value)
        @data[key] = value
      end

      def each(&block)
        @data.each do |key, value|
          yield(key, value)
        end
      end

      def has_key?(name)
        @data.key?(name)
      end

      def attribute?(name, *keys)
        !safe_get_attribute(name, *keys).nil?
      end

      def set(name, *value)
        set_attribute(name, *value)
      end

      def from(cmd)
        _status, stdout, _stderr = run_command(command: cmd)
        return "" if stdout.nil? || stdout.empty?

        stdout.strip
      end

      # Set the value equal to the stdout of the command, plus
      # run through a regex - the first piece of match data is\
      # the value.
      def from_with_regex(cmd, *regex_list)
        regex_list.flatten.each do |regex|
          _status, stdout, _stderr = run_command(command: cmd)
          return "" if stdout.nil? || stdout.empty?

          stdout.chomp!.strip
          md = stdout.match(regex)
          return md[1]
        end
      end

      def set_attribute(name, *attrs, value)
        # Initialize the path in the @data Mash with new Mashes, if needed.
        # Will raise a TypeError if we hit a subattribute that is not a
        # Hash, Mash, or Array.
        keys = [name] + attrs
        attribute = keys[0..-2].inject(@data) do |atts, key|
          atts[key] ||= Mash.new
          atts[key]
        end

        # Set the subattribute to the value.
        attr_name = attrs.empty? ? name : attrs[-1]
        attribute[attr_name] = value
        @data[name]
      end

      def get_attribute(name, *keys)
        safe_get_attribute(name, *keys)
      end

      def hint?(name)
        Ohai::Hints.hint?(name)
      end

      # emulates the old plugin loading behavior
      def safe_run
        run
      rescue Ohai::Exceptions::Error => e
        @failed = true
        raise e
      rescue => e
        @failed = true
        logger.trace("Plugin #{name} threw #{e.inspect}")
        e.backtrace.each { |line| logger.trace( line ) }
      end

      def method_missing(name, *args)
        return get_attribute(name) if args.length == 0

        set_attribute(name, *args)
      end

      private

      def safe_get_attribute(*keys)
        keys.inject(@data) do |attrs, key|
          unless attrs.nil? || attrs.is_a?(Array) || attrs.is_a?(Hash)
            raise TypeError, "Expected Hash but got #{attrs.class}."
          end

          attrs[key]
        end
      rescue NoMethodError
        # NoMethodError occurs when trying to access a key on nil
        nil
      end
    end
  end
end
