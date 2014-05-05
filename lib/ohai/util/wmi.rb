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

require 'win32ole'
require 'ohai/util/wmi/wmi_instance'

module Ohai
  module Util
    class Wmi

      def self.query(wql_query, namespace = nil)
        results = start_query(namespace, wql_query)
        
        result_set = []

        results.each do | result | 
          result_set.push(Wmi::Instance.new(result))
        end
        
        result_set
      end

      def self.instances_of(wmi_class, namespace = nil)
        query("select * from #{wmi_class}")
      end

      def self.first_of(wmi_class, namespace = nil)
        query_result = start_query(namespace, "select * from #{wmi_class}")
        first_result = nil
        query_result.each do | record |
          first_result = record
          break
        end
        first_result.nil? ? nil : Wmi::Instance.new(first_result)
      end

      private

      def self.start_query(namespace, wql_query)
        connection = new_connection(namespace)
        connection.ExecQuery(wql_query)
      end

      def self.new_connection(namespace)
        locator = WIN32OLE.new("WbemScripting.SWbemLocator")
        locator.ConnectServer('.', namespace.nil? ? 'root/cimv2' : namespace)
      end

      def self.wmi_result_to_hash(wmi_object)
        property_map = {}
        wmi_object.properties_.each do |property|
          property_map[property.name.downcase] = wmi_object.invoke(property.name)
        end

        property_map[:wmi_object] = wmi_object

        property_map
      end
    end
  end
end

