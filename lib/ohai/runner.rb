#
# Author:: Claire McQuin (<claire@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License. You may
# obtain a copy of the license at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either expressed or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License
#

require "ohai/dsl"

module Ohai
  class Runner

    # safe_run: set to true if this runner will run plugins in
    # safe-mode. default false.
    def initialize(controller, safe_run = false)
      @provides_map = controller.provides_map
      @safe_run = safe_run
    end

    # Runs plugins and any un-run dependencies.
    # If force is set to true, then this plugin and its dependencies
    # will be run even if they have been run before.
    def run_plugin(plugin)
      unless plugin.kind_of?(Ohai::DSL::Plugin)
        raise Ohai::Exceptions::InvalidPlugin, "Invalid plugin #{plugin} (must be an Ohai::DSL::Plugin or subclass)"
      end

      begin
        case plugin.version
        when :version7
          run_v7_plugin(plugin)
        when :version6
          run_v6_plugin(plugin)
        else
          raise Ohai::Exceptions::InvalidPlugin, "Invalid plugin version #{plugin.version} for plugin #{plugin}"
        end
      rescue Ohai::Exceptions::Error
        raise
      rescue SystemExit # abort or exit from plug-in should exit Ohai with failure code
        raise
      rescue Exception, Errno::ENOENT => e
        Ohai::Log.debug("Plugin #{plugin.name} threw exception #{e.inspect} #{e.backtrace.join("\n")}")
      end
    end

    def run_v6_plugin(plugin)
      return true if plugin.has_run?

      @safe_run ? plugin.safe_run : plugin.run
    end

    def run_v7_plugin(plugin)
      visited = [ plugin ]
      until visited.empty?
        next_plugin = visited.pop

        next if next_plugin.has_run?

        if visited.include?(next_plugin)
          raise Ohai::Exceptions::DependencyCycle, "Dependency cycle detected. Please refer to the following plugins: #{get_cycle(visited, plugin).join(", ")}"
        end

        dependency_providers = fetch_plugins(next_plugin.dependencies)

        # Remove the already ran plugins from dependencies if force is not set
        # Also remove the plugin that we are about to run from dependencies as well.
        dependency_providers.delete_if do |dep_plugin|
          dep_plugin.has_run? || dep_plugin.eql?(next_plugin)
        end

        if dependency_providers.empty?
          @safe_run ? next_plugin.safe_run : next_plugin.run
        else
          visited << next_plugin << dependency_providers.first
        end
      end
    end

    def fetch_plugins(attributes)
      @provides_map.find_closest_providers_for(attributes)
    end

    # Given a list of plugins and the first plugin in the cycle,
    # returns the list of plugin source files responsible for the
    # cycle. Does not include plugins that aren't a part of the cycle
    def get_cycle(plugins, cycle_start)
      cycle = plugins.drop_while { |plugin| !plugin.eql?(cycle_start) }
      names = []
      cycle.each { |plugin| names << plugin.name }
      names
    end

  end
end
