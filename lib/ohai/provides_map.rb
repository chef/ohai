#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008, 2013 Opscode, Inc.
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

require 'ohai/mash'
require 'ohai/exception'
require 'ohai/mixin/os'
require 'ohai/dsl'

module Ohai
  class ProvidesMap

    attr_reader :map

    def initialize
      @map = Mash.new
    end

    def set_providers_for(plugin, provided_attributes)
      unless plugin.kind_of?(Ohai::DSL::Plugin)
        raise ArgumentError, "set_providers_for only accepts Ohai Plugin classes (got: #{plugin})"
      end
      provided_attributes.each do |attr|
        parts = attr.split('/')
        a = map
        unless parts.length == 0
          parts.shift if parts[0].length == 0
          parts.each do |part|
            a[part] ||= Mash.new
            a = a[part]
          end
        end

        a[:_plugins] ||= []
        a[:_plugins] << plugin
      end
    end

    def find_providers_for(attributes)
      plugins = []
      attributes.each do |attribute|
        attrs = map
        parts = attribute.split('/')
        parts.each do |part|
          next if part == Ohai::Mixin::OS.collect_os
          raise Ohai::Exceptions::AttributeNotFound, "Cannot find plugin providing attribute \'#{attribute}\'" unless attrs[part]
          attrs = attrs[part]
        end
        plugins += collect_plugins_in(attrs, [])
      end
      plugins.uniq
    end


    def all_plugins(attribute_filter=nil)
      if attribute_filter.nil?
        collected = []
        collect_plugins_in(map, collected).uniq
      else
        find_providers_for(Array(attribute_filter))
      end
    end

    private

    # Takes a section of the map, recursively searches for a `_plugins` key
    # to find all the plugins in that section of the map. If given the whole
    # map, it will find all of the plugins that have at least one provided
    # attribute.
    def collect_plugins_in(provides_map, collected)
      provides_map.keys.each do |plugin|
        if plugin.eql?("_plugins")
          collected.concat(provides_map[plugin])
        else
          collect_plugins_in(provides_map[plugin], collected)
        end
      end
      collected
    end
  end
end

