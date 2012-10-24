require 'ohai/mixin/command'
require 'ohai/mixin/from_file'
require 'ohai/mixin/seconds_to_human'

module Ohai
  module DSL
    class Plugin

      include Ohai::Mixin::Command
      include Ohai::Mixin::FromFile
      include Ohai::Mixin::SecondsToHuman

      attr_reader :file
      attr_reader :data

      def initialize(controller, file)
        @controller = controller
        @data = controller.data
        @providers = controller.providers
        @file = file
      end

      def run
        from_file(@file)
      end

      def require_plugin(*args)
        @controller.require_plugin(*args)
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
        paths.each do |path|
          parts = path.split('/')
          h = @providers
          unless parts.length == 0
            parts.shift if parts[0].length == 0
            parts.each do |part|
              h[part] ||= Mash.new
              h = h[part]
            end
          end
          h[:_providers] ||= []
          h[:_providers] << @plugin_path
        end
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
