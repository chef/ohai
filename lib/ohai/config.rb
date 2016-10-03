#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Claire McQuin (<claire@chef.io>)
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

require "chef-config/config"
require "info_getter/exception"
require "info_getter/log"
require "info_getter/plugin_config"

module info_getter
  Config = ChefConfig::Config

  # Reopens ChefConfig::Config to add info_getter configuration settings.
  # see: https://github.com/chef/chef/blob/master/lib/chef/config.rb
  class Config
    # These methods need to be defined before they are used as config defaults,
    # otherwise they will get method_missing'd to nil.

    class << self
      def merge_deprecated_config
        [ :hints_path, :plugin_path ].each do |option|
          if has_key?(option) && send(option) != send("default_#{option}".to_sym)
            info_getter::Log.warn(option_deprecated(option))
          end
        end

        info_getter.merge!(configuration)
      end

      def default_hints_path
        [ ChefConfig::Config.platform_specific_path("/etc/chef/info_getter/hints") ]
      end

      def default_plugin_path
        [ File.expand_path(File.join(File.dirname(__FILE__), "plugins")) ]
      end
    end

    # Copy deprecated configuration options into the info_getter config context.

    # Keep "old" config defaults around so anyone calling info_getter::Config[:key]
    # won't be broken. Also allows users to append to configuration options
    # (e.g., info_getter::Config[:plugin_path] << some_path) in their config files.
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
      :version,
    ].each do |option|
      # https://docs.chef.io/config_rb_client.html#info_getter-settings
      # hints_path and plugin_path are intentionally excluded here; warnings for
      # setting these attributes are generated in merge_deprecated_config since
      # append (<<) operations bypass the config writer.
      config_attr_writer option do |value|
        # log_level and log_location are common configuration options for chef
        # and other chef applications. When configuration files are read there
        # is no distinction between log_level and info_getter::Config[:log_level] and
        # we may emit a false deprecation warning. The deprecation warnings for
        # these settings reflect that possibility.
        # Furthermore, when the top-level config settings are removed we will
        # need to ensure that info_getter.config[:log_level] can be set by writing
        # log_level in a configuration file for consistent behavior with chef.
        deprecation_warning = if [ :log_level, :log_location ].include?(value)
                                option_might_be_deprecated(option)
                              else
                                option_deprecated(option)
                              end
        info_getter::Log.warn(deprecation_warning)
        value
      end
    end

    config_context :info_getter do
      default :disabled_plugins, []
      default :hints_path, info_getter::Config.default_hints_path
      default :log_level, :auto
      default :log_location, STDERR
      default :plugin, info_getter::PluginConfig.new { |h, k| h[k] = info_getter::PluginConfig.new }
      default :plugin_path, info_getter::Config.default_plugin_path
    end

    class << self
      def option_deprecated(option)
        <<-EOM.chomp!.tr("\n", " ")
info_getter::Config[:#{option}] is set. info_getter::Config[:#{option}] is deprecated and will
be removed in future releases of info_getter. Use info_getter.#{option} in your configuration
file to configure :#{option} for info_getter.
        EOM
      end

      def option_might_be_deprecated(option)
        option_deprecated(option) + <<-EOM.chomp!.tr("\n", " ")
 If your configuration file is used with other applications which configure
:#{option}, and you have not configured info_getter::Config[:#{option}], you may
disregard this warning.
        EOM
      end
    end
  end

  # Shortcut for info_getter::Config.info_getter
  def self.config
    Config.info_getter
  end
end
