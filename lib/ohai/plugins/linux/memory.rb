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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Ohai.plugin(:Memory) do
  provides "memory", "memory/swap"

  collect_data(:linux) do
    memory Mash.new
    memory[:swap] = Mash.new
    memory[:hugepages] = Mash.new
    memory[:directmap] = Mash.new

    file_open("/proc/meminfo").each do |line|
      case line
      when /^MemTotal:\s+(\d+) (.+)/
        memory[:total] = "#{$1}#{$2}"
      when /^MemFree:\s+(\d+) (.+)/
        memory[:free] = "#{$1}#{$2}"
      when /^MemAvailable:\s+(\d+) (.+)/
        memory[:available] = "#{$1}#{$2}"
      when /^Buffers:\s+(\d+) (.+)/
        memory[:buffers] = "#{$1}#{$2}"
      when /^Cached:\s+(\d+) (.+)/
        memory[:cached] = "#{$1}#{$2}"
      when /^Active:\s+(\d+) (.+)/
        memory[:active] = "#{$1}#{$2}"
      when /^Inactive:\s+(\d+) (.+)/
        memory[:inactive] = "#{$1}#{$2}"
      when /^HighTotal:\s+(\d+) (.+)/
        memory[:high_total] = "#{$1}#{$2}"
      when /^HighFree:\s+(\d+) (.+)/
        memory[:high_free] = "#{$1}#{$2}"
      when /^LowTotal:\s+(\d+) (.+)/
        memory[:low_total] = "#{$1}#{$2}"
      when /^LowFree:\s+(\d+) (.+)/
        memory[:low_free] = "#{$1}#{$2}"
      when /^Dirty:\s+(\d+) (.+)/
        memory[:dirty] = "#{$1}#{$2}"
      when /^Writeback:\s+(\d+) (.+)/
        memory[:writeback] = "#{$1}#{$2}"
      when /^AnonPages:\s+(\d+) (.+)/
        memory[:anon_pages] = "#{$1}#{$2}"
      when /^Mapped:\s+(\d+) (.+)/
        memory[:mapped] = "#{$1}#{$2}"
      when /^Slab:\s+(\d+) (.+)/
        memory[:slab] = "#{$1}#{$2}"
      when /^SReclaimable:\s+(\d+) (.+)/
        memory[:slab_reclaimable] = "#{$1}#{$2}"
      when /^SUnreclaim:\s+(\d+) (.+)/
        memory[:slab_unreclaim] = "#{$1}#{$2}"
      when /^PageTables:\s+(\d+) (.+)/
        memory[:page_tables] = "#{$1}#{$2}"
      when /^NFS_Unstable:\s+(\d+) (.+)/
        memory[:nfs_unstable] = "#{$1}#{$2}"
      when /^Bounce:\s+(\d+) (.+)/
        memory[:bounce] = "#{$1}#{$2}"
      when /^CommitLimit:\s+(\d+) (.+)/
        memory[:commit_limit] = "#{$1}#{$2}"
      when /^Committed_AS:\s+(\d+) (.+)/
        memory[:committed_as] = "#{$1}#{$2}"
      when /^VmallocTotal:\s+(\d+) (.+)/
        memory[:vmalloc_total] = "#{$1}#{$2}"
      when /^VmallocUsed:\s+(\d+) (.+)/
        memory[:vmalloc_used] = "#{$1}#{$2}"
      when /^VmallocChunk:\s+(\d+) (.+)/
        memory[:vmalloc_chunk] = "#{$1}#{$2}"
      when /^SwapCached:\s+(\d+) (.+)/
        memory[:swap][:cached] = "#{$1}#{$2}"
      when /^SwapTotal:\s+(\d+) (.+)/
        memory[:swap][:total] = "#{$1}#{$2}"
      when /^SwapFree:\s+(\d+) (.+)/
        memory[:swap][:free] = "#{$1}#{$2}"
      when /^HugePages_Total:\s+(\d+)/
        memory[:hugepages][:total] = $1.to_s
      when /^HugePages_Free:\s+(\d+)/
        memory[:hugepages][:free] = $1.to_s
      when /^HugePages_Rsvd:\s+(\d+)/
        memory[:hugepages][:reserved] = $1.to_s
      when /^HugePages_Surp:\s+(\d+)/
        memory[:hugepages][:surplus] = $1.to_s
      when /^Hugepagesize:\s+(\d+) (.+)/
        memory[:hugepage_size] = "#{$1}#{$2}"
      when /^Hugetlb:\s+(\d+) (.+)/
        memory[:hugetlb] = "#{$1}#{$2}"
      when /^DirectMap([0-9]+[a-zA-Z]):\s+(\d+) (.+)/
        memory[:directmap][$1.to_sym] = "#{$2}#{$3}"
      end
    end
  end
end
