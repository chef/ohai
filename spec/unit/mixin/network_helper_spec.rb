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
end
