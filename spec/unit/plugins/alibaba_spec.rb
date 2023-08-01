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
    allow(plugin).to receive(:hint?).with("alibaba").and_return(false)
    allow(plugin).to receive(:file_exist?).with("/sys/class/dmi/id/sys_vendor").and_return(false)
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
      allow(Socket).to receive(:new).and_return(t)
      allow(Socket).to receive(:pack_sockaddr_in).and_return(nil)
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

  describe "with alibaba dmi sys_vendor data" do
    before do
      allow(plugin).to receive(:file_exist?).with("/sys/class/dmi/id/sys_vendor").and_return(true)
      allow(plugin).to receive(:file_read).with("/sys/class/dmi/id/sys_vendor").and_return("Alibaba Cloud\n")
    end

    it_behaves_like "alibaba"
  end

  describe "without hint file and non-alibaba dmi sys_vendor data" do
    before do
      allow(plugin).to receive(:file_exist?).with("/sys/class/dmi/id/sys_vendor").and_return(true)
      allow(plugin).to receive(:file_read).with("/sys/class/dmi/id/sys_vendor").and_return("TimCloud\n")
    end

    it_behaves_like "!alibaba"
  end
end
