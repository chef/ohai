#
# Author:: Matt Wrock (<matt@mattwrock.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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
require "openssl"

describe Ohai::System, "plugin fips" do
  subject do
    plugin.run
    plugin["fips"]["kernel"]["enabled"]
  end

  let(:plugin) { get_plugin("fips") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  context "when OpenSSL reports FIPS mode true" do
    it "sets fips enabled true" do
      stub_const("OpenSSL::OPENSSL_FIPS", true)
      expect(subject).to be(true)
    end
  end

  context "when OpenSSL reports FIPS mode false" do
    it "sets fips enabled false" do
      stub_const("OpenSSL::OPENSSL_FIPS", false)
      expect(subject).to be(false)
    end
  end
end
