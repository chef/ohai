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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, "plugin digital_ocean" do
  let(:hint_path_nix) { '/etc/chef/ohai/hints/digital_ocean.json' }
  let(:hint_path_win) { 'C:\chef\ohai\hints/digital_ocean.json' }
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
              "broadcast"=> "67.23.20.255",
              "netmask"=> "255.255.255.0",
              "family"=> "inet"
            },
            "fe80::4240:95ff:fe47:6eed"=> {
              "scope"=> "Link",
              "prefixlen"=> "64",
              "family"=> "inet6"
            },
            "40:40:95:47:6E:ED" => {
              "family" => "lladdr"
            }
          }
        }
      }
    }

    File.stub(:read).with(hint_path_nix).and_return(hint)
    File.stub(:read).with(hint_path_win).and_return(hint)
  end


  shared_examples_for "!digital_ocean"  do
    before(:each) do
      @plugin.run
    end

    it "does not create the digital_ocean mash" do
      @plugin[:digital_ocean].should be_nil
    end
  end

  shared_examples_for "digital_ocean" do
    before(:each) do
      @plugin.run
    end

    it "creates a digital_ocean mash" do
      @plugin[:digital_ocean].should_not be_nil
    end

    it "has all hint attributes" do
      @plugin[:digital_ocean][:droplet_id].should_not be_nil
      @plugin[:digital_ocean][:name].should_not be_nil
      @plugin[:digital_ocean][:image_id].should_not be_nil
      @plugin[:digital_ocean][:size_id].should_not be_nil
      @plugin[:digital_ocean][:region_id].should_not be_nil
      @plugin[:digital_ocean][:ip_addresses].should_not be_nil
      @plugin[:digital_ocean][:ip_addresses][:public].should_not be_nil
      @plugin[:digital_ocean][:ip_addresses][:private].should_not be_nil
    end

    it "has correct values for all hint attributes" do
      @plugin[:digital_ocean][:droplet_id].should == 12345678
      @plugin[:digital_ocean][:name].should == "example.com"
      @plugin[:digital_ocean][:image_id].should == 3240036
      @plugin[:digital_ocean][:size_id].should == 66
      @plugin[:digital_ocean][:region_id].should == 4
    end

    it "pulls ip addresses from the network interfaces" do
      @plugin[:digital_ocean][:ip_addresses][:public].should == {"ipv4"=>["1.2.3.4"], "ipv6"=>["fe80::4240:95ff:fe47:6eed"]}
      @plugin[:digital_ocean][:ip_addresses][:private].should == {"ipv4"=>[], "ipv6"=>[]}
    end

  end

  describe "with digital_ocean hint file" do
    before do
      File.stub(:exist?).with(hint_path_nix).and_return(true)
      File.stub(:exist?).with(hint_path_win).and_return(true)
    end

    context "without private networking enabled" do
      it_should_behave_like "digital_ocean"
    end

    context "with private networking enabled" do
      before do
        @plugin[:network][:interfaces][:eth1] = {
          "addresses"=> {
            "5.6.7.8"=> {
              "broadcast"=> "67.23.20.255",
              "netmask"=> "255.255.255.0",
              "family"=> "inet"
            },
            "fe80::4240:95ff:fe47:6eee"=> {
              "scope"=> "Link",
              "prefixlen"=> "64",
              "family"=> "inet6"
            },
            "40:40:95:47:6E:ED" => {
              "family" => "lladdr"
            }
          }
        }

        @plugin.run
      end

      it "should have the correct values for the private networking ips" do
        @plugin[:digital_ocean][:ip_addresses][:private].should == {"ipv4"=>["5.6.7.8"], "ipv6"=>["fe80::4240:95ff:fe47:6eee"]}
      end
    end
  end

  describe "without digital_ocean hint file" do
    before do
      File.stub(:exist?).with(hint_path_nix).and_return(false)
      File.stub(:exist?).with(hint_path_win).and_return(false)
    end

    it_should_behave_like "!digital_ocean"
  end

  context "with ec2 hint file" do
    let(:ec2_hint_path_nix) { '/etc/chef/ohai/hints/ec2.json' }
    let(:ec2_hint_path_win) { 'C:\chef\ohai\hints/ec2.json' }

    before do
      File.stub(:exist?).with(hint_path_nix).and_return(false)
      File.stub(:exist?).with(hint_path_win).and_return(false)

      File.stub(:exist?).with(ec2_hint_path_nix).and_return(true)
      File.stub(:read).with(ec2_hint_path_nix).and_return('')
      File.stub(:exist?).with(ec2_hint_path_win).and_return(true)
      File.stub(:read).with(ec2_hint_path_win).and_return('')
    end

    it_should_behave_like "!digital_ocean"
  end

end

