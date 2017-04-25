#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tim Smith (<tsmith@chef.io>)
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

require "ohai/exception"
require "ohai/log"
require "mixlib/shellout"

module Ohai
  module Mixin
    module Command
      # DISCLAIMER: Logging only works in the context of a plugin!!
      # accept a command and any of the mixlib-shellout options
      def shell_out(cmd, **options)
        options = options.dup
        # unless specified by the caller timeout after 30 seconds
        options[:timeout] ||= 30
        unless RUBY_PLATFORM =~ /mswin|mingw32|windows/
          options[:env] = options.key?(:env) ? options[:env].dup : {}
          options[:env]["PATH"] ||= ((ENV["PATH"] || "").split(":") + %w{/usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin}).join(":")
        end
        so = Mixlib::ShellOut.new(cmd, options)
        begin
          so.run_command
          Ohai::Log.debug("Plugin #{self.name}: ran '#{cmd}' and returned #{so.exitstatus}")
          so
        rescue Errno::ENOENT => e
          Ohai::Log.debug("Plugin #{self.name}: ran '#{cmd}' and failed #{e.inspect}")
          raise Ohai::Exceptions::Exec, e
        rescue Mixlib::ShellOut::CommandTimeout => e
          Ohai::Log.debug("Plugin #{self.name}: ran '#{cmd}' and timed out after #{options[:timeout]} seconds")
          raise Ohai::Exceptions::Exec, e
        end
      end

      module_function :shell_out
    end
  end
end
