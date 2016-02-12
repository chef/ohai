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

module Ohai
  module Util
    module Win32
      if RUBY_PLATFORM =~ /mswin|mingw|windows/

        require "ffi"

        extend FFI::Library

        ffi_lib "advapi32"

        attach_function :lookup_account_sid,
        :LookupAccountSidA, [ :pointer, :pointer, :pointer, :pointer, :pointer, :pointer, :pointer ], :long

        attach_function :convert_string_sid_to_sid,
        :ConvertStringSidToSidA, [ :pointer, :pointer ], :long

        ffi_lib "kernel32"

        attach_function :local_free,
        :LocalFree, [ :pointer ], :long

        attach_function :get_last_error,
        :GetLastError, [], :long
      end
    end
  end
end
