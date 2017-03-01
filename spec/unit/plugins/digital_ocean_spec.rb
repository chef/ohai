#
# Author:: Dylan Page (<dpage@digitalocean.com>)
# Author:: Stafford Brunk (<stafford.brunk@gmail.com>)
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

describe Ohai::System, "plugin digital_ocean" do
  let(:plugin) { get_plugin("digital_ocean") }
  let(:hint) do
    {
      "droplet_id" => 12345678,
      "name" => "example.com",
      "image_id" => 3240036,
      "size_id" => 66,
      "region_id" => 4,
      "ip_addresses" => {
        "public" => "1.2.3.4",
        "private" => "5.6.7.8",
      },
    }
  end

  before(:each) do
    allow(plugin).to receive(:hint?).with("digital_ocean").and_return(false)
  end

  shared_examples_for "!digital_ocean" do
    it "should NOT attempt to fetch the digital_ocean metadata" do
      expect(plugin).not_to receive(:http_client)
      expect(plugin[:digital_ocean]).to be_nil
      plugin.run
    end
  end

  shared_examples_for "digital_ocean" do
    before(:each) do
      @http_client = double("Net::HTTP client")
      allow(plugin).to receive(:http_client).and_return(@http_client)
      allow(IO).to receive(:select).and_return([[], [1], []])
      t = double("connection")
      allow(t).to receive(:connect_nonblock).and_raise(Errno::EINPROGRESS)
      allow(Socket).to receive(:new).and_return(t)
      allow(Socket).to receive(:pack_sockaddr_in).and_return(nil)
    end

    let(:body) do
      '{"droplet_id":2756924,"hostname":"sample-droplet","vendor_data":"#cloud-config\ndisable_root: false\nmanage_etc_hosts: true\n\n# The modules that run in the \'init\' stage\ncloud_init_modules:\n - migrator\n - ubuntu-init-switch\n - seed_random\n - bootcmd\n - write-files\n - growpart\n - resizefs\n - set_hostname\n - update_hostname\n - [ update_etc_hosts, once-per-instance ]\n - ca-certs\n - rsyslog\n - users-groups\n - ssh\n\n# The modules that run in the \'config\' stage\ncloud_config_modules:\n - disk_setup\n - mounts\n - ssh-import-id\n - locale\n - set-passwords\n - grub-dpkg\n - apt-pipelining\n - apt-configure\n - package-update-upgrade-install\n - landscape\n - timezone\n - puppet\n - chef\n - salt-minion\n - mcollective\n - disable-ec2-metadata\n - runcmd\n - byobu\n\n# The modules that run in the \'final\' stage\ncloud_final_modules:\n - rightscale_userdata\n - scripts-vendor\n - scripts-per-once\n - scripts-per-boot\n - scripts-per-instance\n - scripts-user\n - ssh-authkey-fingerprints\n - keys-to-console\n - phone-home\n - final-message\n - power-state-change\n","public_keys":["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAkMD3PYKHaH0KbDiXrRE6KCBo/OKcFqhM+fmnnb0+LUh4RalJWX4edeJmnT5bxLeqmLV/Yggjlpfq73R+Dy7JB4pbBLuM959mSM9ohBCSnByAGoT2iUPev4aZFZZ/ahUzTCylNxXrhZV/bopD399CvYREt7Q+FlauBv0O8MMuMGR8aC69Z3jNL+r+fGWNq98JVHGFO/UgoNL15wGCaidMhzfRqkt1u+m1nY77SFM5qWJz2R0CEC4fMlOiCg8mWBklnryV4yDEPgiXp2I8Rli1Eu2GHwuY1YX9elMeQS7n3Pzq7l6aIQmSgvcEWx6TgMD2V7nQUWpfcud/8dpp/t7z9UyfzLmNwnULHNmUeEp52sejcH5lYzISnkkWa1LzlKSeIrhF3y45m9AyxIfjEqyh/mlKQtUaW3NVXXLPwrNitxHtMIZPU5b16BODn0wb8bqPxpDNpUYrQd/BS7mWDxNpICP2ObLPhd9LW9KIYRNTzryE+uKwxm9NkMlhRku2fu415fH0G0+7aURsHviNN9SO4zct3Pj6QE5rnbVHqxt3biplUTOScdWxSk2Nv3V2dGdt/lBfu6iRPAV9IAS31s7Po3qK1t2jpEPCJwstaCBOM80kmoi3zAgotiAW50X8CelaWsHNrq5jBBgeHUZWgn/c8BkcI61pUE9l34Q6gsiEMQ== tsmith84@gmail.com"],"region":"nyc3","interfaces":{"public":[{"ipv4":{"ip_address":"159.203.92.161","netmask":"255.255.240.0","gateway":"159.203.80.1"},"ipv6":{"ip_address":"2604:A880:0800:00A1:0000:0000:0201:0001","cidr":64,"gateway":"2604:A880:0800:00A1:0000:0000:0000:0001"},"anchor_ipv4":{"ip_address":"10.17.0.5","netmask":"255.255.0.0","gateway":"10.17.0.1"},"mac":"04:01:e5:14:03:01","type":"public"}]},"floating_ip":{"ipv4":{"active":false}},"dns":{"nameservers":["2001:4860:4860::8844","2001:4860:4860::8888","8.8.8.8"]}}'
    end

    it "should fetch and properly parse json metadata" do
      expect(@http_client).to receive(:get).
        with("/metadata/v1.json").
        and_return(double("Net::HTTP Response", :body => body, :code => "200"))
      plugin.run

      expect(plugin[:digital_ocean]).not_to be_nil
      expect(plugin[:digital_ocean]["droplet_id"]).to eq(2756924)
      expect(plugin[:digital_ocean]["hostname"]).to eq("sample-droplet")
    end

    it "should complete the run despite unavailable metadata" do
      expect(@http_client).to receive(:get).
        with("/metadata/v1.json").
        and_return(double("Net::HTTP Response", :body => "", :code => "404"))
      plugin.run

      expect(plugin[:digitalocean]).to be_nil
    end
  end

  describe "without hint or dmi data" do
    it_should_behave_like "!digital_ocean"
  end

  describe "with digital_ocean hint file" do
    it_should_behave_like "digital_ocean"

    before(:each) do
      allow(plugin).to receive(:hint?).with("digital_ocean").and_return(true)
    end
  end

  describe "with digital_ocean DMI data" do
    it_should_behave_like "digital_ocean"

    before(:each) do
      plugin[:dmi] = { :bios => { :all_records => [ { :Vendor => "DigitalOcean" } ] } }
    end
  end
end
