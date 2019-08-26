#
# Author:: Matt Wrock (<matt@mattwrock.com>)
# Copyright:: Copyright (c) 2016-2018 Chef Software, Inc.
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

  let(:enabled) { "0" }
  let(:plugin) { get_plugin("linux/fips") }
  let(:openssl_test_mode) { false }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  around do |ex|

    $FIPS_TEST_MODE = openssl_test_mode
    ex.run
  ensure
    $FIPS_TEST_MODE = false

  end

  context "with OpenSSL.fips_mode == false" do
    before { allow(OpenSSL).to receive(:fips_mode).and_return(false) }

    it "does not set fips plugin" do
      expect(subject).to be(false)
    end
  end

  context "with OpenSSL.fips_mode == true" do
    before { allow(OpenSSL).to receive(:fips_mode).and_return(true) }

    it "sets fips plugin" do
      expect(subject).to be(true)
    end
  end
end
