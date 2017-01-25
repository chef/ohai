#
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

require_relative "../../spec_helper.rb"
require "ipaddr_extensions"

describe Ohai::System, "plugin ip_scopes" do
  let(:plugin) { get_plugin("ip_scopes") }
  let(:network) { Mash.new(:interfaces => interfaces) }
  let(:interfaces) do
    Hash[
      interface1, { :addresses => addresses1, :type => interface1_type },
      interface2, { :addresses => addresses2, :type => interface2_type },
      interface3, { :addresses => addresses3, :type => interface3_type }] end
  let(:interface1) { :eth0 }
  let(:interface2) { :eth1 }
  let(:interface3) { :eth2 }
  let(:addresses1) { {} }
  let(:addresses2) { {} }
  let(:addresses3) { {} }
  let(:interface1_type) { "eth" }
  let(:interface2_type) { "eth" }
  let(:interface3_type) { "eth" }

  before { plugin[:network] = network }

  if defined?(IPAddrExtensions)
    context "with ipaddr_extensions gem" do
      let(:ip1) { "10.0.0.1" }
      let(:ip2) { "1.2.3.4" }
      let(:ip3) { "fe80::8638:35ff:fe4e:dc74" }

      let(:addresses1) { Hash[ip1, {}] }
      let(:addresses2) { Hash[ip2, {}, ip3, {}] }

      it "adds ip_scope to each address's information hash" do
        plugin.run
        expect(plugin[:network][:interfaces][:eth0][:addresses]["10.0.0.1"][:ip_scope]).to eq("RFC1918 PRIVATE")
        expect(plugin[:network][:interfaces][:eth1][:addresses]["1.2.3.4"][:ip_scope]).to eq("GLOBAL UNICAST")
        expect(plugin[:network][:interfaces][:eth1][:addresses]["fe80::8638:35ff:fe4e:dc74"][:ip_scope]).to eq("LINK LOCAL UNICAST")
      end

      describe "privateaddress attribute" do
        before { plugin.run }

        context "when host has multiple RFC1918 ethernet addresses" do
          let(:ip1) { "10.0.0.1" }
          let(:ip2) { "192.168.1.1" }
          let(:interface1_type) { "eth" }
          let(:interface2_type) { "eth" }

          it "picks the last RFC1918 address" do
            expect(plugin[:privateaddress]).to eq("192.168.1.1")
          end
        end

        context "when host has virtual and ethernet RFC1918 addresses" do
          let(:ip1) { "10.0.0.1" }
          let(:ip2) { "192.168.1.1" }
          let(:interface1_type) { "eth" }
          let(:interface2_type) { "ppp" }

          it "picks the non-virtual address" do
            expect(plugin[:privateaddress]).to eq("10.0.0.1")
          end
        end

        context "when host has tunl" do
          let(:ip1) { "10.0.0.1" }
          let(:ip2) { "192.168.1.1" }
          let(:interface1_type) { "eth" }
          let(:interface2_type) { "tunl" }

          it "picks the non-virtual address" do
            expect(plugin[:privateaddress]).to eq("10.0.0.1")
          end
        end

        context "when host has docker" do
          let(:ip1) { "10.0.0.1" }
          let(:ip2) { "192.168.1.1" }
          let(:interface1_type) { "eth" }
          let(:interface2_type) { "docker" }

          it "picks the non-virtual address" do
            expect(plugin[:privateaddress]).to eq("10.0.0.1")
          end
        end

        context "when host only has virtual RFC1918 addresses" do
          let(:ip1) { "10.0.0.1" }
          let(:ip2) { "192.168.1.1" }
          let(:ip3) { "172.16.1.1" }

          let(:interface1_type) { "ppp" }
          let(:interface2_type) { "tunl" }
          let(:interface3_type) { "docker" }

          it "ignores them" do
            expect(plugin[:privateaddress]).to be nil
          end
        end
      end
    end
  end

  unless defined?(IPAddrExtensions)
    context "without the ipaddr_extensions gem" do
      let(:addresses1) { Hash["10.0.0.1", {}] }

      before do
        # standin for raising on `require 'ipaddr_extensions'`
        allow(plugin[:network][:interfaces]).to receive(:keys).and_raise(LoadError)
        plugin.run
      end

      it "does not add ip_scope to addresses" do
        expect(plugin[:network][:interfaces][:eth0][:addresses]["10.0.0.1"][:ip_scope]).to be nil
      end

      it "does not add a privateaddress attribute" do
        expect(plugin[:privateaddress]).to be nil
      end
    end
  end
end
