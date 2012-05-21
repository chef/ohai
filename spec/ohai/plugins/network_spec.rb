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

def it_does_not_fail
  it "doesn't fail" do
    Ohai::Log.should_not_receive(:debug).with(/Plugin network threw exception/)
    @ohai._require_plugin("network")
    %w[ ipaddress, macaddress, ip6address ].each do |attribute|
      @ohai.should have_key(attribute)
    end
  end
end      

describe Ohai::System, "Network Plugin" do
  
  basic_network_data = {
    "linux" => {
      # pp Hash[node['network']] from  shef to get the network data
      # have just removed the neighbour and route entries by hand
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
            "3ffe:1111:2222::33"=> {
              "prefixlen"=> "48",
              "family"=> "inet6",
              "scope"=> "Global"
            }},
          "mtu"=>"1500",
          "type"=>"eth",
          "encapsulation"=>"Ethernet"},
        "eth1"=>
        {"flags"=>["BROADCAST", "MULTICAST", "UP"],
          "number"=>"1",
          "addresses"=>
          {
            "fe80::216:3eff:fe2f:3680"=> {"scope"=>"Link", "prefixlen"=>"64", "family"=>"inet6"},
            "00:16:3E:2F:36:80"=>{"family"=>"lladdr"},
            "192.168.99.11"=> {"scope"=>"Global",
              "netmask"=>"255.255.255.0",
              "broadcast"=>"192.168.99.255",
              "prefixlen"=>"24",
              "family"=>"inet"},
            "3ffe:1111:3333::1"=> {
              "prefixlen"=> "48",
              "family"=> "inet6",
              "scope"=> "Global"
          }},
          "mtu"=>"1500",
          "type"=>"eth",
        "encapsulation"=>"Ethernet"}},
      "default_gateway"=>"192.168.66.15",
      "default_interface" => "eth0",
      "default_inet6_gateway" => "3ffe:1111:2222::",
      "default_inet6_interface" => "eth0"
    }
  }
  
  %w[ linux ].each do |os|
    describe "with #{os}" do
      before(:each) do
        @ohai = Ohai::System.new
        @ohai.stub!(:require_plugin).and_return(true)
        @ohai["network"] = basic_network_data[os]
      end
      
      describe "when the #{os}::network plugin hasn't set {ip,ip6,mac}address" do
        context "simple setup" do
          it_does_not_fail
          
          it "detects {ip,ip6,mac}address" do
            @ohai._require_plugin("network")          
            @ohai["ipaddress"].should == "192.168.66.33"
            @ohai["macaddress"].should == "00:16:3E:2F:36:79"
            @ohai["ip6address"].should == "3ffe:1111:2222::33"
          end
        end
        
        context "default ipv4 and ipv6 gateway on different interfaces" do
          before do
            @ohai["network"]["default_inet6_gateway"] = "3ffe:1111:3333::"
            @ohai["network"]["default_inet6_interface"] = "eth1"
          end
          
          it_does_not_fail
          
          it "detects {ip,ip6,mac}address" do
            @ohai._require_plugin("network")          
            @ohai["ipaddress"].should == "192.168.66.33"
            @ohai["macaddress"].should == "00:16:3E:2F:36:79"
            @ohai["ip6address"].should == "3ffe:1111:3333::1"
          end
          
          it "informs about this setup" do
            Ohai::Log.should_receive(:info).with(/ipaddress and ip6address are set from different interfaces/)
            @ohai._require_plugin("network")
          end
        end
        
        context "conflicting results" do
          before do
            @ohai["network"]["default_interface"] = "eth1"
            @ohai["network"]["default_inet6_interface"] = "eth1"
          end
          
          it_does_not_fail
          
          it "detects {ip,ip6,mac}address" do
            @ohai._require_plugin("network")          
            @ohai["ipaddress"].should == "192.168.66.33"
            @ohai["macaddress"].should == "00:16:3E:2F:36:79"
            @ohai["ip6address"].should == "3ffe:1111:2222::33"
          end
          
          it "warns about this conflict" do
            Ohai::Log.should_receive(:warn).with(/conflict when looking for the default/).exactly(2).times
            @ohai._require_plugin("network")
          end
        end
        
        context "several ipaddresses matching the default route, bigger prefix wins" do
          before do
            @ohai["network"]["interfaces"]["eth2"] = {
              "flags" =>["BROADCAST", "MULTICAST", "UP"],
              "number" =>"2",
              "addresses" => {
                "fe80::216:3eff:fe2f:3681" => { "scope"=>"Link", "prefixlen"=>"64", "family"=>"inet6"},
                "00:16:3E:2F:36:81" =>{"family"=>"lladdr"},
                "192.168.66.99" => {
                  "scope"=>"Global",
                  "netmask"=>"255.255.255.127",
                  "broadcast"=>"192.168.99.127",
                  "prefixlen"=>"25",
                  "family"=>"inet"},
                "3ffe:1111:2222:0:4444::1"=> {
                  "prefixlen"=> "64",
                  "family"=> "inet6",
                  "scope"=> "Global"
                }
              }
            }
          end
          
          it_does_not_fail
          
          it "detects {ip,ip6,mac}address" do
            @ohai._require_plugin("network")          
            @ohai["ipaddress"].should == "192.168.66.99"
            @ohai["macaddress"].should == "00:16:3E:2F:36:81"
            @ohai["ip6address"].should == "3ffe:1111:2222:0:4444::1"
          end
        end

        context "several ipaddresses matching the default route, smallest ip wins" do
          before do
            @ohai["network"]["interfaces"]["eth2"] = {
              "flags" =>["BROADCAST", "MULTICAST", "UP"],
              "number" =>"2",
              "addresses" => {
                "fe80::216:3eff:fe2f:3681" => { "scope"=>"Link", "prefixlen"=>"64", "family"=>"inet6"},
                "00:16:3E:2F:36:81" =>{"family"=>"lladdr"},
                "192.168.66.32" => {
                  "scope"=>"Global",
                  "netmask"=>"255.255.255.0",
                  "broadcast"=>"192.168.66.255",
                  "prefixlen"=>"24",
                  "family"=>"inet"},
                "3ffe:1111:2222::32"=> {
                  "prefixlen"=> "48",
                  "family"=> "inet6",
                  "scope"=> "Global"
                }
              }
            }
          end
          
          it_does_not_fail
          
          it "detects {ip,ip6,mac}address" do
            @ohai._require_plugin("network")          
            @ohai["ipaddress"].should == "192.168.66.32"
            @ohai["macaddress"].should == "00:16:3E:2F:36:81"
            @ohai["ip6address"].should == "3ffe:1111:2222::32"
          end
        end

	context "no default route" do
          before do
            @ohai["network"]["default_gateway"] = nil
            @ohai["network"]["default_interface"] = nil
            @ohai["network"]["default_inet6_gateway"] = nil
            @ohai["network"]["default_inet6_interface"] = nil
            # removing inet* addresses from eth0, to complicate things a bit
            @ohai["network"]["interfaces"]["eth0"]["addresses"].delete_if{|k,v| %w[inet inet6].include? v["family"]}
          end

          it_does_not_fail

          it "picks {ip,mac,ip6}address from the first interface" do
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should == "192.168.99.11"
            @ohai["macaddress"].should == "00:16:3E:2F:36:80"
            @ohai["ip6address"].should == "3ffe:1111:3333::1"
          end
	end

	context "link level default route" do
	pending
        end

	context "link level addresses" do
	pending
        end

      end
      
      describe "when the #{os}::network plugin sets {ip,mac}address" do
        before do
          @ohai["ipaddress"] = "10.11.12.13"
          @ohai["macaddress"] = "00:AA:BB:CC:DD:EE"
        end

        it_does_not_fail
        
        it "detects ip6address" do
          @ohai._require_plugin("network")
          @ohai["ip6address"].should == "3ffe:1111:2222::33"
        end
        
        it "doesn't overwrite {ip,mac}address" do
          @ohai._require_plugin("network")
          @ohai["ipaddress"].should == "10.11.12.13"
          @ohai["macaddress"].should == "00:AA:BB:CC:DD:EE"
        end
      end

      describe "when the #{os}::network plugin sets ip6address" do
        before do
          @ohai["ip6address"] = "3ffe:8888:9999::1"
        end

        it_does_not_fail
        
        it "detects {ip,mac}address" do
          @ohai._require_plugin("network")
          @ohai["ipaddress"].should == "192.168.66.33"
          @ohai["macaddress"].should == "00:16:3E:2F:36:79"
        end
        
        it "doesn't overwrite ip6address" do
          @ohai._require_plugin("network")
          @ohai["ip6address"].should == "3ffe:8888:9999::1"
        end
      end
      
      describe "when the #{os}::network plugin sets {mac,ip6}address" do
        before do
          @ohai["macaddress"] = "00:AA:BB:CC:DD:EE"
          @ohai["ip6address"] = "3ffe:8888:9999::1"
        end

        it_does_not_fail
        
        it "detects {ip,mac}address" do
          @ohai._require_plugin("network")
          @ohai["ipaddress"].should == "192.168.66.33"
          @ohai["macaddress"].should == "00:16:3E:2F:36:79"
        end
        
        it "doesn't overwrite ip6address" do
          @ohai._require_plugin("network")
          @ohai["ip6address"].should == "3ffe:8888:9999::1"
        end
      end
      
      describe "when the #{os}::network plugin sets {ip,mac,ip6}address" do
        before do
          @ohai["ipaddress"] = "10.11.12.13"
          @ohai["macaddress"] = "00:AA:BB:CC:DD:EE"
          @ohai["ip6address"] = "3ffe:8888:9999::1"
        end

        it_does_not_fail
        
        it "doesn't overwrite {ip,mac,ip6}address" do
          @ohai._require_plugin("network")
          @ohai["ipaddress"].should == "10.11.12.13"
          @ohai["macaddress"].should == "00:AA:BB:CC:DD:EE"
          @ohai["ip6address"].should == "3ffe:8888:9999::1"
        end
      end

      describe "when the #{os}::network plugin sets {ip,ip6}address" do
        before do
          @ohai["ipaddress"] = "10.11.12.13"
          @ohai["ip6address"] = "3ffe:8888:9999::1"
        end
        
        it_does_not_fail
        
        it "doesn't overwrite {ip,mac,ip6}address" do
          @ohai._require_plugin("network")
          @ohai["ipaddress"].should == "10.11.12.13"
          @ohai["macaddress"].should == nil
          @ohai["ip6address"].should == "3ffe:8888:9999::1"
        end
      end

    end
    
  end
end
