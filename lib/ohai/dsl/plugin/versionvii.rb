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
      class VersionVII < Plugin
        attr_reader :version
        attr_reader :source

        def initialize(data)
          super(data)
          @source = self.class.sources
          @version = :version7
        end

        def name
          self.class.name.split("Ohai::NamedPlugin::")[1].to_sym
        end

        def self.version
          :version7
        end

        def self.sources
          @source_list ||= []
        end

        def self.provides_attrs
          @provides_attrs ||= []
        end

        def self.depends_attrs
          @depends_attrs ||= []
        end

        def self.data_collector
          @data_collector ||= Mash.new
        end

        def self.provides(*attrs)
          attrs.each do |attr|
            provides_attrs << attr unless provides_attrs.include?(attr)
          end
        end

        def self.depends(*attrs)
          attrs.each do |attr|
            depends_attrs << attr unless depends_attrs.include?(attr)
          end
        end

        def self.collect_data(platform = :default, *other_platforms, &block)
          [platform, other_platforms].flatten.each do |plat|
            if data_collector.has_key?(plat)
              raise Ohai::Exceptions::IllegalPluginDefinition, "collect_data already defined on platform #{plat}"
            else
              data_collector[plat] = block
            end
          end
        end

        def dependencies
          self.class.depends_attrs
        end

        def run_plugin
          collector = self.class.data_collector
          platform = collect_os

          if collector.has_key?(platform)
            self.instance_eval(&collector[platform])
          elsif collector.has_key?(:default)
            self.instance_eval(&collector[:default])
          else
            Ohai::Log.debug("Plugin #{self.name}: No data to collect. Skipping...")
          end
        end

        def provides(*paths)
          Ohai::Log.warn("[UNSUPPORTED OPERATION] \'provides\' is no longer supported in a \'collect_data\' context. Please specify \'provides\' before collecting plugin data. Ignoring command \'provides #{paths.join(", ")}")
        end

        def require_plugin(*args)
          Ohai::Log.warn("[UNSUPPORTED OPERATION] \'require_plugin\' is no longer supported. Please use \'depends\' instead.\nIgnoring plugin(s) #{args.join(", ")}")
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
          parts = self.name.to_s.split(/([A-Z][a-z]+)/)
          # ["DMI"] => ["DMI"]
          # ["", "Memory"] => ["Memory"]
          # ["", "Network", "", "Listeners"] => ["Network", "Listeners"]
          # ["SSH", "Host", "", "Key"] => ["SSH", "Host", "Key"]
          parts.delete_if { |part| part.empty? }
          # ["DMI"] => :dmi
          # ["Memory"] => :memory
          # ["Network", "Listeners"] => :network_listeners
          # ["SSH", "Host", "Key"] => :ssh_host_key
          snake_case_name = parts.map { |part| part.downcase }.join("_").to_sym

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
