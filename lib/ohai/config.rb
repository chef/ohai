# frozen_string_literal: true
#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Claire McQuin (<claire@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
require_relative "exception"
require_relative "plugin_config"

module Ohai
  Config = ChefConfig::Config

  # Reopens ChefConfig::Config to add Ohai configuration settings.
  # see: https://github.com/chef/chef/blob/master/lib/chef/config.rb
  class Config
    config_context :ohai do
      default :disabled_plugins, []
      default :hints_path, [ ChefConfig::Config.platform_specific_path("/etc/chef/ohai/hints") ]
      default :log_level, :auto
      default :log_location, STDERR
      default :plugin, ( Ohai::PluginConfig.new { |h, k| h[k] = Ohai::PluginConfig.new } )
      default :plugin_path, [ File.expand_path(File.join(__dir__, "plugins")), ChefConfig::Config.platform_specific_path("/etc/chef/ohai/plugins") ]
      default :critical_plugins, []
      # causes all optional plugins to be run.
      default :run_all_plugins, false
      # optional plugins are the set of plugins that are marked optional but you wish to run.
      default(:optional_plugins, []).writes_value { |arr| arr.map(&:to_sym) }
      default :shellout_timeout, 30
    end
  end

  # Shortcut for Ohai::Config.ohai
  def self.config
    Config.ohai
  end
end
