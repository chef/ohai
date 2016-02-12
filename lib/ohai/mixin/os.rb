#
# Author:: Adam Jacob (<adam@chef.io>)
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "rbconfig"

module Ohai
  module Mixin
    module OS

      def collect_os
        case ::RbConfig::CONFIG["host_os"]
        when /aix(.+)$/
          return "aix"
        when /darwin(.+)$/
          return "darwin"
        when /hpux(.+)$/
          return "hpux"
        when /linux/
          return "linux"
        when /freebsd(.+)$/
          return "freebsd"
        when /openbsd(.+)$/
          return "openbsd"
        when /netbsd(.*)$/
          return "netbsd"
        when /dragonfly(.*)$/
          return "dragonflybsd"
        when /solaris2/
          return "solaris2"
        when /mswin|mingw32|windows/
          # After long discussion in IRC the "powers that be" have come to a consensus
          # that no Windows platform exists that was not based on the
          # Windows_NT kernel, so we herby decree that "windows" will refer to all
          # platforms built upon the Windows_NT kernel and have access to win32 or win64
          # subsystems.
          return "windows"
        else
          return ::RbConfig::CONFIG["host_os"]
        end
      end

      module_function :collect_os
    end
  end
end
