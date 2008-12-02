#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
# License:: GNU GPL, Version 3
#
# Copyright (C) 2008, OpsCode Inc. 
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'extlib'
require 'ohai/log'
require 'ohai/mixin/from_file'
require 'ohai/mixin/command'
require 'json'

module Ohai
  class System
    attr_accessor :data, :seen_plugins
    
    include Ohai::Mixin::FromFile
    include Ohai::Mixin::Command
    
    def initialize
      @data = Mash.new
      @seen_plugins = Hash.new
    end
    
    def attribute?(name)
      Ohai::Log.debug("Attribute #{name} is #{@data.has_key?(name)}")
      @data.has_key?(name) 
    end
    
    def set(name, *value)
      set_attribute(name, *value)
    end
    
    def from(cmd)
      status, stdout, stderr = run_command(:command => cmd)
      stdout.chomp!
    end
    
    # Set the value equal to the stdout of the command, plus run through a regex - the first piece of match data is the value.
    def from_with_regex(cmd, *regex_list)
      regex_list.flatten.each do |regex|
        status, stdout, stderr = run_command(:command => cmd)
        stdout.chomp!
        md = stdout.match(regex)
        return md[1]
      end
    end
    
    def set_attribute(name, *value)
      Ohai::Log.debug("Setting attribute #{name} to #{value.inspect}")
      @data[name] = *value
      @data[name]
    end
    
    def get_attribute(name)
      Ohai::Log.debug("Getting attribute #{name}, value #{@data[name].inspect}")
      @data[name]
    end
    
    def all_plugins
      Ohai::Config[:plugin_path].each do |path|
        Dir[File.join(path, '**', '*')].each do |file|
          file_regex = Regexp.new("#{path}#{File::SEPARATOR}(.+).rb$")
          md = file_regex.match(file)
          if md
            plugin_name = md[1].gsub(File::SEPARATOR, "::") 
            require_plugin(plugin_name) unless @seen_plugins.has_key?(plugin_name)
          end
        end
      end
    end
    
    def require_plugin(plugin_name)
      return true if @seen_plugins[plugin_name]
      
      filename = "#{plugin_name.gsub("::", File::SEPARATOR)}.rb"
            
      Ohai::Config[:plugin_path].each do |path|
        check_path = File.expand_path(File.join(path, filename))
        begin
          @seen_plugins[plugin_name] = true
          Ohai::Log.info("Loading plugin #{plugin_name}")
          from_file(check_path)
          return true
        rescue IOError => e
          Ohai::Log.debug("No #{plugin_name} at #{check_path}")
        rescue Exception => e
          Ohai::Log.debug("Plugin #{plugin_name} threw exception #{e.inspect}")
        end
      end
    end
    
    # Serialize this object as a hash 
    def to_json(*a)
      output = @data.clone
      output["json_class"] = self.class.name
      output.to_json(*a)
    end
    
    # Pretty Print this object as JSON 
     def json_pretty_print
       JSON.pretty_generate(@data)
     end
    
    # Create an Ohai::System from JSON
    def self.json_create(o)
      ohai = new
      o.each do |key, value|
        ohai.data[key] = value unless key == "json_class"
      end
      ohai
    end
    
    def method_missing(name, *args)
      return get_attribute(name) if args.length == 0 
      
      set_attribute(name, *args)
    end
  end
end