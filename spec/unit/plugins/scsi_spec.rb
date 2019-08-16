#
# Author:: Phil Dibowitz <phil@ipom.com>
# Copyright:: Copyright (c) 2018 Facebook, Inc.
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

describe Ohai::System, "lsscsi plugin" do
  let(:plugin) { get_plugin("scsi") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    @stdout = <<~LSSCSI
      [5:0:0:0]    disk    ATA      Hitachi HUA72205 A3EA  /dev/sda
      [6:2:0:0]    disk    LSI      MR9286CV-8e      3.41  /dev/sdb
      [6:2:1:0]    disk    LSI      MR9286CV-8e      3.41  /dev/sdc
      [6:2:2:0]    disk    LSI      MR9286CV-8e      3.41  /dev/sdd
      [6:2:3:0]    disk    LSI      MR9286CV-8e      3.41  /dev/sde
      [6:2:4:0]    disk    LSI      MR9286CV-8e      3.41  /dev/sdf
    LSSCSI
    allow(plugin).to receive(:shell_out).with("lsscsi").and_return(
      mock_shell_out(0, @stdout, "")
    )
    plugin.run
  end

  describe "when gathering data from lsscsi" do
    it "lists all devices" do
      expect(plugin[:scsi].keys).to eq(
        ["5:0:0:0", "6:2:0:0", "6:2:1:0", "6:2:2:0", "6:2:3:0", "6:2:4:0"]
      )
    end

    it "parses out type" do
      expect(plugin[:scsi]["6:2:0:0"]["type"]).to eq("disk")
    end

    it "parses out transport" do
      expect(plugin[:scsi]["5:0:0:0"]["transport"]).to eq("ATA")
      expect(plugin[:scsi]["6:2:0:0"]["transport"]).to eq("LSI")
    end

    it "parses out device" do
      expect(plugin[:scsi]["6:2:0:0"]["device"]).to eq("/dev/sdb")
    end

    it "parses out revision" do
      expect(plugin[:scsi]["6:2:3:0"]["revision"]).to eq("3.41")
    end

    it "parses out name" do
      expect(plugin[:scsi]["5:0:0:0"]["name"]).to eq("Hitachi HUA72205")
      expect(plugin[:scsi]["6:2:4:0"]["name"]).to eq("MR9286CV-8e")
    end
  end
end
