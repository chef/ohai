#
# Author:: Kris Shannon <k.shannon@amaze.com.au>
# Copyright:: Copyright (c) 2019 Amaze Communication.
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

require "spec_helper"
require "ohai/mixin/network_helper"

describe Ohai::Mixin::NetworkHelper, "Network Helper Mixin" do
  let(:mixin) { Object.new.extend(described_class) }

  describe "hex_to_dec_netmask method" do
    it "converts a netmask from hexadecimal form to decimal form" do
      expect(mixin.hex_to_dec_netmask("ffff0000")).to eq("255.255.0.0")
    end
  end

  describe "canonicalize hostname" do
    [
      {
        desc: "canonname == initial hostname returns those",
        initial_hostname: "fullhostname.example.com",
        canonname: "fullhostname.example.com",
        final_hostname: "fullhostname.example.com",
      },
      {
        desc: "canonname(hostname) => fqdn returns fqdn",
        initial_hostname: "hostnamepart",
        canonname: "hostnamepart.example.com",
        final_hostname: "hostnamepart.example.com",
      },
      {
        desc: "hostname only canonname, getnameinfo is tried and succeeds",
        initial_hostname: "hostnamepart2",
        canonname: "hostnamepart2",
        nameinfo: "hostnamepart2.example.com",
        final_hostname: "hostnamepart2.example.com",
      },
      {
        desc: "hostname only canonname, getnameinfo returns ip => original hostname",
        initial_hostname: "hostnameip.example.com",
        canonname: "hostnameip", # totally contrived
        nameinfo: "192.168.1.1",
        final_hostname: "hostnameip.example.com",
      }
    ].each do |example_hash|
      # this is a brittle set of tests deliberately intended to discourage modifying
      # this API (see the note in the code on the necessity of manual testing)
      example example_hash[:desc] do
        addrinfo = instance_double(Addrinfo)
        expect(Addrinfo).to receive(:getaddrinfo)
          .with(example_hash[:initial_hostname], nil, nil, nil, nil, Socket::AI_CANONNAME)
          .and_return([addrinfo])
        expect(addrinfo).to receive(:canonname).and_return(example_hash[:canonname])

        # only expect this call if :nameinfo key is set, otherwise code should not
        # fall through to getnameinfo
        if example_hash[:nameinfo]
          expect(addrinfo).to receive(:getnameinfo).and_return([example_hash[:nameinfo], "0"])
        end

        # the actual input and output for #canonicalize_hostname method
        expect(mixin.canonicalize_hostname(example_hash[:initial_hostname]))
          .to eql(example_hash[:final_hostname])
      end
    end
  end
end
