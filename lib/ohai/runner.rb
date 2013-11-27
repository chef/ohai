#
# Author:: Claire McQuin (<claire@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'ohai/dsl/plugin'

module Ohai
  class Runner

    # safe_run: set to true if this runner will run plugins in
    # safe-mode. default false.
    def initialize(controller, safe_run = false)
      @attributes = controller.attributes
      @safe_run = safe_run
    end

    # runs this plugin and any un-run dependencies. if force is set to
    # true, then this plugin and its dependencies will be run even if
    # they have been run before.
    def run_plugin(plugin, force = false)
      unless plugin.kind_of?(Ohai::DSL::Plugin)
        raise ArgumentError, "Invalid plugin #{plugin} (must be an Ohai::DSL::Plugin or subclass)"
      end
      visited = [plugin]
      while !visited.empty?
        next_plugin = visited.pop

        next if next_plugin.has_run? unless force

        if visited.include?(next_plugin)
          raise Ohai::Exceptions::DependencyCycle, "Dependency cycle detected. Please refer to the following plugins: #{get_cycle(visited, p).join(", ") }"
        end

        dependency_providers = fetch_plugins(next_plugin.dependencies)
        dependency_providers.delete_if { |dep_plugin| (!force && dep_plugin.has_run?) || dep_plugin.eql?(next_plugin) }

        if dependency_providers.empty?
          @safe_run ? next_plugin.safe_run : next_plugin.run
        else
          visited << next_plugin << dependency_providers.first
        end
      end
    end

    # returns a list of plugins which provide the given attributes
    def fetch_plugins(attributes)
      @attributes.find_providers_for(attributes)
    end

    # given a list of plugins and the first plugin in the cycle,
    # returns the list of plugin source files responsible for the
    # cycle. does not include plugins that aren't a part of the cycle
    def get_cycle(plugins, cycle_start)
      cycle = plugins.drop_while { |plugin| !plugin.eql?(cycle_start) }
      names = []
      cycle.each { |plugin| names << plugin.name }
      names
    end

  end
end
