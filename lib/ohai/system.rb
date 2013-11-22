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

require 'ohai/loader'
require 'ohai/log'
require 'ohai/mash'
require 'ohai/runner'
require 'ohai/dsl/plugin'
require 'ohai/mixin/from_file'
require 'ohai/mixin/command'
require 'ohai/mixin/os'
require 'ohai/mixin/string'
require 'mixlib/shellout'

require 'yajl'

module Ohai

  class ProvidesMap

    attr_reader :map

    def initialize
      @map = Mash.new
    end

    def set_providers_for(plugin, provided_attributes)
      unless plugin.kind_of?(Ohai::DSL::Plugin)
        raise ArgumentError, "set_providers_for only accepts Ohai Plugin classes (got: #{plugin})"
      end
      provided_attributes.each do |attr|
        parts = attr.split('/')
        a = map
        unless parts.length == 0
          parts.shift if parts[0].length == 0
          parts.each do |part|
            a[part] ||= Mash.new
            a = a[part]
          end
        end

        a[:_plugins] ||= []
        a[:_plugins] << plugin
      end
    end

    def find_providers_for(attributes)
      plugins = []
      attributes.each do |attribute|
        attrs = map
        parts = attribute.split('/')
        parts.each do |part|
          next if part == Ohai::Mixin::OS.collect_os
          raise Ohai::Exceptions::AttributeNotFound, "Cannot find plugin providing attribute \'#{attribute}\'" unless attrs[part]
          attrs = attrs[part]
        end
        plugins << attrs[:_plugins]
        plugins.flatten!
      end
      plugins.uniq
    end


    def all_plugins
      collected = []
      collect_plugins_in(map, collected).uniq
    end

    # TODO: change this to has_provider? or something domain specific.
    def has_key?(key)
      @map.has_key?(key)
    end

    # TODO: refactor out direct access to the map (mostly only occurs in test code)
    def [](key)
      @map[key]
    end

    # TODO: refactor out direct access to the map (mostly only occurs in test code)
    def []=(key, value)
      @map[key] = value
    end

    private

    def collect_plugins_in(provides_map, collected)
      provides_map.keys.each do |plugin|
        if plugin.eql?("_plugins")
          collected.concat(provides_map[plugin])
        else
          collect_plugins_in(provides_map[plugin], collected)
        end
      end
      collected
    end
  end

  class System
    attr_accessor :data
    attr_reader :attributes
    attr_reader :hints
    attr_reader :v6_dependency_solver

    def initialize
      @data = Mash.new
      @attributes = ProvidesMap.new

      @hints = Hash.new
      @v6_dependency_solver = Hash.new
      @plugin_path = ""

      @loader = Ohai::Loader.new(self)
      @runner = Ohai::Runner.new(self, true)
    end

    def [](key)
      @data[key]
    end

    #=============================================
    #  Version 7 system commands
    #=============================================
    def all_plugins
      load_plugins
      run_plugins(true)
    end

    def load_plugins
      Ohai::Config[:plugin_path].each do |path|
        [
         Dir[File.join(path, '*')],
         Dir[File.join(path, Ohai::Mixin::OS.collect_os, '**', '*')]
        ].flatten.each do |file|
          file_regex = Regexp.new("#{File.expand_path(path)}#{File::SEPARATOR}(.+).rb$")
          md = file_regex.match(file)
          if md
            plugin_name = md[1].gsub(File::SEPARATOR, "::")
            unless @v6_dependency_solver.has_key?(plugin_name)
              plugin = @loader.load_plugin(file, plugin_name)
              @v6_dependency_solver[plugin_name] = plugin unless plugin.nil?
            else
              Ohai::Log.debug("Already loaded plugin at #{file}")
            end
          end
        end
      end
      true
    end

    def run_plugins(safe = false, force = false)
      # collect and run version 6 plugins
      v6plugins = []
      @v6_dependency_solver.each { |plugin_name, plugin| v6plugins << plugin if plugin.version.eql?(:version6) }
      v6plugins.each do |v6plugin|
        if !v6plugin.has_run? || force
          safe ? v6plugin.safe_run : v6plugin.run
        end
      end

      # collect and run version 7 plugins
      plugins = @attributes.all_plugins

      begin
        plugins.each { |plugin| @runner.run_plugin(plugin, force) }
      rescue Ohai::Exceptions::AttributeNotFound, Ohai::Exceptions::DependencyCycle => e
        Ohai::Log.error("Encountered error while running plugins: #{e.inspect}")
        raise
      end
      true
    end

    def collect_plugins(plugins)
      collected = []
      if plugins.is_a?(Mash)
        # TODO: remove this branch
        plugins.keys.each do |plugin|
          if plugin.eql?("_plugins")
            collected << plugins[plugin]
          else
            collected << collect_plugins(plugins[plugin])
          end
        end
      else
        collected << plugins
      end
      collected.flatten.uniq
    end

    #=============================================
    # Version 6 system commands
    #=============================================
    def require_plugin(plugin_name, force=false)
      unless force
        plugin = @v6_dependency_solver[plugin_name]
        return true if plugin && plugin.has_run?
      end

      if Ohai::Config[:disabled_plugins].include?(plugin_name)
        Ohai::Log.debug("Skipping disabled plugin #{plugin_name}")
        return false
      end

      if plugin = @v6_dependency_solver[plugin_name] or plugin = plugin_for(plugin_name)
        begin
          plugin.version.eql?(:version7) ? @runner.run_plugin(plugin, force) : plugin.safe_run
          true
        rescue SystemExit, Interrupt
          raise
        rescue DependencyCycleError, NoAttributeError => e
          Ohai::Log.error("Encountered error while running plugins: #{e.inspect}")
          raise
        rescue Exception,Errno::ENOENT => e
          Ohai::Log.debug("Plugin #{plugin_name} threw exception #{e.inspect} #{e.backtrace.join("\n")}")
        end
      else
        Ohai::Log.debug("No #{plugin_name} found in #{Ohai::Config[:plugin_path]}")
      end
    end

    def plugin_for(plugin_name)
      filename = "#{plugin_name.gsub("::", File::SEPARATOR)}.rb"

      plugin = nil
      Ohai::Config[:plugin_path].each do |path|
        check_path = File.expand_path(File.join(path, filename))
        if File.exist?(check_path)
          plugin = @loader.load_plugin(check_path, plugin_name)
          @v6_dependency_solver[plugin_name] = plugin
          break
        else
          next
        end
      end
      plugin
    end

    # todo: fix for running w/new internals
    # add updated function to v7?
    def refresh_plugins(path = '/')
      parts = path.split('/')
      if parts.length == 0
        h = @metadata
      else
        parts.shift if parts[0].length == 0
        h = @metadata
        parts.each do |part|
          break unless h.has_key?(part)
          h = h[part]
        end
      end

      refreshments = collect_plugins(h)
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

    #=============================================
    # For outputting an Ohai::System object
    #=============================================
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

  end
end
