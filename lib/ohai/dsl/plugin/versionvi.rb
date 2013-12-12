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
      class VersionVI < Plugin
        attr_reader :version

        def initialize(controller, source)
          super(controller, source)
          @version = :version6
        end

        def name
          self.class.name.split("Ohai::NamedPlugin::")[1]
        end

        def self.version
          :version6
        end

        def self.collect_contents(contents)
          define_method(:run_plugin) { self.instance_eval(contents) }
        end

        def provides(*paths)
          provides_map.set_providers_for(self, paths)
        end

        def require_plugin(*args)
          @controller.require_plugin(*args)
        end

      end
    end
  end
end

