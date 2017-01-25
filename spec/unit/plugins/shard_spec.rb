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
require_relative "../../spec_helper.rb"

describe Ohai::System, "shard plugin" do
  let(:plugin) { get_plugin("shard") }
  let(:fqdn) { "somehost004.someregion.somecompany.com" }
  let(:uuid) { "48555CF4-5BB1-21D9-BC4C-E8B73DDE5801" }
  let(:serial) { "234du3m4i498xdjr2" }
  let(:machine_id) { "0a1f869f457a4c8080ab19faf80af9cc" }
  let(:machinename) { "somehost004" }

  before(:each) do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    plugin["machinename"] = machinename
    plugin["machine_id"] = machine_id
    plugin["fqdn"] = fqdn
    plugin["dmi"] = { "system" => {} }
    plugin["dmi"]["system"]["uuid"] = uuid
    plugin["dmi"]["system"]["serial_number"] = serial
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  it "should provide a shard with a default-safe set of sources" do
    plugin.run
    result = Digest::MD5.hexdigest(
      "#{machinename}#{serial}#{uuid}"
    )[0...7].to_i(16)
    expect(plugin[:shard_seed]).to eq(result)
  end

  it "should provide a shard with a configured source" do
    Ohai.config[:plugin][:shard_seed][:sources] = [:fqdn]
    plugin.run
    result = Digest::MD5.hexdigest(fqdn)[0...7].to_i(16)
    expect(plugin[:shard_seed]).to eq(result)
  end

  it "fails on an unrecognized source" do
    Ohai.config[:plugin][:shard_seed][:sources] = [:GreatGooglyMoogly]
    expect { plugin.run }.to raise_error(RuntimeError)
  end
end
