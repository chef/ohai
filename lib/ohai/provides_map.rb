#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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

require "ohai/mash"
require "ohai/exception"
require "ohai/mixin/os"
require "ohai/dsl"

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
        parts = normalize_and_validate(attribute)
        parts.each do |part|
          attrs[part] ||= Mash.new
          attrs = attrs[part]
        end
        attrs[:_plugins] ||= []
        attrs[:_plugins] << plugin
      end
    end

    # gather plugins providing exactly the attributes listed
    def find_providers_for(attributes)
      plugins = []
      attributes.each do |attribute|
        attrs = select_subtree(@map, attribute)
        raise Ohai::Exceptions::AttributeNotFound, "No such attribute: \'#{attribute}\'" unless attrs
        raise Ohai::Exceptions::ProviderNotFound, "Cannot find plugin providing attribute: \'#{attribute}\'" unless attrs[:_plugins]
        plugins += attrs[:_plugins]
      end
      plugins.uniq
    end

    # This function is used to fetch the plugins for the attributes specified
    # in the CLI options to Ohai.
    # It first attempts to find the plugins for the attributes
    # or the sub attributes given.
    # If it can't find any, it looks for plugins that might
    # provide the parents of a given attribute and returns the
    # first parent found.
    def deep_find_providers_for(attributes)
      plugins = []
      attributes.each do |attribute|
        attrs = select_subtree(@map, attribute)

        unless attrs
          attrs = select_closest_subtree(@map, attribute)

          unless attrs
            raise Ohai::Exceptions::AttributeNotFound, "No such attribute: \'#{attribute}\'"
          end
        end

        collect_plugins_in(attrs, plugins)
      end

      plugins.uniq
    end

    # This function is used to fetch the plugins from
    # 'depends "languages"' statements in plugins.
    # It gathers plugins providing each of the attributes listed, or the
    # plugins providing the closest parent attribute
    def find_closest_providers_for(attributes)
      plugins = []
      attributes.each do |attribute|
        parts = normalize_and_validate(attribute)
        raise Ohai::Exceptions::AttributeNotFound, "No such attribute: \'#{attribute}\'" unless @map[parts[0]]
        attrs = select_closest_subtree(@map, attribute)
        raise Ohai::Exceptions::ProviderNotFound, "Cannot find plugin providing attribute: \'#{attribute}\'" unless attrs
        plugins += attrs[:_plugins]
      end
      plugins.uniq
    end

    def all_plugins(attribute_filter = nil)
      if attribute_filter.nil?
        collected = []
        collect_plugins_in(map, collected).uniq
      else
        deep_find_providers_for(Array(attribute_filter))
      end
    end

    private

    def normalize_and_validate(attribute)
      raise Ohai::Exceptions::AttributeSyntaxError, "Attribute contains duplicate '/' characters: #{attribute}" if attribute =~ /\/\/+/
      raise Ohai::Exceptions::AttributeSyntaxError, "Attribute contains a trailing '/': #{attribute}" if attribute =~ /\/$/

      parts = attribute.split("/")
      parts.shift if parts.length != 0 && parts[0].length == 0 # attribute begins with a '/'
      parts
    end

    def select_subtree(provides_map, attribute)
      subtree = provides_map
      parts = normalize_and_validate(attribute)
      parts.each do |part|
        return nil unless subtree[part]
        subtree = subtree[part]
      end
      subtree
    end

    def select_closest_subtree(provides_map, attribute)
      attr, *rest = normalize_and_validate(attribute)

      # return nil if the top-level part of the attribute is not a
      # top-level key in the provides_map (can't search any lower, and
      # no information to return from this level of the search)
      return nil unless provides_map[attr]

      # attr is a key in the provides_map, search for the sub
      # attribute under attr (if attribute = attr/sub1/sub2 then we
      # search provides_map[attr] for sub1/sub2)
      unless rest.empty?
        subtree = select_closest_subtree(provides_map[attr], rest.join("/"))
      end

      if subtree.nil?
        # no subtree of provides_map[attr] either 1) has a
        # subattribute, 2) has a plugin providing a subattribute.
        unless provides_map[attr][:_plugins]
          # no providers for this attribute, this subtree won't do.
          return nil # no providers for this attribute
        else
          # there are providers for this attribute, return its subtree
          # to indicate this is the closest subtree
          return provides_map[attr]
        end
      end

      # we've already found a closest subtree or we've search all
      # parent attributes of the original attribute and found no
      # providers (subtree is nil in this case)
      subtree
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
