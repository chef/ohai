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

      provided_attributes.each do |attribute|
        attrs = @map
        parts = attribute.split('/')
        parts.shift if parts.length != 0 && parts[0].length == 0 # attribute begins with a '/'
        unless parts.length == 0
          parts.each do |part|
            raise Ohai::Exceptions::AttributeSyntaxError, "Attribute contains duplicate '/' characters: #{attribute}" if part.length == 0
            attrs[part] ||= Mash.new
            attrs = attrs[part]
          end
          attrs[:_plugins] ||= []
          attrs[:_plugins] << plugin
        end
      end
    end

    def find_providers_for(attributes)
      find_with_search_type(attributes, :strict)
    end

    def deep_find_providers_for(attributes)
      find_with_search_type(attributes, :deep)
    end

    def find_closest_providers_for(attributes)
      find_with_search_type(attributes, :closest)
    end

    def all_plugins(attribute_filter=nil)
      if attribute_filter.nil?
        collected = []
        collect_plugins_in(map, collected).uniq
      else
        deep_find_providers_for(Array(attribute_filter))
      end
    end

    private

    # Finds providers for each listed attribute using the given search
    # type. Search types behave as follows:
    #   1. :strict  => Returns a list of unique plugins explicitly
    #                  providing one or more of the listed attributes.
    #                  Raises Ohai::Exceptions::AttributeNotFound
    #                  error if at least one attribute does not exists
    #                  in the map. 
    #   2. :deep    => For each listed attribute, gathers all the
    #                  unique plugins providing that attribute and any
    #                  of its subattributes.
    #                  Raises Ohai::Exceptions::AttributeNotFound
    #                  error if at least one attribute does not exists
    #                  in the map.
    #   3. :closest => For each listed attribute, gathers the
    #                  providers for the most specific parent. If the
    #                  attribute exists in the mapping, its providers
    #                  are gathered. If the least specific parent does
    #                  not exist in the map an
    #                  Ohai::Exceptions::AttributeNotFound error is
    #                  raised. 
    def find_with_search_type(attributes, search_type=:strict)
      plugins = []
      attributes.each do |attribute|
        attrs = @map
        parts = attribute.split('/')
        parts.shift if parts.length != 0 && parts[0].length == 0
        parts.each do |part|
          unless attrs[part]
            break if search_type.eql?(:closest) && part != parts[0]
            raise Ohai::Exceptions::AttributeNotFound, "Cannot find plugin providing attribute \'#{attribute}\'"
          end
          attrs = attrs[part]
        end
        search_type.eql?(:deep) ? plugins += collect_plugins_in(attrs, []) : plugins += attrs[:_plugins]
      end
      plugins.uniq
    end

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
