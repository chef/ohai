#
# Author:: Stafford Brunk (<stafford.brunk@gmail.com>)
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "ipaddress"
require_relative "../../spec_helper.rb"
require "ohai/util/ip_helper"

class IpHelperMock
  include Ohai::Util::IpHelper
end

describe "Ohai::Util::IpHelper" do
  let(:ip_helper) { IpHelperMock.new }

  shared_examples "ip address types" do
    context "with an IPv4 address" do
      context "that is private" do
        let(:address) { "10.128.142.89" }

        it "identifies the address as private" do
          expect(ip_helper.private_address?(address)).to be_truthy
        end
      end

      context "that is public" do
        let(:address) { "74.125.224.72" }

        it "identifies the address as public" do
          expect(ip_helper.private_address?(address)).to be_falsey
        end
      end
    end

    context "with an IPv6 address" do
      context "that is an RFC 4193 unique local address" do
        let(:address) { "fdf8:f53b:82e4::53" }

        it "identifies the address as a unique local address" do
          expect(ip_helper.private_address?(address)).to be_truthy
        end
      end

      context "that is a RFC 4291 Link-Local unicast address" do
        let(:address) { "FE80::0202:B3FF:FE1E:8329" }

        it "does identify the address as a link-local address" do
          expect(ip_helper.private_address?(address)).to be_truthy
        end
      end
    end
  end

  describe "private_address?" do
    include_examples "ip address types"
  end

  describe "unique_local_address?" do
    include_examples "ip address types"
  end

  describe "public_address?" do
    let(:address) { "10.128.142.89" }

    before do
      allow(ip_helper).to receive(:private_address?)
    end

    it "should call #private_address?" do
      expect(ip_helper).to receive(:private_address?)
      ip_helper.public_address?(address)
    end

    it "should return the inverse of #private_address?" do
      expect(ip_helper.public_address?(address)).to equal !ip_helper.private_address?(address)
    end
  end

  describe "loopback?" do
    context "with an IPv4 address" do
      context "that is a loopback address" do
        let(:address) { "127.0.0.1" }

        it "should identify the address as a loopback address" do
          expect(ip_helper.loopback?(address)).to be_truthy
        end
      end

      context "that is not a loopback address" do
        let(:address) { "1.2.3.4" }

        it "should not identify the address as a loopback address" do
          expect(ip_helper.loopback?(address)).to be_falsey
        end
      end
    end

    context "with an IPv6 address" do
      context "that is a loopback address" do
        let(:address) { "0:0:0:0:0:0:0:1" }

        it "should identify the address as a loopback address" do
          expect(ip_helper.loopback?(address)).to be_truthy
        end
      end

      context "that is not a loopback address" do
        let(:address) { "2400:6180:0000:00D0:0000:0000:0009:7001" }

        it "should not identify the address as a loopback address" do
          expect(ip_helper.loopback?(address)).to be_falsey
        end
      end
    end
  end
end
