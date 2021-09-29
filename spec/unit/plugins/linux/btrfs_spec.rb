#
#  Author:: Boris Burkov <boris@bur.io>
#  Copyright:: Copyright (c) 2021 Facebook, Inc.
#  License:: Apache License, Version 2.0
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require "spec_helper"

describe Ohai::System, "Linux Btrfs Plugin" do
  ALLOC = {
    "data" => {
      "total_bytes" => "10000000000",
      "bytes_used" => "7000000000",
    },
    "metadata" => {
      "total_bytes" => "2000000000",
      "bytes_used" => "200000000",
    },
    "system" => {
      "total_bytes" => "100000000",
      "bytes_used" => "10000",
    },
  }.freeze

  before do
    @plugin = get_plugin("linux/btrfs")
    sysfs_base_path = "/sys/fs/btrfs/fake-uuid/allocation"
    %w{data metadata system}.each do |bg_type|
      allow(@plugin).to receive(:file_exists?).with("#{sysfs_base_path}/#{bg_type}/single").and_return(true)
      allow(@plugin).to receive(:file_exists?).with("#{sysfs_base_path}/#{bg_type}/dup").and_return(false)
      %w{total_bytes bytes_used}.each do |field|
        allow(@plugin).to receive(:file_read).with("#{sysfs_base_path}/#{bg_type}/#{field}").and_return(ALLOC[bg_type][field])
      end
    end
    @plugin[:filesystem] = {
      by_mountpoint: {
        "/": {
          "fs_type": "btrfs",
          "uuid": "fake-uuid",
        },
        "/mnt": {
          "fs_type": "ext4",
        },
        "/mnt2": {
          "fs_type": "btrfs",
          "uuid": "fake-uuid",
        },
      },
    }
  end
  it "collects btrfs usage information" do
    @plugin.run
    expect(@plugin[:btrfs]["by_mountpoint"]["/"]["allocation"]).to eq(ALLOC)
    expect(@plugin[:btrfs]["by_mountpoint"]["/mnt"]).to eq(nil)
    expect(@plugin[:btrfs]["by_mountpoint"]["/mnt2"]["allocation"]).to eq(ALLOC)
    expect(@plugin[:btrfs]["by_uuid"]["fake-uuid"]["allocation"]).to eq(ALLOC)
  end
end
