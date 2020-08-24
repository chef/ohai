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

require_relative "../exception"
require_relative "../log"

module Ohai
  module Mixin
    module Command
      # DISCLAIMER: Logging only works in the context of a plugin!!
      # accept a command and any of the mixlib-shellout options
      def shell_out(cmd, **options)
        execution = connection.run_command(cmd)
        logger.trace("Plugin #{name}: ran '#{cmd}' and returned #{execution.exit_status}")

        Struct.new("OutResult", :stdout, :stderr, :exit_status, :exitstatus, keyword_init: true)

        Struct::OutResult.new(
          stdout: execution.stdout,
          stderr: execution.stderr,
          exit_status: execution.exit_status,

          # Compatibility for old shell_out usage
          exitstatus: execution.exit_status,
        )

      rescue Errno::ENOENT => e
        logger.trace("Plugin #{name}: ran '#{cmd}' and failed #{e.inspect}")
        raise Ohai::Exceptions::Exec, e
      end

      module_function :shell_out
    end
  end
end
