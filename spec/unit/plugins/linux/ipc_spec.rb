# frozen_string_literal: true
#
# Author:: Davide Cavalca <dcavalca@fb.com>
# Copyright:: Copyright (c) 2020 Facebook
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

require "spec_helper"

describe Ohai::System, "Linux ipc plugin" do
  let(:plugin) { get_plugin("linux/ipc") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  it "populates ipc if ipcs is available" do
    ipcs_out = <<~IPCS_OUT

      ------ Shared Memory Segments --------
      key        shmid      owner      perms      bytes      nattch     status
      0x00000000 131072     dcavalca   600        524288     2          dest
      0x00000000 38993921   dcavalca   600        393216     2          dest
      0x00000000 39092226   dcavalca   600        524288     2          dest
      0x00000000 9437188    dcavalca   600        524288     2          dest

    IPCS_OUT

    allow(plugin).to receive(:which).with("ipcs").and_return("/bin/ipcs")
    allow(plugin).to receive(:shell_out).with("/bin/ipcs -m").and_return(mock_shell_out(0, ipcs_out, ""))
    plugin.run
    expect(plugin[:ipc].to_hash).to eq({
      "shm" => {
        131072 => {
          "bytes" => 524288,
          "key" => "0x00000000",
          "nattch" => 2,
          "owner" => "dcavalca",
          "perms" => "600",
          "status" => "dest",
        },
        38993921 => {
          "bytes" => 393216,
          "key" => "0x00000000",
          "nattch" => 2,
          "owner" => "dcavalca",
          "perms" => "600",
          "status" => "dest",
        },
        39092226 => {
          "bytes" => 524288,
          "key" => "0x00000000",
          "nattch" => 2,
          "owner" => "dcavalca",
          "perms" => "600",
          "status" => "dest",
        },
        9437188 => {
          "bytes" => 524288,
          "key" => "0x00000000",
          "nattch" => 2,
          "owner" => "dcavalca",
          "perms" => "600",
          "status" => "dest",
        },
      },
    })
  end

  it "does not populate ipc if ipcs is not available" do
    allow(plugin).to receive(:which).with("ipcs").and_return(false)
    expect(plugin[:ipc]).to eq(nil)
  end
end
