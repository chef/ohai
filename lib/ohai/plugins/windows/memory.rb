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
    memory Mash.new
    memory[:swap] = Mash.new

    os_results = shell_out('Get-WmiObject "Win32_OperatingSystem" | ForEach-Object { Write-Host "$($_.TotalVisibleMemorySize)kB,$($_.FreePhysicalMemory)kB,$($_.SizeStoredInPagingFiles)kB,$($_.FreeSpaceInPagingFiles)kB" }').stdout.strip
    total_memory, free_memory, swap_total, swap_free = os_results.split(',',4)
    
    memory[:total] = total_memory
    memory[:free] = free_memory
    memory[:swap][:total] = swap_total
    memory[:swap][:free] = swap_free
  end
end
