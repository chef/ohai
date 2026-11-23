#
# Author:: Ranjib Dey (dey.ranjib@gmail.com)
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

describe Ohai::System, "plugin gce" do
  let(:plugin) { get_plugin("gce") }

  before do
    # SMBIOS fields a test doesn't set read as absent, on every platform
    allow(plugin).to receive(:smbios_value).and_return(nil)
  end

  shared_examples_for "!gce" do
    it "does NOT attempt to fetch the gce metadata" do
      expect(plugin).not_to receive(:http_get)
      plugin.run
    end

    it "does NOT set gce attributes" do
      expect(plugin[:gce]).to be_nil
      plugin.run
    end
  end

  shared_examples_for "gce" do
    before do
      @http_get = double("Net::HTTP client")
      allow(plugin).to receive(:http_get).and_return(double("Net::HTTP Response", body: '{"instance":{"hostname":"test-host"}}', code: "200"))
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

      expect(plugin[:gce]).not_to be_nil
      expect(plugin[:gce]["instance"]).to eq("hostname" => "test-host")
    end

  end

  describe "with hint file and with metadata connection" do
    before do
      allow(plugin).to receive(:hint?).with("gce").and_return({})
    end

    it_behaves_like "gce"

  end

  describe "with hint file and a metadata server error" do
    before do
      allow(plugin).to receive(:hint?).with("gce").and_return({})
      allow(plugin).to receive(:http_get).and_return(double("Net::HTTP Response", body: "", code: "503"))
    end

    it "sets an empty gce attribute without raising" do
      plugin.run
      expect(plugin[:gce]).to eq({})
    end
  end

  describe "without hint file and without metadata connection" do
    before do
      allow(plugin).to receive(:hint?).with("gce").and_return(false)

      # Raise Errno::ENOENT to simulate the scenario in which metadata server
      # can not be connected
      t = double("connection")
      allow(t).to receive(:connect_nonblock).and_raise(Errno::ENOENT)
      allow(Socket).to receive(:new).and_return(t)
      allow(Socket).to receive(:pack_sockaddr_in).and_return(Socket.pack_sockaddr_in(80, "127.0.0.1"))
    end

    it_behaves_like "!gce"

  end

  describe "#has_gce_dmi?" do
    before do
      allow(plugin).to receive(:smbios_value).and_return(nil)
    end

    { product_name: "Google Compute Engine", sys_vendor: "Google", bios_vendor: "Google", product_serial: "GoogleCloud-1234ABCD" }.each do |field, value|
      it "is true when #{field} is #{value}" do
        allow(plugin).to receive(:smbios_value).with(field).and_return(value)
        expect(plugin.has_gce_dmi?).to be true
      end
    end

    it "is true when the product name is only Google" do
      allow(plugin).to receive(:smbios_value).with(:product_name).and_return("Google")
      expect(plugin.has_gce_dmi?).to be true
    end

    it "is false for other systems" do
      allow(plugin).to receive(:smbios_value).with(:sys_vendor).and_return("Microsoft Corporation")
      allow(plugin).to receive(:smbios_value).with(:product_name).and_return("Virtual Machine")
      expect(plugin.has_gce_dmi?).to be false
    end
  end

  describe "with GCE DMI data and no hint" do
    before do
      allow(plugin).to receive(:hint?).with("gce").and_return(false)
      allow(plugin).to receive(:has_gce_dmi?).and_return(true)
    end

    it "probes the metadata server by IP address, without a DNS lookup" do
      expect(plugin).to receive(:can_socket_connect?).with("169.254.169.254", 80).and_return(false)
      expect(plugin.looks_like_gce?).to be false
    end
  end
end
