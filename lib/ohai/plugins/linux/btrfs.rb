# frozen_string_literal: true
#
# Author:: Boris Burkov <boris@bur.io>
# Copyright:: Copyright (c) 2021 Facebook, Inc.
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

Ohai.plugin(:Btrfs) do
  provides "btrfs"
  depends "filesystem"

  collect_data(:linux) do
    btrfs Mash.new
    btrfs["by_mountpoint"] ||= Mash.new
    btrfs["by_uuid"] ||= Mash.new
    filesystem["by_mountpoint"].each do |mount, fs|
      next unless fs["fs_type"] == "btrfs"

      uuid = fs["uuid"]
      logger.trace("Plugin Btrfs: found btrfs #{uuid} at #{mount}")
      # don't read again if we already read this uuid
      btrfs_data = btrfs["by_uuid"][uuid]
      unless btrfs_data
        btrfs_data = Mash.new
        btrfs_data["uuid"] = uuid
        alloc = "/sys/fs/btrfs/#{uuid}/allocation"
        %w{data metadata system}.each do |bg_type|
          dir = "#{alloc}/#{bg_type}"
          %w{single dup}.each do |raid|
            if file_exist?("#{dir}/#{raid}")
              btrfs_data["raid"] = raid
            end
          end
          logger.trace("Plugin Btrfs: reading allocation files at #{dir}")
          btrfs_data["allocation"] ||= Mash.new
          btrfs_data["allocation"][bg_type] ||= Mash.new
          %w{total_bytes bytes_used}.each do |field|
            bytes = file_read("#{dir}/#{field}").chomp.to_i
            btrfs_data["allocation"][bg_type][field] = "#{bytes}"
          end
        end
      end

      btrfs["by_mountpoint"][mount] = btrfs_data
      btrfs["by_uuid"][uuid] = btrfs_data
    end
  end
end
