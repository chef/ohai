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
  
  checks = {}
  basic_linux_network_data = {
    # pp Hash[node['network']] from  shef to get the network data
    # have just removed the neighbour and route entries by hand
    "default_interface"=>"eth0",
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
        {
          "fe80::216:3eff:fe2f:3679"=> {"scope"=>"Link", "prefixlen"=>"64", "family"=>"inet6"},
          "00:16:3E:2F:36:79"=>{"family"=>"lladdr"},
          "192.168.66.33"=> {"scope"=>"Global",
            "netmask"=>"255.255.255.0",
            "broadcast"=>"192.168.66.255",
            "prefixlen"=>"24",
            "family"=>"inet"},
          "3ffe:1111:2222::1"=> {
            "prefixlen"=> "48",
            "family"=> "inet6",
            "scope"=> "Global"
          }},
        "mtu"=>"1500",
        "type"=>"eth",
        "encapsulation"=>"Ethernet"}},
    "default_gateway"=>"192.168.66.15",
    "default_inet6_gateway" => "3ffe:1111:2222::"
  }
  checks["1 linux"] = {
    "data" => {
      "network" => basic_linux_network_data
    },
    "expected_results" => {
      "ipaddress" => "192.168.66.33",
      "macaddress" => "00:16:3E:2F:36:79",
      "ip6address" => "3ffe:1111:2222::1"
    }
  }
  #  checks["linux with ipv6"] = {
  #  }
  #  checks["linux with default ipv4 and ipv6 gateway on different interfaces"] = {
  #  }
  #  checks["linux with conflict between default gateway and default address"] = {
  #  }
  checks["2 linux with {ip,mac}address set from the linux plugin"] = {
    "data" => {
      "network" => basic_linux_network_data,
      "ipaddress" => "10.11.12.13",
      "macaddress" => "00:AA:BB:CC:DD:EE",
    },
    "expected_results" => {
      "ipaddress" => "10.11.12.13",
      "macaddress" => "00:AA:BB:CC:DD:EE",
      "ip6address" => "3ffe:1111:2222::1"
    }
  }
  checks["3 linux with {ip,mac}address set from the linux plugin, ip6address detected"] = {
    "data" => {
      "network" => basic_linux_network_data,
      "ipaddress" => "10.11.12.13",
      "macaddress" => "00:AA:BB:CC:DD:EE",
    },
    "expected_results" => {
      "ipaddress" => "10.11.12.13",
      "macaddress" => "00:AA:BB:CC:DD:EE",
      "ip6address" => "3ffe:1111:2222::1"
    }
  }
  checks["4 linux with ip6address set from the linux plugin, {ip,mac}address detected"] = {
    "data" => {
      "network" => basic_linux_network_data,
      "ip6address" => "3ffe:8888:9999::1"
    },
    "expected_results" => {
      "ipaddress" => "192.168.66.33",
      "macaddress" => "00:16:3E:2F:36:79",
      "ip6address" => "3ffe:8888:9999::1"
    }
  }
  checks["5 linux with {mac,ip6}address set from the linux plugin, {ip,mac}address detected"] = {
    "data" => {
      "network" => basic_linux_network_data,
      "ip6address" => "3ffe:8888:9999::1",
      "macaddress" => "00:11:22:33:44:55"
    },
    "expected_results" => {
      "ipaddress" => "192.168.66.33",
      "macaddress" => "00:16:3E:2F:36:79",
      "ip6address" => "3ffe:8888:9999::1"
    }
  }
  checks["6 linux with {ip,mac,ip6}address set from the linux plugin"] = {
    "data" => {
      "network" => basic_linux_network_data,
      "ipaddress" => "10.11.12.13",
      "macaddress" => "00:AA:BB:CC:DD:EE",
      "ip6address" => "3ffe:8888:9999::1"
    },
    "expected_results" => {
      "network" => basic_linux_network_data,
      "ipaddress" => "10.11.12.13",
      "macaddress" => "00:AA:BB:CC:DD:EE",
      "ip6address" => "3ffe:8888:9999::1"
    }
  }
  checks["7 linux with {ip,ip6}address set from the linux plugin"] = {
    "data" => {
      "network" => basic_linux_network_data,
      "ipaddress" => "10.11.12.13",
      "ip6address" => "3ffe:8888:9999::1"
    },
    "expected_results" => {
      "ipaddress" => "10.11.12.13",
      "macaddress" => nil,
      "ip6address" => "3ffe:8888:9999::1"
    }
  }

  checks.keys.sort.each do |check_name|
    check_data = checks[check_name]
    describe "it checks results from #{check_name}" do
      before do
        @ohai = Ohai::System.new
        @ohai.stub!(:require_plugin).and_return(true)
        check_data["data"].keys.each do |k|
          @ohai[k] = check_data["data"][k]
        end
      end

      it "doesn't fail" do
        Ohai::Log.should_not_receive(:debug).with(/Plugin network threw exception/)
        @ohai._require_plugin("network")
      end

      check_data["expected_results"].keys.sort.each do |attribute|
        value = check_data["expected_results"][attribute]
        it "sets #{attribute}" do
          @ohai._require_plugin("network")
          puts "A - #{@ohai["ipaddress"].inspect} - #{@ohai["macaddress"].inspect} - #{@ohai["ip6address"].inspect}"
          @ohai.should have_key(attribute)
          @ohai[attribute].should == value
        end
      end
    end
  end
end
