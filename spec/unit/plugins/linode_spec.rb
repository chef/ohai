#
# Author:: Aaron Kalin (<akalin@martinisoftware.com>)
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

describe Ohai::System, "plugin linode" do
  let(:hint_path_nix) { '/etc/chef/ohai/hints/linode.json' }
  let(:hint_path_win) { 'C:\chef\ohai\hints/linode.json' }

  before do
    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)
    @ohai[:network] = {
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
  end

  shared_examples_for "!linode"  do
    it "does not create the linode mash" do
      @ohai._require_plugin("linode")
      @ohai[:linode].should be_nil
    end
  end

  shared_examples_for "linode" do
    it "creates a linode mash" do
      @ohai._require_plugin("linode")
      @ohai[:linode].should_not be_nil
    end

    it "has all required attributes" do
      @ohai._require_plugin("linode")
      @ohai[:linode][:public_ip].should_not be_nil
    end

    it "has correct values for all attributes" do
      @ohai._require_plugin("linode")
      @ohai[:linode][:public_ip].should == "1.2.3.4"
    end

  end

  context "without linode kernel" do
    before do
      @ohai[:kernel] = { "release" => "3.5.2-x86_64" }
    end

    it_should_behave_like "!linode"
  end

  context "with linode kernel" do
    before do
      @ohai[:kernel] = { "release" => "3.5.2-x86_64-linode24" }
    end

    it_should_behave_like "linode"

    # This test is an interface created according to this guide by Linode
    # http://library.linode.com/networking/configuring-static-ip-interfaces
    context "with configured private ip address as suggested by linode" do
      before do
        @ohai[:network][:interfaces]["eth0:1"] = {
          "addresses" => {
            "5.6.7.8"=> {
              "broadcast"=> "10.176.191.255",
              "netmask"=> "255.255.224.0",
              "family"=> "inet"
            },
            "fe80::4240:f5ff:feab:2836" => {
              "scope"=> "Link",
              "prefixlen"=> "64",
              "family"=> "inet6"
            },
            "40:40:F5:AB:28:36" => {
              "family"=> "lladdr"
            }
          }
        }
      end

      it "detects and sets the private ip" do
        @ohai._require_plugin("linode")
        @ohai[:linode][:private_ip].should_not be_nil
        @ohai[:linode][:private_ip].should == "5.6.7.8"
      end
    end

  end

  describe "with linode cloud file" do
    before do
      File.stub!(:exist?).with(hint_path_nix).and_return(true)
      File.stub!(:read).with(hint_path_nix).and_return('')
      File.stub!(:exist?).with(hint_path_win).and_return(true)
      File.stub!(:read).with(hint_path_win).and_return('')
    end

    it_should_behave_like "linode"
  end

  describe "without cloud file" do
    before do
      File.stub!(:exist?).with(hint_path_nix).and_return(false)
      File.stub!(:exist?).with(hint_path_win).and_return(false)
    end

    it_should_behave_like "!linode"
  end

  context "with ec2 cloud file" do
    let(:hint_path_nix) { '/etc/chef/ohai/hints/ec2.json' }
    let(:hint_path_win) { 'C:\chef\ohai\hints/ec2.json' }

    before do
      File.stub!(:exist?).with(hint_path_nix).and_return(true)
      File.stub!(:read).with(hint_path_nix).and_return('')
      File.stub!(:exist?).with(hint_path_win).and_return(true)
      File.stub!(:read).with(hint_path_win).and_return('')
    end

    it_should_behave_like "!linode"
  end

end
