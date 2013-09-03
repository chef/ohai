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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'ohai/os'
require 'ohai/mixin/command'
require 'ohai/mixin/seconds_to_human'

module Ohai
  def self.plugin(&block)
    Class.new(DSL::Plugin::VersionVII, &block)
  end

  def self.v6plugin(&block)
    Class.new(DSL::Plugin::VersionVI, &block)
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
        def initialize(controller, source)
          super(controller, source)
        end

        def version
          :version7
        end

        def dependencies
          self.class.depends_attrs
        end

        def self.provides_attrs
          @provides_attrs ||= []
        end

        def self.depends_attrs
          @depends_attrs ||= []
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

        def self.depends_os(*attrs)
          attrs.each do |attr|
            depends_attrs << "#{Ohai::OS.collect_os}/#{attr}"
          end
        end

        def self.collect_data(&block)
          define_method(:run_plugin, &block)
        end
      end

      #=====================================================
      # version 6 plugin class
      #=====================================================
      class VersionVI < Plugin
        def initialize(controller, source)
          super(controller, source)
        end

        def version
          :version6
        end

        def self.collect_contents(contents)
          define_method(:run_plugin) { self.instance_eval(contents) }
        end
      end

      #=====================================================
      # plugin DSL methods
      #=====================================================
      def require_plugin(*args)
        if self.version == :version6
          @controller.require_plugin(*args)
        else
          Ohai::Log.warn("[UNSUPPORTED OPERATION] \'require_plugin\' is no longer supported. Please use \'depends\' instead.\nIgnoring plugin(s) #{args.join(", ")}")
        end
      end

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

      def provides(*paths)
        if self.version == :version7
          Ohai::Log.warn("[UNSUPPORTED OPERATION] \'provides\' is no longer supported in a \'collect_data\' context. Please specify \'provides\' before collecting plugin data. Ignoring command \'provides #{paths.join(", ")}")
        else
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

      #emulates the old plugin loading behavior
      def safe_run
        begin
          self.run
        rescue => e
          Ohai::Log.error("Plugin #{self.class.name} threw #{e.inspect}")
          e.backtrace.each { |line| Ohai::Log.error( line )}
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
