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
require 'ohai/dsl'
require 'ohai/mixin/command'
require 'ohai/mixin/os'
require 'ohai/mixin/string'
require 'ohai/mixin/constant_helper'
require 'ohai/provides_map'
require 'ohai/hints'
require 'mixlib/shellout'

module Ohai
  class System
    include Ohai::Mixin::ConstantHelper

    attr_accessor :data
    attr_reader :provides_map
    attr_reader :v6_dependency_solver

    def initialize
      @plugin_path = ""
      reset_system
    end

    def reset_system
      @data = Mash.new
      @provides_map = ProvidesMap.new

      @v6_dependency_solver = Hash.new

      # configure logging
      Ohai::Log.init(Ohai::Config[:log_location])
      Ohai::Log.level = Ohai::Config[:log_level]

      @loader = Ohai::Loader.new(self)
      @runner = Ohai::Runner.new(self, true)

      Ohai::Hints.refresh_hints()

      # Remove the previously defined plugins
      recursive_remove_constants(Ohai::NamedPlugin)
    end

    def [](key)
      @data[key]
    end

    def all_plugins(attribute_filter=nil)
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
      # First run all the version 6 plugins
      @v6_dependency_solver.values.each do |v6plugin|
        @runner.run_plugin(v6plugin)
      end

      # Users who are migrating from ohai 6 may give one or more Ohai 6 plugin
      # names as the +attribute_filter+. In this case we return early because
      # the v7 plugin provides map will not have an entry for this plugin.
      if attribute_filter and Array(attribute_filter).all? {|filter_item| have_v6_plugin?(filter_item) }
        return true
      end

      # Then run all the version 7 plugins
      begin
        @provides_map.all_plugins(attribute_filter).each { |plugin|
          @runner.run_plugin(plugin)
        }
      rescue Ohai::Exceptions::AttributeNotFound, Ohai::Exceptions::DependencyCycle => e
        Ohai::Log.error("Encountered error while running plugins: #{e.inspect}")
        raise
      end
    end

    def have_v6_plugin?(name)
      @v6_dependency_solver.values.any? {|v6plugin| v6plugin.name == name }
    end

    def pathify_v6_plugin(plugin_name)
      path_components = plugin_name.split("::")
      File.join(path_components) + ".rb"
    end

    #
    # Below APIs are from V6.
    # Make sure that you are not breaking backwards compatibility
    # if you are changing any of the APIs below.
    #
    def require_plugin(plugin_ref, force=false)
      plugins = [ ]
      # This method is only callable by version 6 plugins.
      # First we check if there exists a v6 plugin that fulfills the dependency.
      if @v6_dependency_solver.has_key? pathify_v6_plugin(plugin_ref)
        # Note that: partial_path looks like Plugin::Name
        # keys for @v6_dependency_solver are in form 'plugin/name.rb'
        plugins << @v6_dependency_solver[pathify_v6_plugin(plugin_ref)]
      else
        # While looking up V7 plugins we need to convert the plugin_ref to an attribute.
        attribute = plugin_ref.gsub("::", "/")
        begin
          plugins = @provides_map.find_providers_for([attribute])
        rescue Ohai::Exceptions::AttributeNotFound
          Ohai::Log.debug("Can not find any v7 plugin that provides #{attribute}")
          plugins = [ ]
        end
      end

      if plugins.empty?
        raise Ohai::Exceptions::DependencyNotFound, "Can not find a plugin for dependency #{plugin_ref}"
      else
        plugins.each do |plugin|
          begin
            @runner.run_plugin(plugin)
          rescue SystemExit, Interrupt
            raise
          rescue Ohai::Exceptions::DependencyCycle, Ohai::Exceptions::AttributeNotFound => e
            Ohai::Log.error("Encountered error while running plugins: #{e.inspect}")
            raise
          rescue Exception,Errno::ENOENT => e
            Ohai::Log.debug("Plugin #{plugin.name} threw exception #{e.inspect} #{e.backtrace.join("\n")}")
          end
        end
      end
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
    def refresh_plugins(attribute_filter=nil)
      Ohai::Hints.refresh_hints()
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
    def json_pretty_print(item=nil)
      FFI_Yajl::Encoder.new(pretty: true, validate_utf8: false).encode(item || @data)
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
