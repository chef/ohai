#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Claire McQuin (<claire@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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

require "ohai/mixin/os"
require "ohai/mixin/command"
require "ohai/mixin/seconds_to_human"
require "ohai/hints"
require "ohai/util/file_helper"

module Ohai

  # For plugin namespacing
  module NamedPlugin
    def self.valid_name?(name)
      name.is_a?(Symbol) && name.to_s.match(/^[^A-Z]|_/).nil?
    end

    # dealing with ruby 1.8
    if Module.method(:const_defined?).arity == 1
      def self.strict_const_defined?(const)
        const_defined?(const)
      end
    else
      def self.strict_const_defined?(const)
        const_defined?(const, false)
      end
    end
  end

  def self.plugin(name, &block)
    raise Ohai::Exceptions::InvalidPluginName, "#{name} is not a valid plugin name. A valid plugin name is a symbol which begins with a capital letter and contains no underscores" unless NamedPlugin.valid_name?(name)

    plugin = nil

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
  def self.dev_null
    if RUBY_PLATFORM =~ /mswin|mingw|windows/
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
      include Ohai::Mixin::Command
      include Ohai::Mixin::SecondsToHuman
      include Ohai::Util::FileHelper

      attr_reader :data

      def initialize(data)
        @data = data
        @has_run = false
      end

      def run
        @has_run = true

        if Ohai.config[:disabled_plugins].include?(name)
          Ohai::Log.debug("Skipping disabled plugin #{name}")
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
        @data.has_key?(name)
      end

      def attribute?(name, *keys)
        !safe_get_attribute(name, *keys).nil?
      end

      def set(name, *value)
        set_attribute(name, *value)
      end

      def from(cmd)
        _status, stdout, _stderr = run_command(:command => cmd)
        return "" if stdout.nil? || stdout.empty?
        stdout.strip
      end

      # Set the value equal to the stdout of the command, plus
      # run through a regex - the first piece of match data is\
      # the value.
      def from_with_regex(cmd, *regex_list)
        regex_list.flatten.each do |regex|
          _status, stdout, _stderr = run_command(:command => cmd)
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
        attribute = keys[0..-2].inject(@data) do |attrs, key|
          attrs[key] ||= Mash.new
          attrs[key]
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
        begin
          self.run
        rescue Ohai::Exceptions::Error => e
          raise e
        rescue => e
          Ohai::Log.debug("Plugin #{self.name} threw #{e.inspect}")
          e.backtrace.each { |line| Ohai::Log.debug( line ) }
        end
      end

      def method_missing(name, *args)
        return get_attribute(name) if args.length == 0

        set_attribute(name, *args)
      end

      private

      def safe_get_attribute(*keys)
        keys.inject(@data) do |attrs, key|
          unless attrs.nil? || attrs.is_a?(Array) || attrs.is_a?(Hash)
            raise TypeError.new("Expected Hash but got #{attrs.class}.")
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
