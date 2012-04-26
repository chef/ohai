#
#  Author:: Laurent Desarmes <laurent.desarmes@u-picardie.fr>
#  Copyright:: Copyright (c) 2012 Laurent Desarmes
#  License:: Apache License, Version 2.0
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, "Network Plugin" do
  
  checks = {
    "linux" => {
      "data" => {
        # pp Hash[node['network']] from  shef to get the network data
        # have just removed the arp entries by hand
        "network" => {"default_interface"=>"eth0",
 "interfaces"=>
          {"lo"=>
            {"flags"=>["LOOPBACK", "UP"],
              "addresses"=>
              {"::1"=>{"scope"=>"Node", "prefixlen"=>"128", "family"=>"inet6"},
                "127.0.0.1"=>
                {"scope"=>"Node",
                  "netmask"=>"255.0.0.0",
                  "prefixlen"=>"8",
                  "family"=>"inet"}},
              "mtu"=>"16436",
              "encapsulation"=>"Loopback"},
            "eth0"=>
            {"flags"=>["BROADCAST", "MULTICAST", "UP"],
              "number"=>"0",
              "addresses"=>
              {"fe80::216:3eff:fe2f:3679"=>
                {"scope"=>"Link", "prefixlen"=>"64", "family"=>"inet6"},
                "00:16:3E:2F:36:79"=>{"family"=>"lladdr"},
                "192.168.66.33"=>
                {"scope"=>"Global",
                  "netmask"=>"255.255.255.0",
                  "broadcast"=>"192.168.66.255",
                  "prefixlen"=>"24",
                  "family"=>"inet"}},
              "routes"=>{"192.168.66.0/24"=>{"scope"=>"Link", "src"=>"192.168.66.33"}},
              "mtu"=>"1500",
              "type"=>"eth",
              "encapsulation"=>"Ethernet"}},
          "default_gateway"=>"192.168.66.15"}  
      },
      "expected_results" => {
        "ipaddress" => "192.168.66.33",
        "macaddress" => "00:16:3E:2F:36:79"
      }
    },
    "linux with {ip,mac}address set from the linux plugin" => {
      "data" => {
        "ipaddress" => "192.168.66.33",
        "macaddress" => "00:16:3E:2F:36:79"
      },
      "expected_results" => {
        "ipaddress" => "192.168.66.33",
        "macaddress" => "00:16:3E:2F:36:79"
      }
    }
  }

    checks.each do | check_name, check_data |
    describe "it checks results from #{check_name}" do
      before do
        @ohai = Ohai::System.new
        @ohai.stub!(:require_plugin).and_return(true)
        check_data["data"].keys.each do |k|
          @ohai[k] = check_data["data"][k]
        end
      end

      check_data["expected_results"].each do |attribute, value|
        it "sets #{attribute}" do
          @ohai._require_plugin("network")
          @ohai.should have_key(attribute)
          @ohai[attribute].should == value!
        end
      end
    end
  end
end
