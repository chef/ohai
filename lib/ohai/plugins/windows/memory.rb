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
#
Ohai.plugin(:Memory) do
  provides "memory"

  collect_data(:windows) do
    require "wmi-lite/wmi"

    memory Mash.new
    memory[:swap] = Mash.new

    wmi = WmiLite::Wmi.new

    os = wmi.first_of("Win32_OperatingSystem")

    # MemTotal
    memory[:total] = os["TotalVisibleMemorySize"] + "kB"
    # MemFree
    memory[:free] = os["FreePhysicalMemory"] + "kB"
    # SwapTotal
    memory[:swap][:total] = os["SizeStoredInPagingFiles"] + "kB"
    # SwapFree
    memory[:swap][:free] = os["FreeSpaceInPagingFiles"] + "kB"
  end
end
