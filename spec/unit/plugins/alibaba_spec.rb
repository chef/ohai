#
# Author:: Ranjib Dey (dey.ranjib@gmail.com)
# Author:: Tim Smith (tsmith@chef.io)
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
# WITHOUT WARRANTIES OR CONDIT"Net::HTTP Response"NS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"
require "open-uri"

describe Ohai::System, "plugin alibaba" do
  let(:plugin) { get_plugin("alibaba") }

  before do
    # SMBIOS fields a test doesn't set read as absent, on every platform
    allow(plugin).to receive(:smbios_value).and_return(nil)
    allow(plugin).to receive(:hint?).with("alibaba").and_return(false)
  end

  shared_examples_for "!alibaba" do
    it "does NOT attempt to fetch the alibaba metadata" do
      expect(plugin).not_to receive(:http_get)
      plugin.run
    end

    it "does NOT set alibaba attributes" do
      expect(plugin[:alibaba]).to be_nil
      plugin.run
    end
  end

  shared_examples_for "alibaba" do
    before do
      @http_get = double("Net::HTTP client")
      allow(plugin).to receive(:http_get).with("").and_return(double("Net::HTTP Response", body: "meta-data\n", code: "200"))
      allow(plugin).to receive(:http_get).with("meta-data/").and_return(double("Net::HTTP Response", body: "hostname\n", code: "200"))
      allow(plugin).to receive(:http_get).with("meta-data/hostname").and_return(double("Net::HTTP Response", body: "foo", code: "200"))
      allow(IO).to receive(:select).and_return([[], [1], []])
      t = double("connection")
      allow(t).to receive(:connect_nonblock).and_raise(Errno::EINPROGRESS)
      allow(t).to receive(:getsockopt).and_return(double("sockopt", int: 0))
      allow(t).to receive(:close)
      allow(Socket).to receive(:new).and_return(t)
      allow(Socket).to receive(:pack_sockaddr_in).and_return(Socket.pack_sockaddr_in(80, "127.0.0.1"))
    end

    it "recursively fetches and properly parses json metadata" do
      plugin.run

      expect(plugin[:alibaba]).not_to be_nil
      expect(plugin[:alibaba]["meta_data"]).to eq("hostname" => "foo")
    end

  end

  describe "with hint file and with metadata connection" do
    before do
      allow(plugin).to receive(:hint?).with("alibaba").and_return({})
    end

    it_behaves_like "alibaba"
  end

  describe "with hint file and a metadata server error" do
    before do
      allow(plugin).to receive(:hint?).with("alibaba").and_return({})
      allow(plugin).to receive(:http_get).and_return(double("Net::HTTP Response", body: "", code: "403"))
    end

    it "sets an empty alibaba attribute without raising" do
      plugin.run
      expect(plugin[:alibaba]).to eq({})
    end
  end

  describe "with alibaba dmi sys_vendor data" do
    before do
      allow(plugin).to receive(:smbios_value).with(:sys_vendor).and_return("Alibaba Cloud")
    end

    it_behaves_like "alibaba"
  end

  describe "without hint file and non-alibaba dmi sys_vendor data" do
    before do
      allow(plugin).to receive(:smbios_value).with(:sys_vendor).and_return("TimCloud")
    end

    it_behaves_like "!alibaba"
  end

  describe "with the Alibaba Cloud ECS product name and no system vendor" do
    before do
      allow(plugin).to receive(:smbios_value).and_return(nil)
      allow(plugin).to receive(:smbios_value).with(:product_name).and_return("Alibaba Cloud ECS")
    end

    it "looks like Alibaba" do
      expect(plugin.looks_like_alibaba?).to be true
    end
  end
end
