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
    Ohai::Log.should_receive(:warn).any_number_of_times
    Ohai::Log.should_not_receive(:debug).with(/^Plugin network threw exception/)
    @ohai._require_plugin("network")
    %w[ ipaddress, macaddress, ip6address ].each do |attribute|
      @ohai.should have_key(attribute)
    end
  end
end

describe Ohai::System, "Network Plugin" do

  basic_data = {
    "linux" => {
      "network" => {
        # pp Hash[node['network']] from  shef to get the network data
        # have just removed the neighbour and route entries by hand
        "interfaces" => {
          "lo" => {
            "flags" => ["LOOPBACK", "UP"],
            "addresses" => {
              "::1" => {
                "scope" => "Node",
                "prefixlen" => "128",
                "family" => "inet6"
              },
              "127.0.0.1" => {
                "scope" => "Node",
                "netmask" => "255.0.0.0",
                "prefixlen" => "8",
                "family" => "inet"
              }
            },
            "mtu" => "16436",
            "encapsulation" => "Loopback"
          },
          "eth0" => {
            "flags" => ["BROADCAST", "MULTICAST", "UP"],
            "number" => "0",
            "addresses" => {
              "fe80::216:3eff:fe2f:3679" => {
                "scope" => "Link",
                "prefixlen" => "64",
                "family" => "inet6"
              },
              "00:16:3E:2F:36:79" => {"family" => "lladdr"},
              "192.168.66.33" => {
                "scope" => "Global",
                "netmask" => "255.255.255.0",
                "broadcast" => "192.168.66.255",
                "prefixlen" => "24",
                "family" => "inet"
              },
              "3ffe:1111:2222::33" => {
                "prefixlen" => "48",
                "family" => "inet6",
                "scope" => "Global"
              }
            },
            "mtu" => "1500",
            "type" => "eth",
            "encapsulation" => "Ethernet"
          },
          "eth1" => {
            "flags" => ["BROADCAST", "MULTICAST", "UP"],
            "number" => "1",
            "addresses" => {
              "fe80::216:3eff:fe2f:3680" => {
                "scope" => "Link",
                "prefixlen" => "64",
                "family" => "inet6"
              },
              "00:16:3E:2F:36:80" => {"family" => "lladdr"},
              "192.168.99.11" => {
                "scope" => "Global",
                "netmask" => "255.255.255.0",
                "broadcast" => "192.168.99.255",
                "prefixlen" => "24",
                "family" => "inet"
              },
              "3ffe:1111:3333::1" => {
                "prefixlen" => "48",
                "family" => "inet6",
                "scope" => "Global"
              }
            },
            "mtu" => "1500",
            "type" => "eth",
            "encapsulation" => "Ethernet"
          }
        },
        "default_gateway" => "192.168.66.15",
        "default_interface" => "eth0",
        "default_inet6_gateway" => "3ffe:1111:2222::",
        "default_inet6_interface" => "eth0"
      }
    },
    "windows" => {
      "network" => {
        "interfaces" => {
          "0xb" => {
            "addresses" => {
              "172.19.0.130" => {
                "prefixlen" => "24",
                "netmask" => "255.255.255.0",
                "broadcast" => "172.19.0.255",
                "family" => "inet"
              },
              "fe80::698d:3e37:7950:b28c" => {
                "prefixlen" => "64",
                "family" => "inet6",
                "scope" => "Link"
              },
              "52:54:44:66:66:02" => {
                "family" => "lladdr"
              }
            },
            "mtu" => nil,
            "type" => "Ethernet 802.3",
            "encapsulation" => "Ethernet"
          }
        },
        "default_gateway" => "172.19.0.1",
        "default_interface" => "0xb"
      }
    }
  }

  describe "with linux" do
    before(:each) do
      @ohai = Ohai::System.new
      @ohai.stub!(:require_plugin).twice.and_return(true)
      @ohai["network"] = basic_data["linux"]["network"]
    end

    describe "when the linux::network plugin hasn't set any of {ip,ip6,mac}address attributes" do
      describe "simple setup" do
        it_does_not_fail

        it "logs 2 debug messages" do
          Ohai::Log.should_receive(:debug).with(/^Loading plugin network/).once
          Ohai::Log.should_receive(:debug).with(/^\[inet\] Using default/).once
          Ohai::Log.should_receive(:debug).with(/^\[inet6\] Using default/).once
          @ohai._require_plugin("network")
        end

        it "detects {ip,ip6,mac}address" do
          @ohai._require_plugin("network")
          @ohai["ipaddress"].should == "192.168.66.33"
          @ohai["macaddress"].should == "00:16:3E:2F:36:79"
          @ohai["ip6address"].should == "3ffe:1111:2222::33"
        end
      end

      describe "default ipv4 and ipv6 gateway on different interfaces" do
        describe "both interfaces have an ARP" do
          before do
            @ohai["network"]["default_inet6_gateway"] = "3ffe:1111:3333::"
            @ohai["network"]["default_inet6_interface"] = "eth1"
          end

          it_does_not_fail

          it "detects {ip,ip6}address" do
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should == "192.168.66.33"
            @ohai["ip6address"].should == "3ffe:1111:3333::1"
          end

          it "set macaddress from the ipv4 setup" do
            @ohai._require_plugin("network")
            @ohai["macaddress"].should == "00:16:3E:2F:36:79"
          end

          it "informs about this setup" do
            Ohai::Log.should_receive(:info).with(/^ipaddress and ip6address are set from different interfaces/)
            @ohai._require_plugin("network")
          end
        end

        describe "ipv4 interface has no ARP" do
          before do
            @ohai["network"]["interfaces"]["eth0"]["addresses"].delete_if{|k,kv| kv["family"] == "lladdr" }
            # not really checked by this pluging
            @ohai["network"]["interfaces"]["eth0"]["flags"] << "NOARP"
            @ohai["network"]["default_inet6_gateway"] = "3ffe:1111:3333::"
            @ohai["network"]["default_inet6_interface"] = "eth1"
          end

          it_does_not_fail

          it "detects {ip,ip6}address" do
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should == "192.168.66.33"
            @ohai["ip6address"].should == "3ffe:1111:3333::1"
          end

          it "doesn't set macaddress, ipv4 setup is valid and has precedence over ipv6" do
            Ohai::Log.should_not_receive(:warn).with(/^unable to detect macaddress/)
            @ohai._require_plugin("network")
            @ohai["macaddress"].should be_nil
          end

          it "informs about this setup" do
            Ohai::Log.should_receive(:info).with(/^ipaddress and ip6address are set from different interfaces/)
            @ohai._require_plugin("network")
          end
        end
      end

      describe "conflicting results from the linux::network plugin" do
        describe "default interface doesn't match the default_gateway" do
          before do
            @ohai["network"]["default_interface"] = "eth1"
            @ohai["network"]["default_inet6_interface"] = "eth1"
          end

          it_does_not_fail

          it "doesn't detect {ip,ip6,mac}address" do
            Ohai::Log.should_receive(:warn).any_number_of_times
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should be_nil
            @ohai["macaddress"].should be_nil
            @ohai["ip6address"].should be_nil
          end

          it "warns about this conflict" do
            Ohai::Log.should_receive(:warn).with(/^\[inet\] no ipaddress\/mask on eth1/).once
            Ohai::Log.should_receive(:warn).with(/^unable to detect ipaddress/).once
            Ohai::Log.should_receive(:warn).with(/^unable to detect macaddress/).once
            Ohai::Log.should_receive(:warn).with(/^\[inet6\] no ipaddress\/mask on eth1/).once
            Ohai::Log.should_receive(:warn).with(/^unable to detect ip6address/).once
            @ohai._require_plugin("network")
          end
        end

        describe "no ip address for the given default interface/gateway" do
          before do
            @ohai["network"]["interfaces"]["eth0"]["addresses"].delete_if{|k,v| %w[inet inet6].include? v["family"]}
          end

          it_does_not_fail

          it "doesn't detect {ip,ip6,mac}address" do
            Ohai::Log.should_receive(:warn).any_number_of_times
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should be_nil
            @ohai["macaddress"].should be_nil
            @ohai["ip6address"].should be_nil
          end

          it "warns about this conflict" do
            Ohai::Log.should_receive(:warn).with(/^unable to detect ipaddress/).once
            Ohai::Log.should_receive(:warn).with(/^unable to detect macaddress/).once
            Ohai::Log.should_receive(:warn).with(/^\[inet\] no ip on eth0/).once
            Ohai::Log.should_receive(:warn).with(/^unable to detect ip6address/).once
            Ohai::Log.should_receive(:warn).with(/^\[inet6\] no ip on eth0/).once
            @ohai._require_plugin("network")
          end
        end

        describe "no ip at all" do
          before do
            @ohai["network"]["default_gateway"] = nil
            @ohai["network"]["default_interface"] = nil
            @ohai["network"]["default_inet6_gateway"] = nil
            @ohai["network"]["default_inet6_interface"] = nil
            @ohai["network"]["interfaces"].each do |i,iv|
              iv["addresses"].delete_if{|k,kv| %w[inet inet6].include? kv["family"]}
            end
          end

          it_does_not_fail

          it "doesn't detect {ip,ip6,mac}address" do
            Ohai::Log.should_receive(:warn).any_number_of_times
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should be_nil
            @ohai["macaddress"].should be_nil
            @ohai["ip6address"].should be_nil
          end

          it "should warn about it" do
            Ohai::Log.should_receive(:warn).with(/^unable to detect ipaddress/).once
            Ohai::Log.should_receive(:warn).with(/^unable to detect macaddress/).once
            Ohai::Log.should_receive(:warn).with(/^unable to detect ip6address/).once
            @ohai._require_plugin("network")
          end
        end
      end

      describe "several ipaddresses matching the default route" do
        describe "bigger prefix not set on the default interface" do
          before do
            @ohai["network"]["interfaces"]["eth2"] = {
              "flags" => ["BROADCAST", "MULTICAST", "UP"],
              "number" => "2",
              "addresses" => {
                "fe80::216:3eff:fe2f:3681" => {
                  "scope" => "Link",
                  "prefixlen" => "64",
                  "family" => "inet6"
                },
                "00:16:3E:2F:36:81" => {"family" => "lladdr"},
                "192.168.66.99" => {
                  "scope" => "Global",
                  "netmask" => "255.255.255.128",
                  "broadcast" => "192.168.99.127",
                  "prefixlen" => "25",
                  "family" => "inet"
                },
                "3ffe:1111:2222:0:4444::1" => {
                  "prefixlen" => "64",
                  "family" => "inet6",
                  "scope" => "Global"
                }
              }
            }
          end

          it_does_not_fail

          it "sets {ip,ip6,mac}address correctly" do
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should == "192.168.66.33"
            @ohai["macaddress"].should == "00:16:3E:2F:36:79"
            @ohai["ip6address"].should == "3ffe:1111:2222::33"
          end
        end

        describe "bigger prefix set on the default interface" do
          before do
            @ohai["network"]["interfaces"]["eth0"]["addresses"]["192.168.66.99"] = {
              "scope" => "Global",
              "netmask" => "255.255.255.128",
              "broadcast" => "192.168.66.127",
              "prefixlen" => "25",
              "family" => "inet"
            }
            @ohai["network"]["interfaces"]["eth0"]["addresses"]["3ffe:1111:2222:0:4444::1"] = {
              "prefixlen" => "64",
              "family" => "inet6",
              "scope" => "Global"
            }
          end

          it_does_not_fail

          it "sets {ip,ip6,mac}address correctly" do
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should == "192.168.66.99"
            @ohai["macaddress"].should == "00:16:3E:2F:36:79"
            @ohai["ip6address"].should == "3ffe:1111:2222:0:4444::1"
          end
        end

        describe "smallest ip not set on the default_interface" do
          before do
            @ohai["network"]["interfaces"]["eth2"] = {
              "flags" => ["BROADCAST", "MULTICAST", "UP"],
              "number" => "2",
              "addresses" => {
                "fe80::216:3eff:fe2f:3681" => {
                  "scope" => "Link",
                  "prefixlen" => "64",
                  "family" => "inet6"
                },
                "00:16:3E:2F:36:81" => {"family" => "lladdr"},
                "192.168.66.32" => {
                  "scope" => "Global",
                  "netmask" => "255.255.255.0",
                  "broadcast" => "192.168.66.255",
                  "prefixlen" => "24",
                  "family" => "inet"
                },
                "3ffe:1111:2222::32" => {
                  "prefixlen" => "48",
                  "family" => "inet6",
                  "scope" => "Global"
                }
              }
            }
          end

          it_does_not_fail

          it "sets {ip,ip6,mac}address correctly" do
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should == "192.168.66.33"
            @ohai["macaddress"].should == "00:16:3E:2F:36:79"
            @ohai["ip6address"].should == "3ffe:1111:2222::33"
          end
        end

        describe "smallest ip set on the default_interface" do
          before do
            @ohai["network"]["interfaces"]["eth0"]["addresses"]["192.168.66.32"] = {
              "scope" => "Global",
              "netmask" => "255.255.255.0",
              "broadcast" => "192.168.66.255",
              "prefixlen" => "24",
              "family" => "inet"
            }
            @ohai["network"]["interfaces"]["eth0"]["addresses"]["3ffe:1111:2222::32"] = {
              "prefixlen" => "48",
              "family" => "inet6",
              "scope" => "Global"
            }
          end

          it_does_not_fail

          it "sets {ip,ip6,mac}address correctly" do
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should == "192.168.66.32"
            @ohai["macaddress"].should == "00:16:3E:2F:36:79"
            @ohai["ip6address"].should == "3ffe:1111:2222::32"
          end
        end
      end

      describe "no default route" do
        describe "first interface is not the best choice" do
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
            Ohai::Log.should_receive(:info).with(/^\[inet\] no default interface/).once
            Ohai::Log.should_receive(:info).with(/^\[inet6\] no default interface/).once
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should == "192.168.99.11"
            @ohai["macaddress"].should == "00:16:3E:2F:36:80"
            @ohai["ip6address"].should == "3ffe:1111:3333::1"
          end
        end

        describe "can choose from addresses with different scopes" do
          before do
            @ohai["network"]["default_gateway"] = nil
            @ohai["network"]["default_interface"] = nil
            @ohai["network"]["default_inet6_gateway"] = nil
            @ohai["network"]["default_inet6_interface"] = nil
            # just changing scopes to lInK for eth0 addresses
            @ohai["network"]["interfaces"]["eth0"]["addresses"].each{|k,v| v[:scope]="lInK" if %w[inet inet6].include? v["family"]}
          end

          it_does_not_fail

          it "prefers global scope addressses to set {ip,mac,ip6}address" do
            Ohai::Log.should_receive(:info).with(/^\[inet\] no default interface/).once
            Ohai::Log.should_receive(:info).with(/^\[inet6\] no default interface/).once
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should == "192.168.99.11"
            @ohai["macaddress"].should == "00:16:3E:2F:36:80"
            @ohai["ip6address"].should == "3ffe:1111:3333::1"
          end
        end
      end

      describe "link level default route" do
        describe "simple setup" do
          before do
            @ohai["network"]["default_gateway"] = "0.0.0.0"
            @ohai["network"]["default_interface"] = "eth1"
            @ohai["network"]["default_inet6_gateway"] = "::"
            @ohai["network"]["default_inet6_interface"] = "eth1"
          end

          it_does_not_fail

          it "displays debug messages" do
            Ohai::Log.should_receive(:debug).with(/^Loading plugin network/).once
            Ohai::Log.should_receive(:debug).with(/^link level default inet /).once
            Ohai::Log.should_receive(:debug).with(/^link level default inet6 /).once
            @ohai._require_plugin("network")
          end

          it "picks {ip,mac,ip6}address from the default interface" do
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should == "192.168.99.11"
            @ohai["macaddress"].should == "00:16:3E:2F:36:80"
            @ohai["ip6address"].should == "3ffe:1111:3333::1"
          end
        end

        describe "can choose from addresses with different scopes" do
          before do
            @ohai["network"]["default_gateway"] = "0.0.0.0"
            @ohai["network"]["default_interface"] = "eth1"
            @ohai["network"]["default_inet6_gateway"] = "::"
            @ohai["network"]["default_inet6_interface"] = "eth1"
            @ohai["network"]["interfaces"]["eth1"]["addresses"]["127.0.0.2"] = {
              "scope" => "host",
              "netmask" => "255.255.255.255",
              "prefixlen" => "32",
              "family" => "inet"
            }
          end

          it_does_not_fail

          it "displays debug messages" do
            Ohai::Log.should_receive(:debug).with(/^Loading plugin network/).once
            Ohai::Log.should_receive(:debug).with(/^link level default inet /).once
            Ohai::Log.should_receive(:debug).with(/^link level default inet6 /).once
            @ohai._require_plugin("network")
          end

          it "picks {ip,mac,ip6}address from the default interface" do
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should == "192.168.99.11"
            @ohai["macaddress"].should == "00:16:3E:2F:36:80"
            @ohai["ip6address"].should == "3ffe:1111:3333::1"
          end
        end
      end

      describe "point to point address" do
        before do
          @ohai["network"]["interfaces"]["eth2"] = {
            "flags" => ["POINTOPOINT", "BROADCAST", "MULTICAST", "UP"],
            "number" => "2",
            "addresses" => {
              "fe80::216:3eff:fe2f:3681" => {
                "scope" => "Link",
                "prefixlen" => "64",
                "family" => "inet6"
              },
              "00:16:3E:2F:36:81" => {"family" => "lladdr"},
              "192.168.66.99" => {
                "scope" => "Global",
                "netmask" => "255.255.255.255",
                "peer" => "192.168.99.126",
                "prefixlen" => "32",
                "family" => "inet"
              },
              "3ffe:1111:2222:0:4444::1" => {
                "prefixlen" => "128",
                "peer" => "3ffe:1111:2222:0:4444::2",
                "family" => "inet6",
                "scope" => "Global"
              }
            }
          }
          @ohai["network"]["default_gateway"] = "192.168.99.126"
          @ohai["network"]["default_interface"] = "eth2"
          @ohai["network"]["default_inet6_gateway"] = "3ffe:1111:2222:0:4444::2"
          @ohai["network"]["default_inet6_interface"] = "eth2"
        end

        it_does_not_fail

        it "picks {ip,mac,ip6}address from the default interface" do
          @ohai._require_plugin("network")
          @ohai["ipaddress"].should == "192.168.66.99"
          @ohai["macaddress"].should == "00:16:3E:2F:36:81"
          @ohai["ip6address"].should == "3ffe:1111:2222:0:4444::1"
        end
      end

      describe "ipv6 only node" do
        before do
          @ohai["network"]["default_gateway"] = nil
          @ohai["network"]["default_interface"] = nil
          @ohai["network"]["interfaces"].each do |i,iv|
            iv["addresses"].delete_if{|k,kv| kv["family"] == "inet" }
          end
        end

        it_does_not_fail

        it "can't detect ipaddress" do
          Ohai::Log.should_receive(:warn).any_number_of_times
          @ohai._require_plugin("network")
          @ohai["ipaddress"].should be_nil
        end

        it "warns about not being able to set {ip,mac}address (ipv4)" do
          Ohai::Log.should_receive(:warn).with(/^unable to detect ipaddress/).once
          Ohai::Log.should_receive(:warn).with(/^unable to detect macaddress/).once
          @ohai._require_plugin("network")
        end

        it "sets {ip6,mac}address" do
          Ohai::Log.should_receive(:warn).any_number_of_times
          @ohai._require_plugin("network")
          @ohai["ip6address"].should == "3ffe:1111:2222::33"
          @ohai["macaddress"].should == "00:16:3E:2F:36:79"
        end

        it "informs about macaddress being set using the ipv6 setup" do
          Ohai::Log.should_receive(:warn).any_number_of_times
          Ohai::Log.should_receive(:info).with(/^macaddress set to 00:16:3E:2F:36:79 from the ipv6 setup/).once
          @ohai._require_plugin("network")
        end
      end

    end

    basic_data.keys.sort.each do |os|
      describe "the #{os}::network has already set some of the {ip,mac,ip6}address attributes" do
        before(:each) do
          @ohai = Ohai::System.new
          @ohai.stub!(:require_plugin).twice.and_return(true)
          @ohai["network"] = basic_data[os]["network"]
        end

        describe "{ip,mac}address are already set" do
          before do
            @ohai["ipaddress"] = "10.11.12.13"
            @ohai["macaddress"] = "00:AA:BB:CC:DD:EE"
            @expected_results = {
              "linux" => {
                "ip6address" => "3ffe:1111:2222::33"
              },
              "windows" => {
                "ip6address" => "fe80::698d:3e37:7950:b28c"
              }
            }
          end

          it_does_not_fail

          it "detects ip6address" do
            @ohai._require_plugin("network")
            @ohai["ip6address"].should == @expected_results[os]["ip6address"]
          end

          it "doesn't overwrite {ip,mac}address" do
            @ohai._require_plugin("network")
            @ohai["ipaddress"].should == "10.11.12.13"
            @ohai["macaddress"].should == "00:AA:BB:CC:DD:EE"
          end
        end

        describe "ip6address is already set" do
          describe "node has ipv4 and ipv6" do
            before do
              @ohai["ip6address"] = "3ffe:8888:9999::1"
              @expected_results = {
                "linux" => {
                  "ipaddress" => "192.168.66.33",
                  "macaddress" => "00:16:3E:2F:36:79"
                },
                "windows" => {
                  "ipaddress" => "172.19.0.130",
                  "macaddress" => "52:54:44:66:66:02"
                }
              }
            end

            it_does_not_fail

            it "detects {ip,mac}address" do
              @ohai._require_plugin("network")
              @ohai["ipaddress"].should == @expected_results[os]["ipaddress"]
              @ohai["macaddress"].should == @expected_results[os]["macaddress"]
            end

            it "doesn't overwrite ip6address" do
              @ohai._require_plugin("network")
              @ohai["ip6address"].should == "3ffe:8888:9999::1"
            end
          end

          describe "ipv6 only node" do
            before do
              @ohai["network"]["default_gateway"] = nil
              @ohai["network"]["default_interface"] = nil
              @ohai["network"]["interfaces"].each do |i,iv|
                iv["addresses"].delete_if{|k,kv| kv["family"] == "inet" }
              end
              @ohai["ip6address"] = "3ffe:8888:9999::1"
            end

            it_does_not_fail

            it "can't detect ipaddress (ipv4)" do
              Ohai::Log.should_receive(:warn).any_number_of_times
              @ohai._require_plugin("network")
              @ohai["ipaddress"].should be_nil
            end

            it "can't detect macaddress either" do
              Ohai::Log.should_receive(:warn).any_number_of_times
              @ohai._require_plugin("network")
              @ohai["macaddress"].should be_nil
            end

            it "warns about not being able to set {ip,mac}address" do
              Ohai::Log.should_receive(:warn).with(/^unable to detect ipaddress/).once
              Ohai::Log.should_receive(:warn).with(/^unable to detect macaddress/).once
              @ohai._require_plugin("network")
            end

            it "doesn't overwrite ip6address" do
              Ohai::Log.should_receive(:warn).any_number_of_times
              @ohai._require_plugin("network")
              @ohai["ip6address"].should == "3ffe:8888:9999::1"
            end
          end
        end

        describe "{mac,ip6}address are already set" do
          describe "valid ipv4 setup" do
            before do
              @ohai["macaddress"] = "00:AA:BB:CC:DD:EE"
              @ohai["ip6address"] = "3ffe:8888:9999::1"
              @expected_results = {
                "linux" => {
                  "ipaddress" => "192.168.66.33",
                  "macaddress" => "00:16:3E:2F:36:79"
                },
                "windows" => {
                  "ipaddress" => "172.19.0.130",
                  "macaddress" => "52:54:44:66:66:02"
                }
              }
            end

            it_does_not_fail

            it "detects ipaddress and overwrite macaddress" do
              @ohai._require_plugin("network")
              @ohai["ipaddress"].should == @expected_results[os]["ipaddress"]
              @ohai["macaddress"].should == @expected_results[os]["macaddress"]
            end

            it "doesn't overwrite ip6address" do
              @ohai._require_plugin("network")
              @ohai["ip6address"].should == "3ffe:8888:9999::1"
            end
          end

          describe "ipv6 only node" do
            before do
              @ohai["network"]["default_gateway"] = nil
              @ohai["network"]["default_interface"] = nil
              @ohai["network"]["interfaces"].each do |i,iv|
                iv["addresses"].delete_if{|k,kv| kv["family"] == "inet" }
              end
              @ohai["macaddress"] = "00:AA:BB:CC:DD:EE"
              @ohai["ip6address"] = "3ffe:8888:9999::1"
            end

            it_does_not_fail

            it "can't set ipaddress" do
              Ohai::Log.should_receive(:warn).any_number_of_times
              @ohai._require_plugin("network")
              @ohai["ipaddress"].should be_nil
            end

            it "doesn't overwrite {ip6,mac}address" do
              Ohai::Log.should_receive(:warn).any_number_of_times
              @ohai._require_plugin("network")
              @ohai["ip6address"].should == "3ffe:8888:9999::1"
              @ohai["macaddress"].should == "00:AA:BB:CC:DD:EE"
            end
          end
        end

        describe "{ip,mac,ip6}address are already set" do
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

        describe "{ip,ip6}address are already set" do
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
end
