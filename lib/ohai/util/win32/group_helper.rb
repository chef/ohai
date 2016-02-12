# Author:: Adam Edwards (<adamed@chef.io>)
#
# Copyright:: Copyright (c) 2013-14 Chef Software, Inc.
#
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

require "ohai/util/win32"

module Ohai
  module Util
    class Win32::GroupHelper

      # Per http://support.microsoft.com/kb/243330 SID: S-1-5-32-544 is the
      # internal name for the Administrators group, which lets us work
      # properly in environments with a renamed or localized name for the
      # Administrators group
      BUILTIN_ADMINISTRATORS_SID = "S-1-5-32-544"

      def self.windows_root_group_name
        administrators_group_name_result = nil

        administrators_sid_result = FFI::MemoryPointer.new(:pointer)
        convert_result = Win32.convert_string_sid_to_sid(BUILTIN_ADMINISTRATORS_SID, administrators_sid_result)
        last_win32_error = Win32.get_last_error

        if convert_result == 0
          raise "ERROR: failed to to convert sid string '#{BUILTIN_ADMINISTRATORS_SID}' to a Windows SID structure because Win32 API function ConvertStringSidToSid returned #{last_win32_error}."
        end

        administrators_group_name_buffer = 0.chr * 260
        administrators_group_name_length = [administrators_group_name_buffer.length].pack("L")
        domain_name_length_buffer = [260].pack("L")
        sid_use_result = 0.chr * 4

        # Use LookupAccountSid rather than WMI's Win32_Group class because WMI will attempt
        # to include (unneeded) Active Directory groups by querying AD, which is a performance
        # and reliability issue since AD might not be reachable. Additionally, in domains with
        # thousands of groups, the WMI query is very slow,  on the order of minutes, even to
        # get the first result. So we use LookupAccountSid which is a purely local lookup
        # of the built-in group, with no need to access AD, and thus no failure modes related
        # to network conditions or query performance.
        lookup_boolean_result = Win32.lookup_account_sid(
                                                         nil,
                                                         administrators_sid_result.read_pointer,
                                                         administrators_group_name_buffer,
                                                         administrators_group_name_length,
                                                         nil,
                                                         domain_name_length_buffer,
                                                         sid_use_result)

        last_win32_error = Win32.get_last_error

        Win32.local_free(administrators_sid_result.read_pointer)

        if lookup_boolean_result == 0
          raise "ERROR: failed to find root group (i.e. builtin\\administrators) for sid #{BUILTIN_ADMINISTRATORS_SID} because Win32 API function LookupAccountSid returned #{last_win32_error}."
        end

        administrators_group_name_buffer.strip
      end
    end
  end
end
