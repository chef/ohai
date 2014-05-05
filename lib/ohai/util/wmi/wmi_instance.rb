#
# Author:: Adam Edwards (<adamed@getchef.com>)
# Copyright:: Copyright 2014 Chef Software, Inc.
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
module Ohai
  module Util
   class Wmi
      class Instance

        attr_reader :wmi_ole_object

        def initialize(wmi_ole_object)
          @wmi_ole_object = wmi_ole_object
          @property_map = self.class.wmi_ole_object_to_hash(wmi_ole_object)
        end

        def [](key)
          @property_map[key]
        end

        private

        def self.wmi_ole_object_to_hash(wmi_object)
          property_map = {}
          wmi_object.properties_.each do |property|
            property_map[property.name.downcase] = wmi_object.invoke(property.name)
          end

          property_map[:wmi_object] = wmi_object

          property_map.freeze
        end

      end
    end
  end
end
