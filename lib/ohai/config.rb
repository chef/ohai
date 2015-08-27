#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Claire McQuin (<claire@chef.io>)
# Copyright:: Copyright (c) 2008-2015 Chef Software, Inc.
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

require 'chef-config/config'
require 'ohai/exception'
require 'ohai/log'
require 'ohai/plugin_config'

module Ohai
  Config = ChefConfig::Config

  # Reopens ChefConfig::Config to add Ohai configuration settings.
  # see: https://github.com/chef/chef/blob/master/lib/chef/config.rb
  class Config
    # These methods need to be defined before they are used as config defaults,
    # otherwise they will get method_missing'd to nil.
    private
    def self.default_hints_path
      [ ChefConfig::Config.platform_specific_path('/etc/chef/ohai/hints') ]
    end

    def self.default_plugin_path
      [ File.expand_path(File.join(File.dirname(__FILE__), 'plugins')) ]
    end

    public
    # Copy deprecated configuration options into the ohai config context.
    def self.merge_deprecated_config
      [ :hints_path, :plugin_path ].each do |option|
        if has_key?(option) && send(option) != send("default_#{option}".to_sym)
          Ohai::Log.warn(option_deprecated(option))
        end
      end

      ohai.merge!(configuration)
    end

    # Keep "old" config defaults around so anyone calling Ohai::Config[:key]
    # won't be broken. Also allows users to append to configuration options
    # (e.g., Ohai::Config[:plugin_path] << some_path) in their config files.
    default :disabled_plugins, []
    default :hints_path, default_hints_path
    default :log_level, :auto
    default :log_location, STDERR
    default :plugin_path, default_plugin_path

    # Log deprecation warning when a top-level configuration option is set.
    # TODO: Should we implement a config_attr_reader so that deprecation
    # warnings will be generatd on read?
    [
      :directory,
      :disabled_plugins,
      :log_level,
      :log_location,
      :version
    ].each do |option|
      # https://docs.chef.io/config_rb_client.html#ohai-settings
      # hints_path and plugin_path are intentionally excluded here; warnings for
      # setting these attributes are generated in merge_deprecated_config since
      # append (<<) operations bypass the config writer.
      config_attr_writer option do |value|
        # log_level and log_location are common configuration options for chef
        # and other chef applications. When configuration files are read there
        # is no distinction between log_level and Ohai::Config[:log_level] and
        # we may emit a false deprecation warning. The deprecation warnings for
        # these settings reflect that possibility.
        # Furthermore, when the top-level config settings are removed we will
        # need to ensure that Ohai.config[:log_level] can be set by writing
        # log_level in a configuration file for consistent behavior with chef.
        deprecation_warning = [ :log_level, :log_location ].include?(value) ?
          option_might_be_deprecated(option) : option_deprecated(option)
        Ohai::Log.warn(deprecation_warning)
        value
      end
    end

    config_context :ohai do
      default :disabled_plugins, []
      default :hints_path, Ohai::Config.default_hints_path
      default :log_level, :auto
      default :log_location, STDERR
      default :plugin, Ohai::PluginConfig.new { |h, k| h[k] = Ohai::PluginConfig.new }
      default :plugin_path, Ohai::Config.default_plugin_path
    end

    private
    def self.option_deprecated(option)
      <<-EOM.chomp!.gsub("\n", " ")
Ohai::Config[:#{option}] is set. Ohai::Config[:#{option}] is deprecated and will
be removed in future releases of ohai. Use ohai.#{option} in your configuration
file to configure :#{option} for ohai.
EOM
    end

    def self.option_might_be_deprecated(option)
      option_deprecated(option) + <<-EOM.chomp!.gsub("\n", " ")
 If your configuration file is used with other applications which configure
:#{option}, and you have not configured Ohai::Config[:#{option}], you may
disregard this warning.
EOM
    end
  end

  # Shortcut for Ohai::Config.ohai
  def self.config
    Config::ohai
  end
end
