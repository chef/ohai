#
# Author:: Cary Penniman (<cary@rightscale.com>)
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, "plugin rackspace" do
  before(:each) do
    Ohai::Log.level = :debug
    @plugin = get_plugin("rackspace")
    @plugin[:hostname] = "katie"


    # # In olden days we could detect rackspace by a -rscloud suffix on the kernel
    # # This is here to make #has_rackspace_kernel? fail until we remove that check
    # @plugin[:kernel] = { :release => "1.2.13-not-rackspace" }

    # We need a generic stub here for the later stubs with arguments to work
    # Because, magic.
    fake_interfaces = "public\nprivate"
    fake_interface_public = <<-json_public
{
    "broadcast": "162.209.6.255",
    "dns": [
        "173.203.4.9",
        "173.203.4.8"
    ],
    "gateway": "162.209.6.1",
    "gateway_v6": "fe80::def",
    "ip6s": [
        {
            "enabled": "1",
            "gateway": "fe80::def",
            "ip": "2a00:1a48:7805:111:e875:efaf:ff08:75",
            "netmask": 64
        }
    ],
    "ips": [
        {
            "enabled": "1",
            "gateway": "162.209.6.1",
            "ip": "1.2.3.4",
            "netmask": "255.255.255.0"
        }
    ],
    "label": "public",
    "mac": "BC:76:4E:11:15:53"
}
json_public
    fake_interface_private = <<-json_private
{
    "broadcast": "10.178.127.255",
    "dns": [
        "173.203.4.9",
        "173.203.4.8"
    ],
    "gateway": null,
    "ips": [
        {
            "enabled": "1",
            "gateway": null,
            "ip": "5.6.7.8",
            "netmask": "255.255.128.0"
        }
    ],
    "label": "private",
    "mac": "BC:76:4E:11:17:2E",
    "routes": [
        {
            "gateway": "10.178.0.1",
            "netmask": "255.240.0.0",
            "route": "10.208.0.0"
        },
        {
            "gateway": "10.178.0.1",
            "netmask": "255.240.0.0",
            "route": "10.176.0.0"
        }
    ]
}
json_private

    allow(@plugin).to receive(:run_command).and_return([1, "", ""])
    allow(@plugin).to receive(:run_command).with(:no_status_check => true, :command => "xenstore ls vm-data/networking").and_return([0, fake_interfaces, ""])
    allow(@plugin).to receive(:run_command).with(:no_status_check => true, :command => "xenstore read vm-data/networking/public").and_return([0, fake_interface_public, ""])
    allow(@plugin).to receive(:run_command).with(:no_status_check => true, :command => "xenstore read vm-data/networking/private").and_return([0, fake_interface_private, ""])
    allow(@plugin).to receive(:run_command).with(:no_status_check => true, :command => "xenstore read vm-data/provider_data/region").and_return([0, "dfw", ""])

  end

  context "should create rackspace node" do
    before(:each) do
      allow(@plugin).to receive(:hint?).with('rackspace').and_return(true)
    end

    it "should create rackspace" do
      @plugin.run
      expect(@plugin[:rackspace]).not_to be_nil
    end

    it "should have all required attributes" do
      @plugin.run
      puts @plugin[:rackspace].inspect
      expect(@plugin[:rackspace][:public_ip]).not_to be_nil
      expect(@plugin[:rackspace][:private_ip]).not_to be_nil
      expect(@plugin[:rackspace][:public_ipv4]).not_to be_nil
      expect(@plugin[:rackspace][:local_ipv4]).not_to be_nil
      expect(@plugin[:rackspace][:public_ipv6]).not_to be_nil
      expect(@plugin[:rackspace][:local_ipv6]).to be_nil
      expect(@plugin[:rackspace][:local_hostname]).not_to be_nil
      expect(@plugin[:rackspace][:public_hostname]).not_to be_nil
    end

    it "should have correct values for all attributes" do
      @plugin.run
      expect(@plugin[:rackspace][:public_ip]).to eq("1.2.3.4")
      expect(@plugin[:rackspace][:private_ip]).to eq("5.6.7.8")
      expect(@plugin[:rackspace][:public_ipv4]).to eq("1.2.3.4")
      expect(@plugin[:rackspace][:local_ipv4]).to eq("5.6.7.8")
      expect(@plugin[:rackspace][:public_ipv6]).to eq("2a00:1a48:7805:111:e875:efaf:ff08:75")
      expect(@plugin[:rackspace][:local_hostname]).to eq('katie')
      expect(@plugin[:rackspace][:public_hostname]).to eq("1-2-3-4.static.cloud-ips.com")
      expect(@plugin[:rackspace][:region]).to eq("dfw")
    end

  end

  describe "does not have private networks" do
    before do
      stdout = 'BC764E20422B = "{"label": "public"}"\n'
      allow(@plugin).to receive(:shell_out).with("xenstore-ls vm-data/networking").and_return(mock_shell_out(0, stdout, "" ))
      stdout = '{"label": "public", "broadcast": "9.10.11.255", "ips": [{"ip": "9.10.11.12", "netmask": "255.255.255.0", "enabled": "1", "gateway": null}], "mac": "BC:76:4E:20:42:2B", "dns": ["69.20.0.164", "69.20.0.196"], "gateway": null}'
      allow(@plugin).to receive(:shell_out).with("xenstore-read vm-data/networking/BC764E20422B").and_return(mock_shell_out(0, stdout, "" ))
      allow(@plugin).to receive(:hint?).with('rackspace').and_return(true)
    end

    it "should not have private_networks object" do
      @plugin.run
      expect(@plugin[:rackspace][:private_networks]).to be_nil
    end
  end

end
