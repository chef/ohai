# frozen_string_literal: true
#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tim Smith (<tsmith@chef.io>)
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

require_relative "../exception"
require_relative "../log"

require "mixlib/shellout/helper" unless defined?(Mixlib::ShellOut::Helper)
require_relative "chef_utils_wiring" unless defined?(Ohai::Mixin::ChefUtilsWiring)

module Ohai
  module Mixin
    module ShellOut
      include Mixlib::ShellOut::Helper
      include Ohai::Mixin::ChefUtilsWiring

      def shell_out(cmd, **options)
        options = options.dup
        # unless specified by the caller timeout after configured timeout (default 30 seconds)
        options[:timeout] ||= Ohai::Config.ohai[:shellout_timeout]
        begin
          so = super(cmd, **options)
          logger.trace("Plugin #{name}: ran '#{cmd}' and returned #{so.exitstatus}")
          so
        rescue Errno::ENOENT => e
          logger.trace("Plugin #{name}: ran '#{cmd}' and failed #{e.inspect}")
          raise Ohai::Exceptions::Exec, e
        rescue Mixlib::ShellOut::CommandTimeout => e
          logger.trace("Plugin #{name}: ran '#{cmd}' and timed out after #{options[:timeout]} seconds")
          raise Ohai::Exceptions::Exec, e
        end
      end
    end
  end
end
