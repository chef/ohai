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

      # Using train determine the OS we're running on
      #
      # @return [String] the OS
      def collect_os
        # Compatibility between Train and Ohai
        return "solaris2" if os_family == "solaris"

        ohai_family = os_hierarchy & %w{aix darwin linux freebsd openbsd netbsd windows}
        return ohai_family.first unless ohai_family.empty?

        os_family
      end

      # Using train determine the os family we're running on
      #
      # @return [String] the OS family
      def os_family
        connection.os.family
      end

      # Using train determine the platform we're running on and its ancestors
      #
      # @return [Array] the OS family hierarchy
      def os_hierarchy
        connection.os.family_hierarchy
      end

      module_function :collect_os
      module_function :os_family
      module_function :os_hierarchy
    end
  end
end
