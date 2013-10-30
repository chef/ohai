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
      visited = [plugin]
      while !visited.empty?
        p = visited.pop

        next if p.has_run? unless force

        if visited.include?(p)
          raise Ohai::Exceptions::DependencyCycle, "Dependency cycle detected. Please refer to the following plugins: #{get_cycle(visited, p).join(", ") }"
        end

        dependency_providers = fetch_plugins(p.dependencies)
        dependency_providers.delete_if { |plugin| (!force && plugin.has_run?) || plugin.eql?(p) }

        if dependency_providers.empty?
          @safe_run ? p.safe_run : p.run
        else
          visited << p << dependency_providers.first
        end
      end
    end

    # returns a list of plugins which provide the given attributes
    def fetch_plugins(attributes)
      plugins = []
      attributes.each do |attribute|
        attrs = @attributes
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
