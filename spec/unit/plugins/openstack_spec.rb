#
# Author:: Daniel DeLeo (dan@chef.io)
# Copyright:: Copyright (c) 2014-2016 Chef Software, Inc.
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
# WITHOUT WARRANTIES OR CONDIT"Net::HTTP Response"NS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"
require "ohai/plugins/openstack"

describe "OpenStack Plugin" do
  let(:plugin) { get_plugin("openstack") }

  before(:each) do
    allow(plugin).to receive(:hint?).with("openstack").and_return(false)
    plugin[:dmi] = nil
  end

  shared_examples_for "!openstack" do
    before(:each) do
      plugin.run
    end

    it "does NOT create the openstack mash" do
      expect(plugin[:openstack]).to be_nil
    end

    it "doesn't attempt to fetch the Openstack metadata" do
      expect(plugin).not_to receive(:collect_openstack_metadata)
    end
  end

  shared_examples_for "openstack" do
    before(:each) do
      @http_client = double("Net::HTTP client")
      allow(plugin).to receive(:http_client).and_return(@http_client)
      expect(plugin).to receive(:can_metadata_connect?)
      allow(plugin).to receive(:can_metadata_connect?).and_return(true)
      allow(plugin).to receive(:collect_openstack_metadata).with("169.254.169.254", "latest").and_return([])
      plugin.run
    end

    it "creates the openstack mash" do
      expect(plugin[:openstack]).not_to be_nil
    end

    it 'sets openstack[:provider] = "openstack"' do
      expect(plugin[:openstack][:provider]).to eq("openstack")
    end

    it "create the metadata mash" do
      expect(plugin[:openstack][:metadata]).not_to be_nil
    end
  end

  describe "with no openstack ohai hint or dmi data" do
    it_behaves_like "!openstack"
  end

  describe "with an openstack ohai hint" do
    it_behaves_like "openstack"

    before do
      allow(plugin).to receive(:hint?).with("openstack").and_return(true)
    end
  end

  describe "with an openstack dmi data" do
    it_behaves_like "openstack"

    before do
      plugin[:dmi] = { :system => { :all_records => [ { :Manufacturer => "OpenStack Foundation" } ] } }
    end
  end

end
