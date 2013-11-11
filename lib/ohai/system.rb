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
  class System
    attr_accessor :data
    attr_reader :attributes
    attr_reader :hints
    attr_reader :v6_dependency_solver

    def initialize
      @data = Mash.new
      @attributes = Mash.new
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
            # we found a plugin file, load it
            plugin = @loader.load_plugin(file)
            if (plugin.version.eql?(:version6))
              # we loaded a v6 plugin, check if a previous plugin path
              # already defined this plugin
              plugin_name = md[1].gsub(File::SEPARATOR, "::")
              unless @v6_dependency_solver.has_key?(plugin_name)
                # this plugin has not been defined before, save it
                @v6_dependency_solver[plugin_name] = plugin
              else
                # this plugin has already been defined, ignore it
                Ohai::Log.debug("Already loaded plugin #{plugin_name}")
              end
            end
          end
          true
        end
      end
    end

    def run_plugins(safe = true, force = false)
      # run version 6 plugins
      @v6_dependency_solver.each do |v6name, |
        require_plugin(v6name, force)
      end

      # collect and run version 7 plugins
      plugins = collect_plugins(@attributes)
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
    def require_plugin(plugin_name, force = false)
      # check if plugin_name is a v6 plugin, if not then we'll search
      # for a matching v7 plugin
      unless plugin = @v6_dependency_solver[plugin_name]
        v7name = ""
        parts = plugin_name.split("::")
        parts.each do |part|
          next if part.empty?
          next if part.eql?(Ohai::Mixin::OS.collect_os)
          v7name << part.capitalize
        end

        if Ohai::NamedPlugin.strict_const_defined?(v7name.to_sym)
          plugin = Ohai::NamedPlugin.const_get(v7name.to_sym)
        else
          # could not find a suitable v7 plugin, try to load the plugin
          plugin = plugin_for(plugin_name)
        end
      end

      unless force
        return true if plugin && plugin.has_run?
      end

      if Ohai::Config[:disabled_plugins].include?(plugin_name)
        Ohai::Log.debug("Skipping disabled plugin #{plugin_name}")
        return false
      end

      unless plugin
        Ohai::Log.debug("No #{plugin_name} found in #{Ohai::Config[:plugin_path].join(", ")}")
        return false
      end

      begin
        if plugin.version.eql?(:version7)
          @runner.run_plugin(plugin, force)
          
          # to emulate v6 plugin behavior, we follow the commonly-used
          # pattern of running the platform-specific plugin block and
          # following up with the default-behavior block. if a
          # platform-specific block exists, Ohai::Runner will have run
          # it above + resolved any dependencies. we'll inspect the
          # plugin to see if a :default block also exists and run it
          collector = plugin.class.data_collector
          if collector.has_key?(:default) && collector.has_key?(Ohai::Mixin::OS.collect_os)
            plugin.instance_eval(&collector[:default])
          end
        else
          # v6 plugins run in safe-mode
          plugin.safe_run
        end
        true
      rescue SystemExit, Interrupt
        raise
      rescue Ohai::Exceptions::AttributeNotFound, Ohai::Exceptions::DependencyCycle => e
        Ohai::Log.error("Encountered error while running plugins: #{e.inspect}")
        raise
      rescue Exception,Errno::ENOENT => e
        Ohai::Log.debug("Plugin #{plugin_name} threw exception #{e.inspect} #{e.backtrace.join("\n")}")
      end
    end

    def plugin_for(plugin_name)
      filename = "#{plugin_name.gsub("::", File::SEPARATOR)}.rb"

      plugin = nil
      Ohai::Config[:plugin_path].each do |path|
        check_path = File.expand_path(File.join(path, filename))
        if File.exist?(check_path)
          Ohai::Log.debug("Loading plugin #{check_path}")
          plugin = @loader.load_plugin(check_path)
          if (plugin.version.eql?(:version6))
            # we loaded a v6 plugin, check if a previous plugin path
            # already defined this plugin
            unless @v6_dependency_solver.has_key?(plugin_name)
              # this plugin has not been defined before, save it
              @v6_dependency_solver[plugin_name] = plugin
            else
              # this plugin has already been defined, ignore it
              Ohai::Log.debug("Already loaded plugin #{plugin_name}")
            end
          end
          break
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
