#
# Author:: Dylan Page (<dpage@digitalocean.com>)
# Author:: Stafford Brunk (<stafford.brunk@gmail.com>)
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

require 'spec_helper'

describe Ohai::System, "plugin digital_ocean" do
  before(:each) do
    @plugin = get_plugin("digital_ocean")
    allow(File).to receive(:exist?).with('/etc/chef/ohai/hints/digital_ocean.json').and_return(false)
    allow(File).to receive(:exist?).with('C:\chef\ohai\hints/digital_ocean.json').and_return(false)
    allow(File).to receive(:exist?).with('/etc/cloud/cloud.cfg').and_return(false)
  end

  shared_examples_for "!digital_ocean" do
    it "should NOT attempt to fetch the digital_ocean metadata" do
      expect(@plugin).not_to receive(:http_client)
      expect(@plugin[:digital_ocean]).to be_nil
      @plugin.run
    end
  end

  shared_examples_for "digital_ocean" do
    before(:each) do
      @http_client = double("Net::HTTP client")
      allow(@plugin).to receive(:http_client).and_return(@http_client)
      allow(IO).to receive(:select).and_return([[],[1],[]])
      t = double("connection")
      allow(t).to receive(:connect_nonblock).and_raise(Errno::EINPROGRESS)
      allow(Socket).to receive(:new).and_return(t)
      allow(Socket).to receive(:pack_sockaddr_in).and_return(nil)
    end

    let(:body) do
     {"droplet_id" => 2756924,
      "hostname" => "sample-droplet",
      "vendor_data" => "#cloud-config\ndisable_root: false\n",
      "public_keys" => ["ssh-rsa pubey sammy@digitalocean.com"],
      "region" => "nyc3",
      "interfaces" => {
        "private" => [
          {
            "ipv4" => {
              "ip_address" => "10.132.255.113",
              "netmask" => "255.255.0.0",
              "gateway" => "10.132.0.1"
            },
            "mac" => "04:01:2a:0f:2a:02",
            "type" => "private"
          }
        ],
        "public" => [
          {
            "ipv4" => {
              "ip_address" => "104.131.20.105",
              "netmask" => "255.255.192.0",
              "gateway" => "104.131.0.1"
            },
            "ipv6":{
              "ip_address" => "2604:A880:0800:0010:0000:0000:017D:2001",
              "cidr" => 64,
              "gateway" => "2604:A880:0800:0010:0000:0000:0000:0001"
            },
            "mac" => "04:01:2a:0f:2a:01",
            "type" => "public"}
        ]
      },
      "floating_ip" => {
        "ipv4" => {
          "active" => false
        }
      },
      "dns" => {
        "nameservers" => [
          "2001:4860:4860::8844",
          "2001:4860:4860::8888",
          "8.8.8.8"
        ]
      }
     }
    end

    it "should fetch and properly parse json metadata" do
      expect(@http_client).to receive(:get).
        with("/metadata/v1.json").
        and_return(double("Net::HTTP Response", :body => body, :code=>"200"))

      @plugin.run

      expect(@plugin[:digital_ocean]).not_to be_nil
      expect(@plugin[:digital_ocean]['droplet_id']).to eq(2756924)
      expect(@plugin[:digital_ocean]['hostname']).to eq("sample-droplet")
    end

    it "should complete the run despite unavailable metadata" do
      expect(@http_client).to receive(:get).
        with("/metadata/v1.json").
        and_return(double("Net::HTTP Response", :body => "", :code => "404"))

      @plugin.run


      expect(@plugin[:digitalocean]).to be_nil
    end
  end

  describe "with metadata address connected" do
    it_should_behave_like "digital_ocean"
  end

  describe "without metadata address connected" do
    it_should_behave_like "!digital_ocean"
  end

  describe "with digital_ocean hint file" do
    it_should_behave_like "digital_ocean"

    before(:each) do
      if windows?
        expect(File).to receive(:exist?).with('C:\chef\ohai\hints/digital_ocean.json').and_return(true)
        allow(File).to receive(:read).with('C:\chef\ohai\hints/digital_ocean.json').and_return("")
      else
        expect(File).to receive(:exist?).with("/etc/chef/ohai/hints/digital_ocean.json").and_return(true)
        allow(File).to receive(:read).with("/etc/chef/ohai/hints/digital_ocean.json").and_return("")
      end
    end
  end

  describe "with digital_ocean cloud-config file" do
    it_should_behave_like "digital_ocean"

    before(:each) do
        expect(File).to receive(:exist?).with("/etc/cloud/cloud.cfg").and_return(true)
        allow(File).to receive(:read).with("/etc/cloud/cloud.cfg").and_return("")
    end
  end
end
