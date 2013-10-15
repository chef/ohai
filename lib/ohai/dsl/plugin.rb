#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Claire McQuin (<claire@opscode.com>)
# Copyright:: Copyright (c) 2008, 2013 Opscode, Inc.
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

require 'ohai/mixin/os'
require 'ohai/mixin/command'
require 'ohai/mixin/seconds_to_human'

module Ohai

  # for plugin namespacing
  module NamedPlugin
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
    plugin = nil
    if NamedPlugin.strict_const_defined?(name)
      plugin = NamedPlugin.const_get(name)
      if plugin.version.eql?(:version6)
        Ohai::Log.warn("Already loaded version 6 plugin #{name}")
      else
        plugin.class_eval(&block)
      end
    else
      klass = Class.new(DSL::Plugin::VersionVII, &block)
      plugin = NamedPlugin.const_set(name, klass)
    end
    plugin
  end

  def self.v6plugin(name_str, &block)
    plugin = nil
    name = nameify(name_str)
    if NamedPlugin.strict_const_defined?(name)
      # log @ debug-level mimics OHAI-6
      Ohai::Log.debug("Already loaded plugin #{name}")
      plugin = NamedPlugin.const_get(name)
    else
      klass = Class.new(DSL::Plugin::VersionVI, &block)
      plugin = NamedPlugin.const_set(name, klass)
    end
    plugin
  end

  def self.nameify(name_str)
    return name_str if name_str.is_a?(Symbol)

    parts = name_str.split(/[^a-zA-Z0-9]/)
    name = ""
    parts.each do |part|
      next if part.eql?("")
      name << part.capitalize
    end

    raise ArgumentError, "Invalid plugin name: #{name_str}" if name.eql?("")
    name.to_sym
  end

  # cross platform /dev/null
  def self.dev_null
    if RUBY_PLATFORM =~ /mswin|mingw|windows/
      "NUL"
    else
      "/dev/null"
    end
  end

  # this methods gets overridden at test time, to force the shell to check
  # ohai/spec/unit/path/original/absolute/path/to/exe
  def self.abs_path( abs_path )
    abs_path
  end

  module DSL
    class Plugin
      include Ohai::OS
      include Ohai::Mixin::Command
      include Ohai::Mixin::SecondsToHuman

      attr_reader :data
      attr_reader :source

      def initialize(controller, source)
        @controller = controller
        @attributes = controller.attributes
        @data = controller.data
        @source = source
        @has_run = false
      end

      def run
        @has_run = true
        run_plugin
      end

      def has_run?
        @has_run
      end

      #=====================================================
      # version 7 plugin class
      #=====================================================
      class VersionVII < Plugin
        attr_reader :version

        def initialize(controller, source)
          super(controller, source)
          @version = :version7
        end

        def name
          self.class.name.split("Ohai::NamedPlugin::")[1]
        end

        def self.version
          :version7
        end

        def self.provides_attrs
          @provides_attrs ||= []
        end

        def self.depends_attrs
          @depends_attrs ||= []
        end

        def self.data_collector
          @data_collector ||= Mash.new
        end

        def self.provides(*attrs)
          attrs.each do |attr|
            provides_attrs << attr
          end
        end

        def self.depends(*attrs)
          attrs.each do |attr|
            depends_attrs << attr
          end
        end

        def self.collect_data(platform = :default, *other_platforms, &block)
          [platform, other_platforms].flatten.each do |plat|
            if data_collector.has_key?(plat)
              Ohai::Log.warn("Already defined collect_data on platform #{plat}")
            else
              data_collector[plat] = block
            end
          end
        end

        def dependencies
          self.class.depends_attrs
        end

        def run_plugin
          collector = self.class.data_collector
          platform = collect_os

          if collector.has_key?(platform)
            self.instance_eval(&collector[platform])
          elsif collector.has_key?(:default)
            self.instance_eval(&collector[:default])
          else
            Ohai::Log.debug("No data to collect for plugin #{self.name}. Continuing...")
          end
        end

        def provides(*paths)
          Ohai::Log.warn("[UNSUPPORTED OPERATION] \'provides\' is no longer supported in a \'collect_data\' context. Please specify \'provides\' before collecting plugin data. Ignoring command \'provides #{paths.join(", ")}")
        end

        def require_plugin(*args)
          Ohai::Log.warn("[UNSUPPORTED OPERATION] \'require_plugin\' is no longer supported. Please use \'depends\' instead.\nIgnoring plugin(s) #{args.join(", ")}")
        end
      end

      #=====================================================
      # version 6 plugin class
      #=====================================================
      class VersionVI < Plugin
        attr_reader :version

        def initialize(controller, source)
          super(controller, source)
          @version = :version6
        end

        def name
          self.class.name.split("Ohai::NamedPlugin::")[1]
        end

        def self.version
          :version6
        end

        def self.collect_contents(contents)
          define_method(:run_plugin) { self.instance_eval(contents) }
        end

        def provides(*paths)
          paths.each do |path|
            parts = path.split("/")
            a = @attributes
            unless parts.length == 0
              parts.shift if parts[0].length == 0
              parts.each do |part|
                a[part] ||= Mash.new
                a = a[part]
              end
            end
            a[:providers] ||= []
            a[:providers] << self
          end
        end

        def require_plugin(*args)
          @controller.require_plugin(*args)
        end

      end

      #=====================================================
      # plugin DSL methods
      #=====================================================
      def hints
        @controller.hints
      end

      def [](key)
        @data[key]
      end

      def []=(key, value)
        @data[key] = value
      end

      def each(&block)
        @data.each do |key, value|
          block.call(key, value)
        end
      end

      def attribute?(name)
        @data.has_key?(name)
      end

      def set(name, *value)
        set_attribute(name, *value)
      end

      def from(cmd)
        status, stdout, stderr = run_command(:command => cmd)
        return "" if stdout.nil? || stdout.empty?
        stdout.strip
      end

      # Set the value equal to the stdout of the command, plus
      # run through a regex - the first piece of match data is\
      # the value.
      def from_with_regex(cmd, *regex_list)
        regex_list.flatten.each do |regex|
          status, stdout, stderr = run_command(:command => cmd)
          return "" if stdout.nil? || stdout.empty?
          stdout.chomp!.strip
          md = stdout.match(regex)
          return md[1]
        end
      end

      def set_attribute(name, *values)
        @data[name] = Array18(*values)
        @data[name]
      end

      def get_attribute(name)
        @data[name]
      end

      def hint?(name)
        @json_parser ||= Yajl::Parser.new

        return hints[name] if hints[name]

        Ohai::Config[:hints_path].each do |path|
          filename = File.join(path, "#{name}.json")
          if File.exist?(filename)
            begin
              hash = @json_parser.parse(File.read(filename))
              hints[name] = hash || Hash.new # hint
              # should exist because the file did, even if it didn't
              # contain anything
            rescue Yajl::ParseError => e
              Ohai::Log.error("Could not parse hint file at #{filename}: #{e.message}")
            end
          end
        end

        hints[name]
      end

      # emulates the old plugin loading behavior
      def safe_run
        begin
          self.run
        rescue => e
          Ohai::Log.error("Plugin #{self.name} threw #{e.inspect}")
          e.backtrace.each { |line| Ohai::Log.debug( line )}
        end
      end

      def method_missing(name, *args)
        return get_attribute(name) if args.length == 0

        set_attribute(name, *args)
      end

      private

      def Array18(*args)
        return nil if args.empty?
        return args.first if args.length == 1
        return *args
      end
    end
  end
end
