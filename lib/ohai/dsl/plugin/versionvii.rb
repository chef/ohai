#
# Author:: Serdar Sutay (<serdar@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
            Ohai::Log.debug("No data to collect for plugin #{self.name}. Continuing...")
          end
        end

        def provides(*paths)
          Ohai::Log.warn("[UNSUPPORTED OPERATION] \'provides\' is no longer supported in a \'collect_data\' context. Please specify \'provides\' before collecting plugin data. Ignoring command \'provides #{paths.join(", ")}")
        end

        def require_plugin(*args)
          Ohai::Log.warn("[UNSUPPORTED OPERATION] \'require_plugin\' is no longer supported. Please use \'depends\' instead.\nIgnoring plugin(s) #{args.join(", ")}")
        end
      end
    end
  end
end
