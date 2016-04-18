#
# Author:: Matt Wrock (<matt@mattwrock.com>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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

# After long discussion in IRC the "powers that be" have come to a concensus
# that there is no other Windows platforms exist that were not based on the
# Windows_NT kernel, so we herby decree that "windows" will refer to all
# platforms built upon the Windows_NT kernel and have access to win32 or win64
# subsystems.

Ohai.plugin(:Fips) do
  provides "fips"

  collect_data(:windows) do
    require "win32/registry"
    fips Mash.new

    # from http://msdn.microsoft.com/en-us/library/windows/desktop/aa384129(v=vs.85).aspx
    if ::RbConfig::CONFIG["target_cpu"] == "i386"
      reg_type = Win32::Registry::KEY_READ | 0x100
    elsif ::RbConfig::CONFIG["target_cpu"] == "x86_64"
      reg_type = Win32::Registry::KEY_READ | 0x200
    else
      reg_type = Win32::Registry::KEY_READ
    end

    begin
      Win32::Registry::HKEY_LOCAL_MACHINE.open('System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy', reg_type) do |policy|
        enabled = policy["Enabled"]
        fips["kernel"] = { "enabled" => enabled == 0 ? false : true }
      end
    rescue Win32::Registry::Error
      fips["kernel"] = { "enabled" => false }
    end
  end
end
