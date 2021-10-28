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
    # this is a brittle test deliberately intended to discourage modifying this API
    # (see the node in the code on the necessity of manual testing)
    it "uses the correct ruby API" do
      hostname = "broken.example.org"
      addrinfo = instance_double(Addrinfo)
      expect(Addrinfo).to receive(:getaddrinfo).with(hostname, nil, nil, nil, nil, Socket::AI_CANONNAME).and_return([addrinfo])
      expect(addrinfo).to receive(:canonname).and_return(hostname)
      expect(mixin.canonicalize_hostname(hostname)).to eql(hostname)
    end
  end
end
