#
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

require 'ipaddress'
require 'spec_helper'

describe Ohai::System, "plugin digital_ocean" do
  let(:hint_path_nix) { '/etc/chef/ohai/hints/digital_ocean.json' }
  let(:hint_path_win) { 'C:\chef\ohai\hints/digital_ocean.json' }
  let(:digitalocean_path) { '/etc/digitalocean' }
  let(:hint) {
    '{
      "droplet_id": 12345678,
      "name": "example.com",
      "image_id": 3240036,
      "size_id": 66,
      "region_id": 4,
      "ip_addresses": {
        "public": "1.2.3.4",
        "private": "5.6.7.8"
      }
    }'
  }

  before do
    @plugin = get_plugin("digital_ocean")
    @plugin[:network] = {
      "interfaces"=> {
        "eth0"=> {
          "addresses"=> {
            "1.2.3.4"=> {
              "netmask"=> "255.255.255.0"
            },
            "2400:6180:0000:00d0:0000:0000:0009:7001"=> {}
          }
        }
      }
    }

    allow(File).to receive(:exist?).with(hint_path_nix).and_return(true)
    allow(File).to receive(:read).with(hint_path_nix).and_return(hint)
    allow(File).to receive(:exist?).with(hint_path_win).and_return(true)
    allow(File).to receive(:read).with(hint_path_win).and_return(hint)
  end


  shared_examples_for "!digital_ocean"  do
    before(:each) do
      @plugin.run
    end

    it "does not create the digital_ocean mash" do
      expect(@plugin[:digital_ocean]).to be_nil
    end
  end

  shared_examples_for "digital_ocean_networking" do
    it "creates the networks attribute" do
      expect(@plugin[:digital_ocean][:networks]).not_to be_nil
    end

    it "pulls ip addresses from the network interfaces" do
      expect(@plugin[:digital_ocean][:networks][:v4]).to eq([{"ip_address" => "1.2.3.4",
                                                         "type" => "public",
                                                         "netmask" => "255.255.255.0"}])
      expect(@plugin[:digital_ocean][:networks][:v6]).to eq([{"ip_address"=>"2400:6180:0000:00d0:0000:0000:0009:7001",
                                                          "type"=>"public",
                                                          "cidr"=>128}])
    end
  end

  shared_examples_for "digital_ocean" do
    before(:each) do
      @plugin.run
    end

    it "creates a digital_ocean mash" do
      expect(@plugin[:digital_ocean]).not_to be_nil
    end

    it "has all hint attributes" do
      expect(@plugin[:digital_ocean][:droplet_id]).not_to be_nil
      expect(@plugin[:digital_ocean][:name]).not_to be_nil
      expect(@plugin[:digital_ocean][:image_id]).not_to be_nil
      expect(@plugin[:digital_ocean][:size_id]).not_to be_nil
      expect(@plugin[:digital_ocean][:region_id]).not_to be_nil
    end

    it "skips the ip_addresses hint attribute" do
      expect(@plugin[:digital_ocean][:ip_addresses]).to be_nil
    end

    it "has correct values for all hint attributes" do
      expect(@plugin[:digital_ocean][:droplet_id]).to eq(12345678)
      expect(@plugin[:digital_ocean][:name]).to eq("example.com")
      expect(@plugin[:digital_ocean][:image_id]).to eq(3240036)
      expect(@plugin[:digital_ocean][:size_id]).to eq(66)
      expect(@plugin[:digital_ocean][:region_id]).to eq(4)
    end

    include_examples 'digital_ocean_networking'
  end

  describe "with digital_ocean hint file" do
    before do
      allow(File).to receive(:exist?).with(hint_path_nix).and_return(true)
      allow(File).to receive(:exist?).with(hint_path_win).and_return(true)
    end

    context "without private networking enabled" do
      it_should_behave_like "digital_ocean"
    end

    context "with private networking enabled" do
      before do
        @plugin[:network][:interfaces][:eth1] = {
          "addresses"=> {
            "10.128.142.89" => {
              "netmask" => "255.255.255.0"
            },
            "fdf8:f53b:82e4:0000:0000:0000:0000:0053" => {}
          }
        }

        @plugin.run
      end

      it "should extract the private networking ips" do
        expect(@plugin[:digital_ocean][:networks][:v4]).to eq([{"ip_address" => "1.2.3.4",
                                                            "type" => "public",
                                                            "netmask" => "255.255.255.0"},
                                                            {"ip_address" => "10.128.142.89",
                                                            "type" => "private",
                                                            "netmask" => "255.255.255.0"}])
        expect(@plugin[:digital_ocean][:networks][:v6]).to eq([{"ip_address"=>"2400:6180:0000:00d0:0000:0000:0009:7001",
                                                            "type"=>"public",
                                                            "cidr"=>128},
                                                           {"ip_address"=>"fdf8:f53b:82e4:0000:0000:0000:0000:0053",
                                                            "type"=>"private",
                                                            "cidr"=>128}])
      end
    end
  end

  describe "without digital_ocean hint file" do
    before do
      allow(File).to receive(:exist?).with(hint_path_nix).and_return(false)
      allow(File).to receive(:exist?).with(hint_path_win).and_return(false)
    end


    describe "with the /etc/digitalocean file" do
      before do
        allow(File).to receive(:exist?).with(digitalocean_path).and_return(true)
        @plugin.run
      end
      it_should_behave_like "digital_ocean_networking"
    end

    describe "without the /etc/digitalocean file" do
      before do
        allow(File).to receive(:exist?).with(digitalocean_path).and_return(false)
      end
      it_should_behave_like "!digital_ocean"
    end
  end

  context "with ec2 hint file" do
    let(:ec2_hint_path_nix) { '/etc/chef/ohai/hints/ec2.json' }
    let(:ec2_hint_path_win) { 'C:\chef\ohai\hints/ec2.json' }

    before do
      allow(File).to receive(:exist?).with(hint_path_nix).and_return(false)
      allow(File).to receive(:exist?).with(hint_path_win).and_return(false)

      allow(File).to receive(:exist?).with(ec2_hint_path_nix).and_return(true)
      allow(File).to receive(:read).with(ec2_hint_path_nix).and_return('')
      allow(File).to receive(:exist?).with(ec2_hint_path_win).and_return(true)
      allow(File).to receive(:read).with(ec2_hint_path_win).and_return('')
    end

    describe "with the /etc/digitalocean file" do
      before do
        allow(File).to receive(:exist?).with(digitalocean_path).and_return(true)
        @plugin.run
      end
      it_should_behave_like "digital_ocean_networking"
    end

    describe "without the /etc/digitalocean file" do
      before do
        allow(File).to receive(:exist?).with(digitalocean_path).and_return(false)
      end
      it_should_behave_like "!digital_ocean"
    end
  end
end
