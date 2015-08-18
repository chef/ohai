#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
  provides "memory", "memory/swap"

  collect_data(:linux) do
    memory Mash.new
    memory[:swap] = Mash.new

    File.open("/proc/meminfo").each do |line|
      case line
      when /^MemTotal:\s+(\d+) (.+)$/
        memory[:total] = $1.to_i / 1024.0
      when /^MemFree:\s+(\d+) (.+)$/
        memory[:free] = $1.to_i / 1024.0
      when /^Buffers:\s+(\d+) (.+)$/
        memory[:buffers] = $1.to_i / 1024.0
      when /^Cached:\s+(\d+) (.+)$/
        memory[:cached] = $1.to_i / 1024.0
      when /^Active:\s+(\d+) (.+)$/
        memory[:active] = $1.to_i / 1024.0
      when /^Inactive:\s+(\d+) (.+)$/
        memory[:inactive] = $1.to_i / 1024.0
      when /^HighTotal:\s+(\d+) (.+)$/
        memory[:high_total] = $1.to_i / 1024.0
      when /^HighFree:\s+(\d+) (.+)$/
        memory[:high_free] = $1.to_i / 1024.0
      when /^LowTotal:\s+(\d+) (.+)$/
        memory[:low_total] = $1.to_i / 1024.0
      when /^LowFree:\s+(\d+) (.+)$/
        memory[:low_free] = $1.to_i / 1024.0
      when /^Dirty:\s+(\d+) (.+)$/
        memory[:dirty] = $1.to_i / 1024.0
      when /^Writeback:\s+(\d+) (.+)$/
        memory[:writeback] = $1.to_i / 1024.0
      when /^AnonPages:\s+(\d+) (.+)$/
        memory[:anon_pages] = $1.to_i / 1024.0
      when /^Mapped:\s+(\d+) (.+)$/
        memory[:mapped] = $1.to_i / 1024.0
      when /^Slab:\s+(\d+) (.+)$/
        memory[:slab] = $1.to_i / 1024.0
      when /^SReclaimable:\s+(\d+) (.+)$/
        memory[:slab_reclaimable] = $1.to_i / 1024.0
      when /^SUnreclaim:\s+(\d+) (.+)$/
        memory[:slab_unreclaim] = $1.to_i / 1024.0
      when /^PageTables:\s+(\d+) (.+)$/
        memory[:page_tables] = $1.to_i / 1024.0
      when /^NFS_Unstable:\s+(\d+) (.+)$/
        memory[:nfs_unstable] = $1.to_i / 1024.0
      when /^Bounce:\s+(\d+) (.+)$/
        memory[:bounce] = $1.to_i / 1024.0
      when /^CommitLimit:\s+(\d+) (.+)$/
        memory[:commit_limit] = $1.to_i / 1024.0
      when /^Committed_AS:\s+(\d+) (.+)$/
        memory[:committed_as] = $1.to_i / 1024.0
      when /^VmallocTotal:\s+(\d+) (.+)$/
        memory[:vmalloc_total] = $1.to_i / 1024.0
      when /^VmallocUsed:\s+(\d+) (.+)$/
        memory[:vmalloc_used] = $1.to_i / 1024.0
      when /^VmallocChunk:\s+(\d+) (.+)$/
        memory[:vmalloc_chunk] = $1.to_i / 1024.0
      when /^SwapCached:\s+(\d+) (.+)$/
        memory[:swap][:cached] = $1.to_i / 1024.0
      when /^SwapTotal:\s+(\d+) (.+)$/
        memory[:swap][:total] = $1.to_i / 1024.0
      when /^SwapFree:\s+(\d+) (.+)$/
        memory[:swap][:free] = $1.to_i / 1024.0
      end
    end
  end
end
