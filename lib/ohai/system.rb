#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'ohai/mash'
require 'ohai/log'
require 'ohai/mixin/from_file'
require 'ohai/mixin/command'
require 'ohai/mixin/string'
require 'mixlib/shellout'

require 'yajl'

module Ohai
  class System
    attr_accessor :data, :seen_plugins, :hints

    include Ohai::Mixin::FromFile
    include Ohai::Mixin::Command

    def initialize
      @data = Mash.new
      @seen_plugins = Hash.new
      @providers = Mash.new
      @plugin_path = ""
      @hints = Hash.new
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
      
      return @hints[name] if @hints[name]
      
      Ohai::Config[:hints_path].each do |path|
        filename = File.join(path, "#{name}.json")
        if File.exist?(filename)
          begin
            hash = @json_parser.parse(File.read(filename))
            @hints[name] = hash || Hash.new # hint should exist because the file did, even if it didn't contain anything
          rescue Yajl::ParseError => e
            Ohai::Log.error("Could not parse hint file at #{filename}: #{e.message}")
          end
        end
      end

      @hints[name]
    end
    

    def all_plugins
      require_plugin('os')

      Ohai::Config[:plugin_path].each do |path|
        [
          Dir[File.join(path, '*')],
          Dir[File.join(path, @data[:os], '**', '*')]
        ].flatten.each do |file|
          file_regex = Regexp.new("#{path}#{File::SEPARATOR}(.+).rb$")
          md = file_regex.match(file)
          if md
            plugin_name = md[1].gsub(File::SEPARATOR, "::")
            require_plugin(plugin_name) unless @seen_plugins.has_key?(plugin_name)
          end
        end
      end
      unless RUBY_PLATFORM =~ /mswin|mingw32|windows/
        # Catch any errant children who need to be reaped
        begin
          true while Process.wait(-1, Process::WNOHANG)
        rescue Errno::ECHILD
        end
      end
      true
    end

    def collect_providers(providers)
      refreshments = []
      if providers.is_a?(Mash)
        providers.keys.each do |provider|
          if provider.eql?("_providers")
            refreshments << providers[provider]
          else
            refreshments << collect_providers(providers[provider])
          end
        end
      else
        refreshments << providers
      end
      refreshments.flatten.uniq
    end

    def refresh_plugins(path = '/')
      parts = path.split('/')
      if parts.length == 0
        h = @providers
      else
        parts.shift if parts[0].length == 0
        h = @providers
        parts.each do |part|
          break unless h.has_key?(part)
          h = h[part]
        end
      end

      refreshments = collect_providers(h)
      Ohai::Log.debug("Refreshing plugins: #{refreshments.join(", ")}")
      
      # remove the hints cache
      @hints = Hash.new

      refreshments.each do |r|
        @seen_plugins.delete(r) if @seen_plugins.has_key?(r)
      end
      refreshments.each do |r|
        require_plugin(r) unless @seen_plugins.has_key?(r)
      end
    end

    def require_plugin(plugin_name, force=false)
      unless force
        return true if @seen_plugins[plugin_name]
      end

      if Ohai::Config[:disabled_plugins].include?(plugin_name)
        Ohai::Log.debug("Skipping disabled plugin #{plugin_name}")
        return false
      end

      @plugin_path = plugin_name

      filename = "#{plugin_name.gsub("::", File::SEPARATOR)}.rb"

      Ohai::Config[:plugin_path].each do |path|
        check_path = File.expand_path(File.join(path, filename))
        begin
          @seen_plugins[plugin_name] = true
          Ohai::Log.debug("Loading plugin #{plugin_name}")
          from_file(check_path)
          return true
        rescue Errno::ENOENT => e
          Ohai::Log.debug("No #{plugin_name} at #{check_path}")
        rescue SystemExit, Interrupt
          raise
        rescue Exception,Errno::ENOENT => e
          Ohai::Log.debug("Plugin #{plugin_name} threw exception #{e.inspect} #{e.backtrace.join("\n")}")
        end
      end
    end

    # Sneaky!  Lets us stub out require_plugin when testing plugins, but still
    # call the real require_plugin to kick the whole thing off.
    alias :_require_plugin :require_plugin

    # Serialize this object as a hash
    def to_json
      Yajl::Encoder.new.encode(@data)
    end

    # Pretty Print this object as JSON
    def json_pretty_print(item=nil)
      Yajl::Encoder.new(:pretty => true).encode(item || @data)
    end

    def attributes_print(a)
      data = @data
      a.split("/").each do |part|
        data = data[part]
      end
      raise ArgumentError, "I cannot find an attribute named #{a}!" if data.nil?
      case data
      when Hash,Mash,Array,Fixnum
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
