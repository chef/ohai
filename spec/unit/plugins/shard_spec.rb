#
# Author:: Davide Cavalca <dcavalca@fb.com>
# Copyright:: Copyright (c) 2016 Facebook
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

require "digest/md5"
require "spec_helper"

describe Ohai::System, "shard plugin" do
  subject do
    plugin.run
    plugin[:shard_seed]
  end

  let(:plugin) { get_plugin("shard") }
  let(:fqdn) { "somehost004.someregion.somecompany.com" }
  let(:uuid) { "48555CF4-5BB1-21D9-BC4C-E8B73DDE5801" }
  let(:serial) { "234du3m4i498xdjr2" }
  let(:machine_id) { "0a1f869f457a4c8080ab19faf80af9cc" }
  let(:machinename) { "somehost004" }
  let(:fips) { false }
  let(:os) { "linux" }

  before do
    plugin["machinename"] = machinename
    plugin["machine_id"] = machine_id
    plugin["fqdn"] = fqdn
    plugin["dmi"] = { "system" => {} }
    plugin["dmi"]["system"]["uuid"] = uuid
    plugin["dmi"]["system"]["serial_number"] = serial
    plugin["fips"] = { "kernel" => { "enabled" => fips } }
    allow(plugin).to receive(:collect_os).and_return(os)
  end

  it "provides a shard with a default-safe set of sources" do
    expect(subject).to eq(27767217)
  end

  it "provides a shard with a configured source" do
    Ohai.config[:plugin][:shard_seed][:sources] = [:fqdn]
    expect(subject).to eq(203669792)
  end

  it "fails on an unrecognized source" do
    Ohai.config[:plugin][:shard_seed][:sources] = [:GreatGooglyMoogly]
    expect { subject }.to raise_error(RuntimeError)
  end

  it "provides a shard with a configured algorithm" do
    Ohai.config[:plugin][:shard_seed][:digest_algorithm] = "sha256"
    expect(Digest::MD5).not_to receive(:new)
    expect(subject).to eq(117055036)
  end

  context "with Darwin OS" do
    let(:os) { "darwin" }

    before do
      plugin.data.delete("fips") # FIPS is undefined on Macs, make sure this still work
      plugin["hardware"] = { "serial_number" => serial, "platform_UUID" => uuid }
    end

    it "provides a shard with a default-safe set of sources" do
      expect(subject).to eq(27767217)
    end
  end

  context "with Windows OS" do
    let(:os) { "windows" }

    before do
      wmi = double("WmiLite::Wmi")
      allow(WmiLite::Wmi).to receive(:new).and_return(wmi)
      allow(wmi).to receive(:first_of).with("Win32_BIOS").and_return("SerialNumber" => serial)
      allow(wmi).to receive(:first_of).with("Win32_ComputerSystemProduct").and_return("UUID" => uuid)
      plugin["kernel"] = { "os_info" => { "serial_number" => serial + "0" } }
      plugin.data.delete("dmi") # To make sure we aren't using the wrong data.
    end

    it "provides a shard with a default-safe set of sources" do
      expect(subject).to eq(27767217)
    end

    it "allows os_serial source" do
      Ohai.config[:plugin][:shard_seed][:sources] = %i{machinename os_serial uuid}
      # Different from above.
      expect(subject).to eq(178738102)
    end
  end

  context "with a weird OS" do
    let(:os) { "aix" }

    it "provides a shard with a default-safe set of sources" do
      # Note: this is different than the other defaults.
      expect(subject).to eq(253499154)
    end
  end

  context "with FIPS mode enabled" do
    let(:fips) { true }

    it "uses SHA2" do
      expect(Digest::MD5).not_to receive(:hexdigest)
      expect(subject).to eq(117055036)
    end
  end
end
