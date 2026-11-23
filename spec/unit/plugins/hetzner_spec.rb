# frozen_string_literal: true
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright (c) 2026 Tim Smith
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

describe Ohai::System, "plugin hetzner" do
  let(:plugin) { get_plugin("hetzner") }

  before do
    allow(plugin).to receive(:hint?).with("hetzner").and_return(false)
    # SMBIOS fields a test doesn't set read as absent, on every platform
    allow(plugin).to receive(:smbios_value).and_return(nil)
    allow(plugin).to receive(:can_socket_connect?).and_return(false)
  end

  shared_examples_for "!hetzner" do
    it "doesn't fetch metadata or set the hetzner attribute" do
      expect(plugin).not_to receive(:fetch_metadata)
      plugin.run
      expect(plugin[:hetzner]).to be_nil
    end
  end

  shared_examples_for "hetzner" do
    it "sets the hetzner attribute from the metadata" do
      allow(plugin).to receive(:fetch_metadata).and_return("instance_id" => 4242, "hostname" => "web-1", "private_networks" => [])
      plugin.run
      expect(plugin[:hetzner][:instance_id]).to eq(4242)
      expect(plugin[:hetzner][:hostname]).to eq("web-1")
    end

    it "keeps the hetzner attribute when the metadata request fails" do
      allow(plugin).to receive(:fetch_metadata).and_raise(Errno::ECONNREFUSED)
      plugin.run
      expect(plugin[:hetzner]).to eq({})
    end
  end

  describe "with no hint and no Hetzner SMBIOS data" do
    it_behaves_like "!hetzner"
  end

  describe "with a hetzner hint" do
    before do
      allow(plugin).to receive(:hint?).with("hetzner").and_return({})
    end

    it_behaves_like "hetzner"
  end

  describe "with the Hetzner system vendor and a metadata service" do
    before do
      allow(plugin).to receive(:smbios_value).with(:sys_vendor).and_return("Hetzner")
      allow(plugin).to receive(:smbios_value).with(:product_name).and_return("vServer")
      allow(plugin).to receive(:can_socket_connect?)
        .with(Ohai::Mixin::HetznerMetadata::HETZNER_METADATA_ADDR, 80)
        .and_return(true)
    end

    it_behaves_like "hetzner"
  end

  describe "with the Hetzner system vendor and no metadata service" do
    # Hetzner hardware outside Hetzner Cloud
    before do
      allow(plugin).to receive(:smbios_value).with(:sys_vendor).and_return("Hetzner")
    end

    it_behaves_like "!hetzner"
  end

  describe "with another vendor and a metadata service" do
    before do
      allow(plugin).to receive(:smbios_value).with(:sys_vendor).and_return("Amazon EC2")
      allow(plugin).to receive(:can_socket_connect?).and_return(true)
    end

    it_behaves_like "!hetzner"
  end
end
