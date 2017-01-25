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

require_relative "../../spec_helper.rb"

def it_doesnt_fail
  it "doesnt fail" do
    allow(Ohai::Log).to receive(:warn)
    expect(Ohai::Log).not_to receive(:debug).with(/^Plugin network threw exception/)
    @plugin.run
  end
end

# basic sanity check that is called in all describes below
def it_populates_ipaddress_attributes
  source = caller[0]

  it "populates ipaddress, macaddress and ip6address" do
    begin
      allow(Ohai::Log).to receive(:warn)
      expect(Ohai::Log).not_to receive(:debug).with(/^Plugin network threw exception/)
      @plugin.run
      %w{ ipaddress macaddress ip6address }.each do |attribute|
        expect(@plugin).to have_key(attribute)
      end
    rescue Exception
      puts "RSpec context: #{source}"
      raise
    end
  end
end

describe Ohai::System, "Network Plugin" do

  # output of network plugins on particular platforms to mock plugin runs
  basic_data = {
    "freebsd" => {
      "network" => {
        "interfaces" => {
          "vr0" => {
            "type" => "vr",
            "number" => "0",
            "flags" => %w{UP BROADCAST RUNNING SIMPLEX MULTICAST},
            "addresses" => {
              "00:00:24:c9:5e:b8" => {
                "family" => "lladdr",
              },
              "fe80::200:24ff:fec9:5eb8" => {
                "family" => "inet6",
                "zoneid" => "vr0",
                "prefixlen" => "64",
                "scopeid" => "0x1",
              },
              "76.91.1.255" => {
                "family" => "inet",
                "netmask" => "255.255.252.0",
                "broadcast" => "255.255.255.255",
              },
            },
            "arp" => {
              "76.91.1.255" => "00:00:24:c9:5e:b8",
              "76.91.0.1" => "00:01:5c:24:8c:01",
            },
          },
          "vr1" => {
            "type" => "vr",
            "number" => "1",
            "flags" => %w{UP BROADCAST RUNNING PROMISC SIMPLEX MULTICAST},
            "addresses" => {
              "00:00:24:c9:5e:b9" => {
                "family" => "lladdr",
              },
              "fe80::200:24ff:fec9:5eb9" => {
                "family" => "inet6",
                "zoneid" => "vr1",
                "prefixlen" => "64",
                "scopeid" => "0x2",
              },
            },
          },
          "vr2" => {
            "type" => "vr",
            "number" => "2",
            "flags" => %w{UP BROADCAST RUNNING PROMISC SIMPLEX MULTICAST},
            "addresses" => {
              "00:00:24:c9:5e:ba" => {
                "family" => "lladdr",
              },
              "fe80::200:24ff:fec9:5eba" => {
                "family" => "inet6",
                "zoneid" => "vr2",
                "prefixlen" => "64",
                "scopeid" => "0x3",
              },
            },
          },
          "vr3" => {
            "type" => "vr",
            "number" => "3",
            "flags" => %w{UP BROADCAST RUNNING PROMISC SIMPLEX MULTICAST},
            "addresses" => {
              "00:00:24:c9:5e:bb" => {
                "family" => "lladdr",
              },
              "fe80::200:24ff:fec9:5ebb" => {
                "family" => "inet6",
                "zoneid" => "vr3",
                "prefixlen" => "64",
                "scopeid" => "0x4",
              },
            },
          },
          "ipfw0" => {
            # OHAI-492: Ensure network plugin works with interfaces without addresses.
            "type" => "ipfw",
            "number" => "0",
            "flags" => %w{UP SIMPLEX MULTICAST},
          },
          "lo0" => {
            "type" => "lo",
            "number" => "0",
            "flags" => %w{UP LOOPBACK RUNNING MULTICAST},
            "addresses" => {
              "127.0.0.1" => {
                "family" => "inet",
                "netmask" => "255.0.0.0",
              },
              "::1" => {
                "family" => "inet6",
                "prefixlen" => "128",
              },
              "fe80::1" => {
                "family" => "inet6",
                "zoneid" => "lo0",
                "prefixlen" => "64",
                "scopeid" => "0x8",
              },
            },
          },
          "bridge0" => {
            "type" => "bridge",
            "number" => "0",
            "flags" => %w{LEARNING DISCOVER AUTOEDGE AUTOPTP},
            "addresses" => {
              "02:20:6f:d2:c4:00" => {
                "family" => "lladdr",
              },
              "192.168.2.1" => {
                "family" => "inet",
                "netmask" => "255.255.255.0",
                "broadcast" => "192.168.2.255",
              },
              "2001:470:d:cb4::1" => {
                "family" => "inet6",
                "prefixlen" => "64",
              },
              "fe80::cafe:babe:dead:beef" => {
                "family" => "inet6",
                "zoneid" => "bridge0",
                "prefixlen" => "64",
                "scopeid" => "0x9",
              },
            },
            "arp" => {
              "192.168.2.142" => "60:67:20:75:a2:0c",
              "192.168.2.205" => "c0:c1:c0:f9:40:ed",
              "192.168.2.160" => "cc:3a:61:cf:67:13",
              "192.168.2.1" => "02:20:6f:d2:c4:00",
              "192.168.2.135" => "f8:0c:f3:d7:c6:b6",
              "192.168.2.165" => "f8:8f:ca:24:49:ad",
              "192.168.2.158" => "48:5d:60:1f:ea:d1",
              "192.168.2.150" => "60:a4:4c:60:b3:d9",
            },
          },
          "gif0" => {
            "type" => "gif",
            "number" => "0",
            "flags" => %w{UP POINTOPOINT RUNNING MULTICAST},
            "addresses" => {
              "fe80::200:24ff:fec9:5eb8" => {
                "family" => "inet6",
                "zoneid" => "gif0",
                "prefixlen" => "64",
                "scopeid" => "0xa",
              },
            },
          },
        },
        "default_gateway" => "76.91.0.1",
        "default_interface" => "vr0",
        "default_inet6_gateway" => "2001:470:d:cb4::2",
        "default_inet6_interface" => "bridge0",
      },
    },
    "linux" => {
      "network" => {
        # pp Hash[node['network']] from chef-shell to get the network data
        # have just removed the neighbour and route entries by hand
        "interfaces" => {
          "lo" => {
            "flags" => %w{LOOPBACK UP},
            "addresses" => {
              "::1" => {
                "scope" => "Node",
                "prefixlen" => "128",
                "family" => "inet6",
              },
              "127.0.0.1" => {
                "scope" => "Node",
                "netmask" => "255.0.0.0",
                "prefixlen" => "8",
                "family" => "inet",
              },
            },
            "mtu" => "16436",
            "encapsulation" => "Loopback",
            "state" => "unknown",
          },
          "eth0" => {
            "flags" => %w{BROADCAST MULTICAST UP},
            "number" => "0",
            "addresses" => {
              "fe80::216:3eff:fe2f:3679" => {
                "scope" => "Link",
                "prefixlen" => "64",
                "family" => "inet6",
              },
              "00:16:3E:2F:36:79" => {
                "family" => "lladdr",
              },
              "192.168.66.33" => {
                "scope" => "Global",
                "netmask" => "255.255.255.0",
                "broadcast" => "192.168.66.255",
                "prefixlen" => "24",
                "family" => "inet",
              },
              "3ffe:1111:2222::33" => {
                "prefixlen" => "48",
                "family" => "inet6",
                "scope" => "Global",
                "state" => "up",
              },
            },
            "mtu" => "1500",
            "type" => "eth",
            "encapsulation" => "Ethernet",
          },
          "eth1" => {
            "flags" => %w{BROADCAST MULTICAST UP},
            "number" => "1",
            "addresses" => {
              "fe80::216:3eff:fe2f:3680" => {
                "scope" => "Link",
                "prefixlen" => "64",
                "family" => "inet6",
              },
              "00:16:3E:2F:36:80" => {
                "family" => "lladdr",
              },
              "192.168.99.11" => {
                "scope" => "Global",
                "netmask" => "255.255.255.0",
                "broadcast" => "192.168.99.255",
                "prefixlen" => "24",
                "family" => "inet",
              },
              "3ffe:1111:3333::1" => {
                "prefixlen" => "48",
                "family" => "inet6",
                "scope" => "Global",
              },
            },
            "mtu" => "1500",
            "type" => "eth",
            "encapsulation" => "Ethernet",
          },
        },
        "default_gateway" => "192.168.66.15",
        "default_interface" => "eth0",
        "default_inet6_gateway" => "3ffe:1111:2222::",
        "default_inet6_interface" => "eth0",
      },
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
                "family" => "inet",
              },
              "fe80::698d:3e37:7950:b28c" => {
                "prefixlen" => "64",
                "family" => "inet6",
                "scope" => "Link",
              },
              "52:54:44:66:66:02" => {
                "family" => "lladdr",
              },
            },
            "mtu" => nil,
            "type" => "Ethernet 802.3",
            "encapsulation" => "Ethernet",
          },
        },
        "default_gateway" => "172.19.0.1",
        "default_interface" => "0xb",
      },
    },
  }

  describe "on linux" do
    before(:each) do
      @plugin = get_plugin("network")
      @plugin["network"] = basic_data["linux"]["network"]
    end

    describe "when the linux::network plugin hasn't set any of {ip,ip6,mac}address attributes" do
      describe "simple network setup" do
        it_populates_ipaddress_attributes

        it "detects {ip,ip6,mac}address" do
          @plugin.run
          expect(@plugin["ipaddress"]).to eq("192.168.66.33")
          expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:79")
          expect(@plugin["ip6address"]).to eq("3ffe:1111:2222::33")
        end
      end

      describe "default ipv4 and ipv6 gateway on different interfaces" do
        describe "both interfaces have an ARP" do
          before do
            @plugin["network"]["default_inet6_gateway"] = "3ffe:1111:3333::"
            @plugin["network"]["default_inet6_interface"] = "eth1"
          end

          it_populates_ipaddress_attributes

          it "detects {ip,ip6}address" do
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("192.168.66.33")
            expect(@plugin["ip6address"]).to eq("3ffe:1111:3333::1")
          end

          it "set macaddress from the ipv4 setup" do
            @plugin.run
            expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:79")
          end

          it "informs about this setup" do
            expect(Ohai::Log).to receive(:debug).with(/ipaddress and ip6address are set from different interfaces/)
            allow(Ohai::Log).to receive(:debug)
            @plugin.run
          end
        end

        describe "ipv4 interface has no ARP" do
          before do
            @plugin["network"]["interfaces"]["eth0"]["addresses"].delete_if { |k, kv| kv["family"] == "lladdr" }
            # not really checked by this pluging
            @plugin["network"]["interfaces"]["eth0"]["flags"] << "NOARP"
            @plugin["network"]["default_inet6_gateway"] = "3ffe:1111:3333::"
            @plugin["network"]["default_inet6_interface"] = "eth1"
          end

          it_populates_ipaddress_attributes

          it "detects {ip,ip6}address" do
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("192.168.66.33")
            expect(@plugin["ip6address"]).to eq("3ffe:1111:3333::1")
          end

          it "sets macaddress to the ipv6 interface because it hadn't set one for ipv4 first" do
            @plugin.run
            expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:80")
          end

          it "informs about this setup" do
            expect(Ohai::Log).to receive(:debug).with(/ipaddress and ip6address are set from different interfaces/)
            allow(Ohai::Log).to receive(:debug)
            @plugin.run
          end
        end
      end

      describe "conflicting results from the linux::network plugin" do
        describe "default interface doesn't match the default_gateway" do
          before do
            @plugin["network"]["default_interface"] = "eth1"
            @plugin["network"]["default_inet6_interface"] = "eth1"
          end

          it_populates_ipaddress_attributes

          it "picks {ip,ip6,mac}address" do
            allow(Ohai::Log).to receive(:warn)
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("192.168.99.11")
            expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:80")
            expect(@plugin["ip6address"]).to eq("3ffe:1111:3333::1")
          end

          it "warns about this conflict" do
            expect(Ohai::Log).to receive(:debug).with(/\[inet\] no ipaddress\/mask on eth1/).once
            expect(Ohai::Log).to receive(:debug).with(/\[inet6\] no ipaddress\/mask on eth1/).once
            allow(Ohai::Log).to receive(:debug)
            @plugin.run
          end
        end

        describe "there's a default gateway, none of the configured ip/mask theorically allows to reach it" do
          before do
            @plugin["network"]["default_gateway"] = "172.16.12.42"
            @plugin["network"]["default_inet6_gateway"] = "3ffe:12:42::7070"
          end

          it "picks {ip,ip6,mac}address" do
            allow(Ohai::Log).to receive(:warn)
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("192.168.66.33")
            expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:79")
            expect(@plugin["ip6address"]).to eq("3ffe:1111:2222::33")
          end

        end

        describe "no ip address for the given default interface/gateway" do
          before do
            @plugin["network"]["interfaces"]["eth0"]["addresses"].delete_if { |k, v| %w{inet inet6}.include? v["family"] }
          end

          it_doesnt_fail

          it "doesn't detect {ip,ip6,mac}address" do
            allow(Ohai::Log).to receive(:warn)
            @plugin.run
            expect(@plugin["ipaddress"]).to be_nil
            expect(@plugin["macaddress"]).to be_nil
            expect(@plugin["ip6address"]).to be_nil
          end

          it "warns about this conflict" do
            expect(Ohai::Log).to receive(:warn).with(/unable to detect ipaddress/).once
            expect(Ohai::Log).to receive(:warn).with(/\[inet\] no ip address on eth0/).once
            expect(Ohai::Log).to receive(:debug).with(/unable to detect ip6address/).once
            expect(Ohai::Log).to receive(:debug).with(/unable to detect macaddress/).twice # for each family
            expect(Ohai::Log).to receive(:warn).with(/\[inet6\] no ip address on eth0/).once
            @plugin.run
          end
        end

        describe "no ip at all" do
          before do
            @plugin["network"]["default_gateway"] = nil
            @plugin["network"]["default_interface"] = nil
            @plugin["network"]["default_inet6_gateway"] = nil
            @plugin["network"]["default_inet6_interface"] = nil
            @plugin["network"]["interfaces"].each do |i, iv|
              iv["addresses"].delete_if { |k, kv| %w{inet inet6}.include? kv["family"] }
            end
          end

          it_doesnt_fail

          it "doesn't detect {ip,ip6,mac}address" do
            allow(Ohai::Log).to receive(:warn)
            @plugin.run
            expect(@plugin["ipaddress"]).to be_nil
            expect(@plugin["macaddress"]).to be_nil
            expect(@plugin["ip6address"]).to be_nil
          end

          it "should warn about it" do
            expect(Ohai::Log).to receive(:warn).with(/unable to detect ipaddress/).once
            expect(Ohai::Log).to receive(:debug).with(/unable to detect macaddress/).twice # for each family
            expect(Ohai::Log).to receive(:debug).with(/unable to detect ip6address/).once
            @plugin.run
          end
        end
      end

      describe "several ipaddresses matching the default route" do
        describe "bigger prefix not set on the default interface" do
          before do
            @plugin["network"]["interfaces"]["eth2"] = {
              "flags" => %w{BROADCAST MULTICAST UP},
              "number" => "2",
              "addresses" => {
                "fe80::216:3eff:fe2f:3681" => {
                  "scope" => "Link",
                  "prefixlen" => "64",
                  "family" => "inet6",
                },
                "00:16:3E:2F:36:81" => { "family" => "lladdr" },
                "192.168.66.99" => {
                  "scope" => "Global",
                  "netmask" => "255.255.255.128",
                  "broadcast" => "192.168.99.127",
                  "prefixlen" => "25",
                  "family" => "inet",
                },
                "3ffe:1111:2222:0:4444::1" => {
                  "prefixlen" => "64",
                  "family" => "inet6",
                  "scope" => "Global",
                },
              },
            }
          end

          it_populates_ipaddress_attributes

          it "sets {ip,ip6,mac}address correctly" do
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("192.168.66.33")
            expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:79")
            expect(@plugin["ip6address"]).to eq("3ffe:1111:2222::33")
          end
        end

        describe "bigger prefix set on the default interface" do
          before do
            @plugin["network"]["interfaces"]["eth0"]["addresses"]["192.168.66.99"] = {
              "scope" => "Global",
              "netmask" => "255.255.255.128",
              "broadcast" => "192.168.66.127",
              "prefixlen" => "25",
              "family" => "inet",
            }
            @plugin["network"]["interfaces"]["eth0"]["addresses"]["3ffe:1111:2222:0:4444::1"] = {
              "prefixlen" => "64",
              "family" => "inet6",
              "scope" => "Global",
            }
          end

          it_populates_ipaddress_attributes

          it "sets {ip,ip6,mac}address correctly" do
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("192.168.66.99")
            expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:79")
            expect(@plugin["ip6address"]).to eq("3ffe:1111:2222:0:4444::1")
          end
        end

        describe "smallest ip not set on the default_interface" do
          before do
            @plugin["network"]["interfaces"]["eth2"] = {
              "flags" => %w{BROADCAST MULTICAST UP},
              "number" => "2",
              "addresses" => {
                "fe80::216:3eff:fe2f:3681" => {
                  "scope" => "Link",
                  "prefixlen" => "64",
                  "family" => "inet6",
                },
                "00:16:3E:2F:36:81" => { "family" => "lladdr" },
                "192.168.66.32" => {
                  "scope" => "Global",
                  "netmask" => "255.255.255.0",
                  "broadcast" => "192.168.66.255",
                  "prefixlen" => "24",
                  "family" => "inet",
                },
                "3ffe:1111:2222::32" => {
                  "prefixlen" => "48",
                  "family" => "inet6",
                  "scope" => "Global",
                },
              },
            }
          end

          it_populates_ipaddress_attributes

          it "sets {ip,ip6,mac}address correctly" do
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("192.168.66.33")
            expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:79")
            expect(@plugin["ip6address"]).to eq("3ffe:1111:2222::33")
          end
        end

        describe "smallest ip set on the default_interface" do
          before do
            @plugin["network"]["interfaces"]["eth0"]["addresses"]["192.168.66.32"] = {
              "scope" => "Global",
              "netmask" => "255.255.255.0",
              "broadcast" => "192.168.66.255",
              "prefixlen" => "24",
              "family" => "inet",
            }
            @plugin["network"]["interfaces"]["eth0"]["addresses"]["3ffe:1111:2222::32"] = {
              "prefixlen" => "48",
              "family" => "inet6",
              "scope" => "Global",
            }
          end

          it_populates_ipaddress_attributes

          it "sets {ip,ip6,mac}address correctly" do
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("192.168.66.32")
            expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:79")
            expect(@plugin["ip6address"]).to eq("3ffe:1111:2222::32")
          end
        end
      end

      describe "no default route" do
        describe "first interface is not the best choice" do
          before do
            @plugin["network"]["default_gateway"] = nil
            @plugin["network"]["default_interface"] = nil
            @plugin["network"]["default_inet6_gateway"] = nil
            @plugin["network"]["default_inet6_interface"] = nil
            # removing inet* addresses from eth0, to complicate things a bit
            @plugin["network"]["interfaces"]["eth0"]["addresses"].delete_if { |k, v| %w{inet inet6}.include? v["family"] }
          end

          it_populates_ipaddress_attributes

          it "picks {ip,mac,ip6}address from the first interface" do
            expect(Ohai::Log).to receive(:debug).with(/\[inet\] no default interface/).once
            expect(Ohai::Log).to receive(:debug).with(/\[inet6\] no default interface/).once
            allow(Ohai::Log).to receive(:debug)
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("192.168.99.11")
            expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:80")
            expect(@plugin["ip6address"]).to eq("3ffe:1111:3333::1")
          end
        end

        describe "can choose from addresses with different scopes" do
          before do
            @plugin["network"]["default_gateway"] = nil
            @plugin["network"]["default_interface"] = nil
            @plugin["network"]["default_inet6_gateway"] = nil
            @plugin["network"]["default_inet6_interface"] = nil
            # just changing scopes to lInK for eth0 addresses
            @plugin["network"]["interfaces"]["eth0"]["addresses"].each { |k, v| v[:scope] = "lInK" if %w{inet inet6}.include? v["family"] }
          end

          it_populates_ipaddress_attributes

          it "prefers global scope addressses to set {ip,mac,ip6}address" do
            expect(Ohai::Log).to receive(:debug).with(/\[inet\] no default interface/).once
            expect(Ohai::Log).to receive(:debug).with(/\[inet6\] no default interface/).once
            allow(Ohai::Log).to receive(:debug)
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("192.168.99.11")
            expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:80")
            expect(@plugin["ip6address"]).to eq("3ffe:1111:3333::1")
          end
        end
      end

      describe "link level default route" do
        describe "simple setup" do
          before do
            @plugin["network"]["default_gateway"] = "0.0.0.0"
            @plugin["network"]["default_interface"] = "eth1"
            @plugin["network"]["default_inet6_gateway"] = "::"
            @plugin["network"]["default_inet6_interface"] = "eth1"
          end

          it_populates_ipaddress_attributes

          it "picks {ip,mac,ip6}address from the default interface" do
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("192.168.99.11")
            expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:80")
            expect(@plugin["ip6address"]).to eq("3ffe:1111:3333::1")
          end
        end

        describe "fe80::1 as a default gateway" do
          before do
            @plugin["network"]["default_inet6_gateway"] = "fe80::1"
          end

          it_populates_ipaddress_attributes

          it "picks {ip,mac,ip6}address from the default interface" do
            @plugin.run
            expect(@plugin["ip6address"]).to eq("3ffe:1111:2222::33")
          end
        end

        describe "can choose from addresses with different scopes" do
          before do
            @plugin["network"]["default_gateway"] = "0.0.0.0"
            @plugin["network"]["default_interface"] = "eth1"
            @plugin["network"]["default_inet6_gateway"] = "::"
            @plugin["network"]["default_inet6_interface"] = "eth1"
            @plugin["network"]["interfaces"]["eth1"]["addresses"]["127.0.0.2"] = {
              "scope" => "host",
              "netmask" => "255.255.255.255",
              "prefixlen" => "32",
              "family" => "inet",
            }
          end

          it_populates_ipaddress_attributes

          it "picks {ip,mac,ip6}address from the default interface" do
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("192.168.99.11")
            expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:80")
            expect(@plugin["ip6address"]).to eq("3ffe:1111:3333::1")
          end
        end
      end

      describe "point to point address" do
        before do
          @plugin["network"]["interfaces"]["eth2"] = {
            "flags" => %w{POINTOPOINT BROADCAST MULTICAST UP},
            "number" => "2",
            "addresses" => {
              "fe80::216:3eff:fe2f:3681" => {
                "scope" => "Link",
                "prefixlen" => "64",
                "family" => "inet6",
              },
              "00:16:3E:2F:36:81" => { "family" => "lladdr" },
              "192.168.66.99" => {
                "scope" => "Global",
                "netmask" => "255.255.255.255",
                "peer" => "192.168.99.126",
                "prefixlen" => "32",
                "family" => "inet",
              },
              "3ffe:1111:2222:0:4444::1" => {
                "prefixlen" => "128",
                "peer" => "3ffe:1111:2222:0:4444::2",
                "family" => "inet6",
                "scope" => "Global",
              },
            },
          }
          @plugin["network"]["default_gateway"] = "192.168.99.126"
          @plugin["network"]["default_interface"] = "eth2"
          @plugin["network"]["default_inet6_gateway"] = "3ffe:1111:2222:0:4444::2"
          @plugin["network"]["default_inet6_interface"] = "eth2"
        end

        it_populates_ipaddress_attributes

        it "picks {ip,mac,ip6}address from the default interface" do
          @plugin.run
          expect(@plugin["ipaddress"]).to eq("192.168.66.99")
          expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:81")
          expect(@plugin["ip6address"]).to eq("3ffe:1111:2222:0:4444::1")
        end
      end

      describe "ipv6 only node" do
        before do
          @plugin["network"]["default_gateway"] = nil
          @plugin["network"]["default_interface"] = nil
          @plugin["network"]["interfaces"].each do |i, iv|
            iv["addresses"].delete_if { |k, kv| kv["family"] == "inet" }
          end
        end

        it_doesnt_fail

        it "can't detect ipaddress" do
          allow(Ohai::Log).to receive(:warn)
          @plugin.run
          expect(@plugin["ipaddress"]).to be_nil
        end

        it "warns about not being able to set {ip,mac}address (ipv4)" do
          expect(Ohai::Log).to receive(:warn).with(/unable to detect ipaddress/).once
          expect(Ohai::Log).to receive(:debug).with(/unable to detect macaddress/) # for ipv4
          expect(Ohai::Log).to receive(:debug).with(/setting macaddress to/) # for ipv6
          expect(Ohai::Log).to receive(:debug).with(/\[inet6\] Using default interface eth0 and default gateway/) # for ipv6
          @plugin.run
        end

        it "sets {ip6,mac}address" do
          allow(Ohai::Log).to receive(:warn)
          @plugin.run
          expect(@plugin["ip6address"]).to eq("3ffe:1111:2222::33")
          expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:79")
        end

        it "informs about macaddress being set using the ipv6 setup" do
          expect(Ohai::Log).to receive(:debug).with(/setting macaddress to '00:16:3E:2F:36:79'/)
          allow(Ohai::Log).to receive(:debug)
          @plugin.run
        end
      end

      describe "ipv6 only with ipv4 loopback" do
        before do
          @plugin["network"]["default_gateway"] = nil
          @plugin["network"]["default_interface"] = nil
          @plugin["network"]["interfaces"].each do |i, iv|
            next if i == "lo"
            iv["addresses"].delete_if { |k, kv| kv["family"] == "inet" }
          end
        end

        it_doesnt_fail

        it "can't detect ipaddress" do
          allow(Ohai::Log).to receive(:warn)
          @plugin.run
          expect(@plugin["ipaddress"]).to eq("127.0.0.1")
        end

        it "sets {ip6,mac}address" do
          allow(Ohai::Log).to receive(:warn)
          @plugin.run
          expect(@plugin["ip6address"]).to eq("3ffe:1111:2222::33")
          expect(@plugin["macaddress"]).to eq("00:16:3E:2F:36:79")
        end

        it "informs about macaddress being set using the ipv6 setup" do
          expect(Ohai::Log).to receive(:debug).with(/setting macaddress to '00:16:3E:2F:36:79'/)
          allow(Ohai::Log).to receive(:debug)
          @plugin.run
        end
      end
    end

    # specs using network plugin data for each mocked OS (freebsd,linux,windows)
    basic_data.keys.sort.each do |os|
      describe "the #{os}::network has already set some of the {ip,mac,ip6}address attributes" do
        before(:each) do
          @plugin["network"] = basic_data[os]["network"]
        end

        describe "{ip,mac}address are already set" do
          before do
            @plugin["ipaddress"] = "10.11.12.13"
            @plugin["macaddress"] = "00:AA:BB:CC:DD:EE"
            @expected_results = {
              "freebsd" => {
                "ip6address" => "2001:470:d:cb4::1",
                "macaddress" => "02:20:6f:d2:c4:00",
              },
              "linux" => {
                "ip6address" => "3ffe:1111:2222::33",
                "macaddress" => "00:16:3E:2F:36:79",
              },
              "windows" => {
                "ip6address" => "fe80::698d:3e37:7950:b28c",
                "macaddress" => "00:AA:BB:CC:DD:EE",
              },
            }
          end

          it_populates_ipaddress_attributes

          it "detects ip6address" do
            @plugin.run
            expect(@plugin["ip6address"]).to eq(@expected_results[os]["ip6address"])
          end

          it "doesn't overwrite {ip,mac}address" do
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("10.11.12.13")
            expect(@plugin["macaddress"]).to eq("00:AA:BB:CC:DD:EE")
          end
        end

        describe "ip6address is already set" do
          describe "node has ipv4 and ipv6" do
            before do
              @plugin["ip6address"] = "3ffe:8888:9999::1"
              @expected_results = {
                "freebsd" => {
                  "ipaddress" => "76.91.1.255",
                  "macaddress" => "00:00:24:c9:5e:b8",
                },
                "linux" => {
                  "ipaddress" => "192.168.66.33",
                  "macaddress" => "00:16:3E:2F:36:79",
                },
                "windows" => {
                  "ipaddress" => "172.19.0.130",
                  "macaddress" => "52:54:44:66:66:02",
                },
              }
            end

            it_populates_ipaddress_attributes

            it "detects {ip,mac}address" do
              @plugin.run
              expect(@plugin["ipaddress"]).to eq(@expected_results[os]["ipaddress"])
              expect(@plugin["macaddress"]).to eq(@expected_results[os]["macaddress"])
            end

            it "doesn't overwrite ip6address" do
              @plugin.run
              expect(@plugin["ip6address"]).to eq("3ffe:8888:9999::1")
            end
          end

          describe "ipv6 only node" do
            before do
              @plugin["network"]["default_gateway"] = nil
              @plugin["network"]["default_interface"] = nil
              @plugin["network"]["interfaces"].each do |i, iv|
                if iv.has_key? "addresses"
                  iv["addresses"].delete_if { |k, kv| kv["family"] == "inet" }
                end
              end
              @plugin["ip6address"] = "3ffe:8888:9999::1"
              @expected_results = {
                "freebsd" => {
                  "macaddress" => "02:20:6f:d2:c4:00",
                },
                "linux" => {
                  "macaddress" => "00:16:3E:2F:36:79",
                },
                "windows" => {
                  "macaddress" => "52:54:44:66:66:02",
                },
              }
            end

            it_doesnt_fail

            it "can't detect ipaddress (ipv4)" do
              allow(Ohai::Log).to receive(:warn)
              @plugin.run
              expect(@plugin["ipaddress"]).to be_nil
            end

            it "takes the macaddress from ipv6" do
              allow(Ohai::Log).to receive(:warn)
              @plugin.run
              expect(@plugin["macaddress"]).to eq(@expected_results[os]["macaddress"])
            end

            it "warns about not being able to set ipaddress" do
              expect(Ohai::Log).to receive(:warn).with(/unable to detect ipaddress/).once
              @plugin.run
            end

            it "doesn't overwrite ip6address" do
              allow(Ohai::Log).to receive(:warn)
              @plugin.run
              expect(@plugin["ip6address"]).to eq("3ffe:8888:9999::1")
            end
          end
        end

        describe "{mac,ip6}address are already set" do
          describe "valid ipv4 setup" do
            before do
              @plugin["macaddress"] = "00:AA:BB:CC:DD:EE"
              @plugin["ip6address"] = "3ffe:8888:9999::1"
              @expected_results = {
                "freebsd" => {
                  "ipaddress" => "76.91.1.255",
                  "macaddress" => "00:00:24:c9:5e:b8",
                },
                "linux" => {
                  "ipaddress" => "192.168.66.33",
                  "macaddress" => "00:16:3E:2F:36:79",
                },
                "windows" => {
                  "ipaddress" => "172.19.0.130",
                  "macaddress" => "52:54:44:66:66:02",
                },
              }
            end

            it_populates_ipaddress_attributes

            it "detects ipaddress and does not overwrite macaddress" do
              @plugin.run
              expect(@plugin["ipaddress"]).to eq(@expected_results[os]["ipaddress"])
              expect(@plugin["macaddress"]).to eq(@plugin["macaddress"])
            end

            it "doesn't overwrite ip6address" do
              @plugin.run
              expect(@plugin["ip6address"]).to eq("3ffe:8888:9999::1")
            end
          end

          describe "ipv6 only node" do
            before do
              @plugin["network"]["default_gateway"] = nil
              @plugin["network"]["default_interface"] = nil
              @plugin["network"]["interfaces"].each do |i, iv|
                if iv.has_key? "addresses"
                  iv["addresses"].delete_if { |k, kv| kv["family"] == "inet" }
                end
              end
              @plugin["macaddress"] = "00:AA:BB:CC:DD:EE"
              @plugin["ip6address"] = "3ffe:8888:9999::1"
            end

            it_doesnt_fail

            it "can't set ipaddress" do
              allow(Ohai::Log).to receive(:warn)
              @plugin.run
              expect(@plugin["ipaddress"]).to be_nil
            end

            it "doesn't overwrite {ip6,mac}address" do
              allow(Ohai::Log).to receive(:warn)
              @plugin.run
              expect(@plugin["ip6address"]).to eq("3ffe:8888:9999::1")
              expect(@plugin["macaddress"]).to eq("00:AA:BB:CC:DD:EE")
            end
          end
        end

        describe "{ip,mac,ip6}address are already set" do
          before do
            @plugin["ipaddress"] = "10.11.12.13"
            @plugin["macaddress"] = "00:AA:BB:CC:DD:EE"
            @plugin["ip6address"] = "3ffe:8888:9999::1"
          end

          it_populates_ipaddress_attributes

          it "doesn't overwrite {ip,mac,ip6}address" do
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("10.11.12.13")
            expect(@plugin["macaddress"]).to eq("00:AA:BB:CC:DD:EE")
            expect(@plugin["ip6address"]).to eq("3ffe:8888:9999::1")
          end
        end

        describe "{ip,ip6}address are already set" do
          before do
            @plugin["ipaddress"] = "10.11.12.13"
            @plugin["ip6address"] = "3ffe:8888:9999::1"
          end

          it_doesnt_fail

          it "doesn't overwrite {ip,ip6}address" do
            @plugin.run
            expect(@plugin["ipaddress"]).to eq("10.11.12.13")
            expect(@plugin["ip6address"]).to eq("3ffe:8888:9999::1")
          end
        end

      end
    end
  end
end
