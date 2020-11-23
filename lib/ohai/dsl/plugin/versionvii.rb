# frozen_string_literal: true
#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

        # The source of the plugin on disk. This is an array since a plugin may exist for multiple
        # oses and this would include each of those os specific file paths
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

        # A block per os for actually performing data collection constructed
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

        # define data collection methodology per os
        #
        # @param os [Array<Symbol>] the list of oses to collect data for
        # @param block [block] the actual code to collect data for the specified os
        #
        def self.collect_data(*os_list, &block)
          os_list = [ :default ] if os_list.empty?
          os_list.flatten.each do |os|
            Ohai::Log.warn("collect_data already defined on os '#{os}' for #{self}, last plugin seen will be used") if data_collector.key?(os)
            data_collector[os] = block
          end
        end

        # @return [Array]
        def dependencies
          self.class.depends_attrs
        end

        def run_plugin
          collector = self.class.data_collector
          os = collect_os

          # :default - means any remote or local unix or windows host
          # :target  - means any remote API which is not unix/windows or otherwise rubyable (cisco switches, IPMI console, HTTP API, etc)
          #
          # Do not be confused by the fact that collectors tagged :target do not run against e.g. target-mode ubuntu boxes, that is not
          # what :target is intended for.  Also, do not be confused by the fact that collectors tagged :default do not run by default against
          # pure-target mode targets like switches.  That is all intended behavior, the names are problematic.  The :default nomenclature was
          # invented 10 years before target mode and we are stuck with it.
          #
          if collector.key?(os)
            instance_eval(&collector[os])
          elsif collector.key?(:default) && !nonruby_target?
            instance_eval(&collector[:default])
          elsif collector.key?(:target) && nonruby_target?
            instance_eval(&collector[:target])
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
          end
        end
      end
    end
  end
end
