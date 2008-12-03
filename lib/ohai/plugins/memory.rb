#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

require_plugin "os"

case os
when "linux"
  File.open("/proc/meminfo").each do |line|
    case line
    when /^MemTotal:\s+(\d+) (.+)$/
      memory_total "#{$1}#{$2}"
    when /^MemFree:\s+(\d+) (.+)$/
      memory_free  "#{$1}#{$2}"
    when /^Buffers:\s+(\d+) (.+)$/
      memory_buffers "#{$1}#{$2}"
    when /^Cached:\s+(\d+) (.+)$/
      memory_cached "#{$1}#{$2}"
    when /^Active:\s+(\d+) (.+)$/
      memory_active "#{$1}#{$2}"
    when /^Inactive:\s+(\d+) (.+)$/
      memory_inactive "#{$1}#{$2}"
    when /^HighTotal:\s+(\d+) (.+)$/
      memory_high_total "#{$1}#{$2}"  
    when /^HighFree:\s+(\d+) (.+)$/
      memory_high_free "#{$1}#{$2}"
    when /^LowTotal:\s+(\d+) (.+)$/
      memory_low_total "#{$1}#{$2}"
    when /^LowFree:\s+(\d+) (.+)$/
      memory_low_free "#{$1}#{$2}"
    when /^Dirty:\s+(\d+) (.+)$/
      memory_dirty "#{$1}#{$2}"
    when /^Writeback:\s+(\d+) (.+)$/
      memory_writeback "#{$1}#{$2}"
    when /^AnonPages:\s+(\d+) (.+)$/
      memory_anon_pages "#{$1}#{$2}"    
    when /^Mapped:\s+(\d+) (.+)$/
      memory_mapped "#{$1}#{$2}"
    when /^Slab:\s+(\d+) (.+)$/
      memory_slab "#{$1}#{$2}"
    when /^SReclaimable:\s+(\d+) (.+)$/
      memory_slab_reclaimable "#{$1}#{$2}"
    when /^SUnreclaim:\s+(\d+) (.+)$/
      memory_slab_unreclaim "#{$1}#{$2}"
    when /^PageTables:\s+(\d+) (.+)$/
      memory_page_tables "#{$1}#{$2}"
    when /^NFS_Unstable:\s+(\d+) (.+)$/
      memory_nfs_unstable "#{$1}#{$2}"
    when /^Bounce:\s+(\d+) (.+)$/
      memory_bounce "#{$1}#{$2}"
    when /^CommitLimit:\s+(\d+) (.+)$/
      memory_commit_limit "#{$1}#{$2}"
    when /^Committed_AS:\s+(\d+) (.+)$/
      memory_committed_as "#{$1}#{$2}"
    when /^VmallocTotal:\s+(\d+) (.+)$/
      memory_vmalloc_total "#{$1}#{$2}"
    when /^VmallocUsed:\s+(\d+) (.+)$/
      memory_vmalloc_used "#{$1}#{$2}"
    when /^VmallocChunk:\s+(\d+) (.+)$/
      memory_vmalloc_chunk "#{$1}#{$2}"
    when /^SwapCached:\s+(\d+) (.+)$/
      swap_cached "#{$1}#{$2}"
    when /^SwapTotal:\s+(\d+) (.+)$/
      swap_total "#{$1}#{$2}"
    when /^SwapFree:\s+(\d+) (.+)$/
      swap_free "#{$1}#{$2}"
    end
  end
end