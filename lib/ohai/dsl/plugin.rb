#
#
#

require 'ohai/os'

require 'ohai/mixin/command'
require 'ohai/mixin/seconds_to_human'

module Ohai
  #=========================================================
  # define new plugin class
  #=========================================================
  def self.plugin(plugin_name, &block)
    plugin_class = Class.new(DSL::Plugin, &block)
    const_set(plugin_name, plugin_class)
  end

  module DSL
    class Plugin

      include Ohai::OS
      include Ohai::Mixin::Command
      include Ohai::Mixin::SecondsToHuman

      #=====================================================
      # plugin loading phase
      #=====================================================
      def self.provides_attrs
        @provides_attrs ||= []
      end

      def self.depends_attrs
        @depends_attrs ||= []
      end

      def self.provides(*args)
        args.each do |attr|
          provides_attrs << attr
        end
      end

      def self.depends(*args)
        args.each do |attr|
          depends_attrs << attr
        end
      end

      def self.depends_os(*args)
        args.each do |attr|
          depends_attrs << "#{Ohai::OS.collect_os}/#{attr}"
        end
      end

      def self.collect_data(&block)
        define_method(:run, &block)
      end

      #=====================================================
      # plugin run phase
      #=====================================================
      attr_reader :data

      def initialize(controller)
        @controller = controller
        @data = controller.data
      end
      
      def require_plugin(*args)
        # @todo: backwards compat
        # @controller.require_plugin(*args)
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

      # Set the value equal to the stdout of the command, plus run through a regex - the first piece of match data is the value.
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
              hints[name] = hash || Hash.new # hint should exist because the file did, even if it didn't contain anything
            rescue Yajl::ParseError => e
              Ohai::Log.error("Could not parse hint file at #{filename}: #{e.message}")
            end
          end
        end

        hints[name]
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
