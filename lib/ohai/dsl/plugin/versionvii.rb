#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

module Ohai
  module DSL
    class Plugin
      # The class for the "Version 7" plugin format we introduced in Ohai 7. This is the 2nd
      # generation of Ohai plugin and the previous generation (V6) was removed in Ohai 14
      class VersionVII < Plugin
        attr_reader :version
        attr_reader :source

        def initialize(data, logger)
          super(data, logger)
          @source = self.class.sources
          @version = :version7
        end

        # the plugin name we use through Ohai (Foo) vs. the class name (Ohai::NamedPlugin::Foo)
        #
        # @return [String]
        def name
          self.class.name.split("Ohai::NamedPlugin::")[1].to_sym
        end

        # return that we're a v7 plugin
        #
        # @return [Symbol]
        def self.version
          :version7
        end

        # the source of the plugin on disk. This is an array since a plugin may exist for multiple platforms and this would include each of those platform specific file paths
        #
        # @return [Array]
        def self.sources
          @source_list ||= []
        end

        def self.provides_attrs
          @provides_attrs ||= []
        end

        def self.depends_attrs
          @depends_attrs ||= []
        end

        # A block per platform for actually performing data collection constructed
        # by the collect_data method
        #
        # @return [Mash]
        def self.data_collector
          @data_collector ||= Mash.new
        end

        # set the attributes provided by the plugin
        #
        # @param attrs [Array]
        def self.provides(*attrs)
          attrs.each do |attr|
            provides_attrs << attr unless provides_attrs.include?(attr)
          end
        end

        # set the attributes depended on by the plugin
        #
        # @param attrs [Array]
        def self.depends(*attrs)
          attrs.each do |attr|
            depends_attrs << attr unless depends_attrs.include?(attr)
          end
        end

        # set the plugin optional state
        #
        # @param opt [Boolean]
        def self.optional(opt = true)
          @optional = opt
        end

        # check if the plugin is optional
        #
        # @return [Boolean]
        def self.optional?
          !!@optional
        end

        # define data collection methodology per platform
        #
        # @param platform [Symbol] the platform to collect data for
        # @param other_platforms [Array] additional platforms to collect data for
        # @param block [block] the actual code to collect data for the specified platforms
        def self.collect_data(platform = :default, *other_platforms, &block)
          [platform, other_platforms].flatten.each do |plat|
            Ohai::Log.warn("collect_data already defined on platform '#{plat}' for #{self}, last plugin seen will be used") if data_collector.key?(plat)
            data_collector[plat] = block
          end
        end

        # @return [Array]
        def dependencies
          self.class.depends_attrs
        end

        def run_plugin
          collector = self.class.data_collector
          platform = collect_os

          if collector.key?(platform)
            instance_eval(&collector[platform])
          elsif collector.key?(:default)
            instance_eval(&collector[:default])
          else
            logger.trace("Plugin #{name}: No data to collect. Skipping...")
          end
        end

        def optional?
          self.class.optional?
        end

        def provides(*paths)
          logger.warn("[UNSUPPORTED OPERATION] \'provides\' is no longer supported in a \'collect_data\' context. Please specify \'provides\' before collecting plugin data. Ignoring command \'provides #{paths.join(", ")}")
        end

        def require_plugin(*args)
          logger.warn("[UNSUPPORTED OPERATION] \'require_plugin\' is no longer supported. Please use \'depends\' instead.\nIgnoring plugin(s) #{args.join(", ")}")
        end

        def configuration(option, *options)
          return nil if plugin_config.nil? || !plugin_config.key?(option)

          value = plugin_config[option]
          options.each do |opt|
            return nil unless value.key?(opt)

            value = value[opt]
          end
          value
        end

        private

        def plugin_config
          @plugin_config ||= fetch_plugin_config
        end

        def fetch_plugin_config
          # DMI => ["DMI"]
          # Memory => ["", "Memory"]
          # NetworkListeners => ["", "Network", "", "Listeners"]
          # SSHHostKey => ["SSH", "Host", "", "Key"]
          parts = name.to_s.split(/([A-Z][a-z]+)/)
          # ["DMI"] => ["DMI"]
          # ["", "Memory"] => ["Memory"]
          # ["", "Network", "", "Listeners"] => ["Network", "Listeners"]
          # ["SSH", "Host", "", "Key"] => ["SSH", "Host", "Key"]
          parts.delete_if(&:empty?)
          # ["DMI"] => :dmi
          # ["Memory"] => :memory
          # ["Network", "Listeners"] => :network_listeners
          # ["SSH", "Host", "Key"] => :ssh_host_key
          snake_case_name = parts.map(&:downcase).join("_").to_sym

          # Plugin names in config hashes are auto-vivified, so we check with
          # key? to avoid falsely instantiating a configuration hash.
          if Ohai.config[:plugin].key?(snake_case_name)
            Ohai.config[:plugin][snake_case_name]
          else
            nil
          end
        end
      end
    end
  end
end
