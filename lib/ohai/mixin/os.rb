# frozen_string_literal: true
#
# Author:: Adam Jacob (<adam@chef.io>)
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "rbconfig" unless defined?(RbConfig)

module Ohai
  module Mixin
    module OS

      # Using ruby configuration determine the OS we're running on
      #
      # @return [String] the OS
      def collect_os
        if target_mode?
          collect_os_target
        else
          collect_os_local
        end
      end

      # This should exactly preserve the semantics of collect_os_local below, which is authoritative
      # for the API and must adhere to pre-existing ohai semantics and not follow inspec's notion of
      # os/family/hierarchy.
      #
      # Right or wrong the ohai `os` variable has matched the ruby `host_os` definition for the past
      # 10+ years, preceding inspec/train's definitions and this is the documented correct API of
      # these methods.  Mismatches between the ruby notion and the train version will be fixed as
      # bugfixes in these methods and may not be considered semver violating even though they make
      # break downstream consumers.  Please ensure that both methods produce the same results if
      # you are on a platform which supports running ruby (train is considered authoritative for
      # any "OS" which cannot run ruby -- server consoles, REST APIs, etc...)
      #
      # @api private
      def collect_os_target
        case
        when transport_connection.os.aix?
          "aix"
        when transport_connection.os.darwin?
          "darwin"
        when transport_connection.os.linux?
          "linux"
        when transport_connection.os.family == "freebsd"
          "freebsd"
        when transport_connection.os.family == "openbsd"
          "openbsd"
        when transport_connection.os.family == "netbsd"
          "netbsd"
        when transport_connection.os.family == "dragonflybsd"
          "dragonflybsd"
        when transport_connection.os.solaris?
          "solaris2"
        when transport_connection.os.windows?
          "windows"

          #
          # The purpose of the next two lines is that anything which runs Unix is presumed to be able to run ruby, and
          # if it was not caught above, we MUST translate whatever train uses as the 'os' into the proper ruby host_os
          # string.  If it is not unix and not caught above we assume it is something like a REST API which cannot run
          # ruby.  If these assumptions are incorrect then it is a bug, which should be submitted to fix it, and the
          # values should not be relied upon until that bug is fixed.  The train os is NEVER considered authoritative
          # for any target which can run ruby.
          #
        when transport_connection.os.unix?
          raise "Target mode unsupported on this Unix-like host, please update the collect_os_target case statement with the correct ruby host_os value."
        else
          # now we have something like an IPMI console that isn't Unix-like or Windows, presumably cannot run ruby, and
          # so we just trust the train O/S information.
          transport_connection.os.name
        end
      end

      # @api private
      def nonruby_target?
        transport_connection && !transport_connection.os.unix? && !transport_connection.os.windows?
      end

      # @api private
      def collect_os_local
        case ::RbConfig::CONFIG["host_os"]
        when /aix(.+)$/
          "aix"
        when /darwin(.+)$/
          "darwin"
        when /linux/
          "linux"
        when /freebsd(.+)$/
          "freebsd"
        when /openbsd(.+)$/
          "openbsd"
        when /netbsd(.*)$/
          "netbsd"
        when /dragonfly(.*)$/
          "dragonflybsd"
        when /solaris2/
          "solaris2"
        when /mswin|mingw|windows/
          # After long discussion in IRC the "powers that be" have come to a consensus
          # that no Windows platform exists that was not based on the
          # Windows_NT kernel, so we herby decree that "windows" will refer to all
          # platforms built upon the Windows_NT kernel and have access to win32 or win64
          # subsystems.
          "windows"
        else
          ::RbConfig::CONFIG["host_os"]
        end
      end

      extend self
    end
  end
end
