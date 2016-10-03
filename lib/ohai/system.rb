#
# Author:: Adam Jacob (<adam@chef.io>)
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "info_getter/loader"
require "info_getter/log"
require "info_getter/mash"
require "info_getter/runner"
require "info_getter/dsl"
require "info_getter/mixin/command"
require "info_getter/mixin/os"
require "info_getter/mixin/string"
require "info_getter/mixin/constant_helper"
require "info_getter/provides_map"
require "info_getter/hints"
require "mixlib/shellout"

module info_getter
  class System
    include info_getter::Mixin::ConstantHelper

    attr_accessor :data
    attr_reader :config
    attr_reader :provides_map
    attr_reader :v6_dependency_solver

    def initialize(config = {})
      @plugin_path = ""
      @config = config
      reset_system
    end

    def reset_system
      @data = Mash.new
      @provides_map = ProvidesMap.new
      @v6_dependency_solver = Hash.new

      configure_info_getter
      configure_logging

      @loader = info_getter::Loader.new(self)
      @runner = info_getter::Runner.new(self, true)

      info_getter::Hints.refresh_hints()

      # Remove the previously defined plugins
      recursive_remove_constants(info_getter::NamedPlugin)
    end

    def [](key)
      @data[key]
    end

    def all_plugins(attribute_filter = nil)
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

      # Users who are migrating from info_getter 6 may give one or more info_getter 6 plugin
      # names as the +attribute_filter+. In this case we return early because
      # the v7 plugin provides map will not have an entry for this plugin.
      if attribute_filter && Array(attribute_filter).all? { |filter_item| have_v6_plugin?(filter_item) }
        return true
      end

      # Then run all the version 7 plugins
      begin
        @provides_map.all_plugins(attribute_filter).each do |plugin|
          @runner.run_plugin(plugin)
        end
      rescue info_getter::Exceptions::AttributeNotFound, info_getter::Exceptions::DependencyCycle => e
        info_getter::Log.error("Encountered error while running plugins: #{e.inspect}")
        raise
      end
    end

    def have_v6_plugin?(name)
      @v6_dependency_solver.values.any? { |v6plugin| v6plugin.name == name }
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
    def require_plugin(plugin_ref, force = false)
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
        rescue info_getter::Exceptions::AttributeNotFound
          info_getter::Log.debug("Can not find any v7 plugin that provides #{attribute}")
          plugins = [ ]
        end
      end

      if plugins.empty?
        raise info_getter::Exceptions::DependencyNotFound, "Can not find a plugin for dependency #{plugin_ref}"
      else
        plugins.each do |plugin|
          begin
            @runner.run_plugin(plugin)
          rescue SystemExit, Interrupt
            raise
          rescue info_getter::Exceptions::DependencyCycle, info_getter::Exceptions::AttributeNotFound => e
            info_getter::Log.error("Encountered error while running plugins: #{e.inspect}")
            raise
          rescue Exception, Errno::ENOENT => e
            info_getter::Log.debug("Plugin #{plugin.name} threw exception #{e.inspect} #{e.backtrace.join("\n")}")
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
    def refresh_plugins(attribute_filter = nil)
      info_getter::Hints.refresh_hints()
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
    def json_pretty_print(item = nil)
      FFI_Yajl::Encoder.new(pretty: true, validate_utf8: false).encode(item || @data)
    end

    def attributes_print(a)
      data = @data
      a.split("/").each do |part|
        data = data[part]
      end
      raise ArgumentError, "I cannot find an attribute named #{a}!" if data.nil?
      case data
      when Hash, Mash, Array, Fixnum
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

    private

    def configure_info_getter
      info_getter::Config.merge_deprecated_config
      info_getter.config.merge!(@config)

      if info_getter.config[:directory] &&
          !info_getter.config[:plugin_path].include?(info_getter.config[:directory])
        info_getter.config[:plugin_path] << info_getter.config[:directory]
      end

      info_getter::Log.debug("Running info_getter with the following configuration: #{info_getter.config.configuration}")
    end

    def configure_logging
      return if info_getter::Log.configured?

      info_getter::Log.init(info_getter.config[:log_location])

      if info_getter.config[:log_level] == :auto
        info_getter::Log.level = :info
      else
        info_getter::Log.level = info_getter.config[:log_level]
      end
    end
  end
end
