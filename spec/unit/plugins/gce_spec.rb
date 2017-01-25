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

require_relative "../../spec_helper.rb"
require "open-uri"

describe Ohai::System, "plugin gce" do
  let(:plugin) { get_plugin("gce") }

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
    before(:each) do
      @http_get = double("Net::HTTP client")
      allow(plugin).to receive(:http_get).and_return(double("Net::HTTP Response", :body => '{"instance":{"hostname":"test-host"}}', :code => "200"))
      allow(IO).to receive(:select).and_return([[], [1], []])
      t = double("connection")
      allow(t).to receive(:connect_nonblock).and_raise(Errno::EINPROGRESS)
      allow(Socket).to receive(:new).and_return(t)
      allow(Socket).to receive(:pack_sockaddr_in).and_return(nil)
    end

    it "recursively fetches and properly parses json metadata" do
      plugin.run

      expect(plugin[:gce]).not_to be_nil
      expect(plugin[:gce]["instance"]).to eq("hostname" => "test-host")
    end

  end

  describe "with hint file and with metadata connection" do
    it_behaves_like "gce"

    before(:each) do
      allow(plugin).to receive(:hint?).with("gce").and_return({})
    end
  end

  describe "without hint file and without metadata connection" do
    it_behaves_like "!gce"

    before(:each) do
      allow(plugin).to receive(:hint?).with("gce").and_return(false)

      # Raise Errno::ENOENT to simulate the scenario in which metadata server
      # can not be connected
      t = double("connection")
      allow(t).to receive(:connect_nonblock).and_raise(Errno::ENOENT)
      allow(Socket).to receive(:new).and_return(t)
      allow(Socket).to receive(:pack_sockaddr_in).and_return(nil)
    end
  end

end
