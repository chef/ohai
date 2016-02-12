#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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

  collect_data(:dragonflybsd) do
    memory Mash.new
    memory[:swap] = Mash.new

    # /usr/src/sys/sys/vmmeter.h
    so = shell_out("sysctl -n vm.stats.vm.v_page_size")
    memory[:page_size] = so.stdout.split($/)[0]
    so = shell_out("sysctl -n vm.stats.vm.v_page_count")
    memory[:page_count] = so.stdout.split($/)[0]
    memory[:total] = memory[:page_size].to_i * memory[:page_count].to_i
    so = shell_out("sysctl -n vm.stats.vm.v_free_count")
    memory[:free] = memory[:page_size].to_i * so.stdout.split($/)[0].to_i
    so = shell_out("sysctl -n vm.status.vm.v_active_count")
    memory[:active] = memory[:page_size].to_i * so.stdout.split($/)[0].to_i
    so = shell_out("sysctl -n vm.status.vm.v_inactive_count")
    memory[:inactive] = memory[:page_size].to_i * so.stdout.split($/)[0].to_i
    so = shell_out("sysctl -n vm.stats.vm.v_cache_count")
    memory[:cache] = memory[:page_size].to_i * so.stdout.split($/)[0].to_i
    so = shell_out("sysctl -n vm.stats.vm.v_wire_count")
    memory[:wired] = memory[:page_size].to_i * so.stdout.split($/)[0].to_i
    so = shell_out("sysctl -n vfs.bufspace")
    memory[:buffers] = so.stdout.split($/)[0]

    so = shell_out("swapinfo")
    so.stdout.lines do |line|
      # Device          1K-blocks     Used    Avail Capacity
      # /dev/ad0s1b        253648        0   253648     0%
      if line =~ /^([\d\w\/]+)\s+(\d+)\s+(\d+)\s+(\d+)\s+([\d\%]+)/
        mdev = $1
        memory[:swap][mdev] = Mash.new
        memory[:swap][mdev][:total] = $2
        memory[:swap][mdev][:used] = $3
        memory[:swap][mdev][:free] = $4
        memory[:swap][mdev][:percent_free] = $5
      end
    end
  end
end
