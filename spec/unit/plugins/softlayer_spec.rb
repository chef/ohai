#
# Author:: Alexey Karpik <alexey.karpik@rightscale.com>
# Author:: Peter Schroeter <peter.schroeter@rightscale.com>
# Author:: Stas Turlo <stanislav.turlo@rightscale.com>
# Copyright:: Copyright (c) 2010-2014 RightScale Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative "../../spec_helper.rb"

describe Ohai::System, "plugin softlayer" do
  let(:plugin) { get_plugin("softlayer") }

  it "not create softlayer if hint file doesn't exists" do
    allow(plugin).to receive(:hint?).with("softlayer").and_return(false)
    plugin.run
    expect(plugin[:softlayer]).to be_nil
  end

  it "do not create node if fetch_metadata raise an error" do
    allow(plugin).to receive(:hint?).with("softlayer").and_return(false)
    allow(plugin).to receive(:fetch_metadata).and_raise(StandardError.new("TEST"))
    plugin.run
    expect(plugin[:softlayer]).to be_nil
  end

  it "create empty node if fetch_metadata return empty hash" do
    allow(plugin).to receive(:hint?).with("softlayer").and_return(true)
    allow(plugin).to receive(:fetch_metadata).and_return({})
    plugin.run
    expect(plugin[:softlayer]).to eq({})
  end

  it "create empty node if fetch_metadata return hash with nil values" do
    metadata = { "local_ipv4" => nil, "public_ipv4" => nil, "public_fqdn" => nil }
    allow(plugin).to receive(:hint?).with("softlayer").and_return(true)
    allow(plugin).to receive(:fetch_metadata).and_return(metadata)
    plugin.run
    expect(plugin[:softlayer]).to eq(metadata)
  end

  it "populate softlayer node with required attributes" do
    metadata = { "local_ipv4" => "192.168.0.1", "public_ipv4" => "8.8.8.8", "public_fqdn" => "abc1234.public.com" }
    allow(plugin).to receive(:hint?).with("softlayer").and_return(true)
    allow(plugin).to receive(:fetch_metadata).and_return(metadata)
    plugin.run
    expect(plugin[:softlayer]).to eq(metadata)
  end
end
