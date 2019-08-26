#
# Author:: Jonathan Amiez (<jonathan.amiez@gmail.com>)
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

describe Ohai::System, "plugin scaleway" do
  let(:plugin) { get_plugin("scaleway") }

  before do
    allow(plugin).to receive(:hint?).with("scaleway").and_return(false)
    allow(File).to receive(:read).with("/proc/cmdline").and_return(false)
  end

  shared_examples_for "!scaleway" do
    it "does not attempt to fetch the scaleway metadata" do
      expect(plugin).not_to receive(:http_client)
      expect(plugin[:scaleway]).to be_nil
      plugin.run
    end
  end

  shared_examples_for "scaleway" do
    before do
      @http_client = double("Net::HTTP client")
      allow(plugin).to receive(:http_client).and_return(@http_client)
      allow(IO).to receive(:select).and_return([[], [1], []])
      t = double("connection")
      allow(t).to receive(:connect_nonblock).and_raise(Errno::EINPROGRESS)
      allow(Socket).to receive(:new).and_return(t)
      allow(Socket).to receive(:pack_sockaddr_in).and_return(nil)
    end

    let(:body) do
      '{"tags": [], "state_detail": "booted", "public_ip": {"dynamic": false, "id": "7564c721-a128-444e-9c95-0754a7616482", "address": "5.1.9.3"}, "ssh_public_keys": [{"key": "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEA5qK2s41yyrNpaXXiQtb/1ADaVHVZZp9rYEtG6Dz7trOPtxkxNsaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/j2C+NAzo6TZCLTbJjBf89ieazqVqhY/dMNLDJINY2Ss2ytgyiJm9bp5bYcZz441czijBlmY/qmI0cFCVOJoDq6X9Lmn/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee+hmLFaTE3FeMr1hmeZT2ChH6ruHi8m6m18SfW0fl2fS8zG4yB+WE2IawdsoZmtgtY/Re3CpvhYP9S/JxpUedl+zzzzzzzzzzzzzzzzz5+YONBAt/PWMelXThfMukbwykto6IXmsX2qflBPsRVrWe0D7vt48loVScHDv5D05ZwqWY9rizFqCx3Y8xCLr6649ieonnnjHEsSOBREU507eXVJL6njHard+s+vuTC4bNH5LiP2INQS+9MaT37/l8WzIAL3U+hvcj95HS8KfATX+7XWa54bGJgeOnPle8ojwp1ssl7ddh2yFJozgk2CkUEyE4f1lmEX2YFJGoEoaW0QC2j0nNYiLs37yHG0h84AOgjoIAJo1rxpBAGGJOgFTkgnSdHjtDZsC9WjJYeu/QpxQ7Lf2Z+FCKoypfnZz/F10/z6nxnkZ3IKKM=", "fingerprint": "4096 4c:71:db:64:cd:24:da:4a:fa:5f:9e:70:af:ea:40:6e  (no comment) (RSA)"}], "private_ip": "10.8.23.7", "timezone": "UTC", "id": "77fab916-e7ff-44c6-a025-ae08837b4c4f", "extra_networks": [], "name": "sample-hostname", "hostname": "sample-hostname", "bootscript": {"kernel": "http://169.254.42.24/kernel/x86_64-4.9.20-std-1/vmlinuz-4.9.20-std-1", "title": "x86_64 4.9.20 std #1 (longterm/latest)", "default": false, "dtb": "", "public": false, "initrd": "http://169.254.42.24/initrd/initrd-Linux-x86_64-v3.12.7.gz", "bootcmdargs": "LINUX_COMMON scaleway boot=local", "architecture": "x86_64", "organization": "11111110-1112-4112-8112-111111111116", "id": "855f21ba-e7f9-421d-91b0-976a6ad59910"}, "location": {"platform_id": "21", "hypervisor_id": "518", "node_id": "4", "cluster_id": "82", "zone_id": "par1"}, "volumes": {"0": {"name": "x86_64-debian-stretch-2017-06-29_10:17", "modification_date": "2018-01-26T10:22:28.268074+00:00", "export_uri": "device://dev/vda", "volume_type": "l_ssd", "creation_date": "2018-01-26T10:22:28.268074+00:00", "organization": "90f39224-d0a2-4771-a2f0-1036a9402b97", "server": {"id": "77fab916-e7ff-44c6-a024-ae08837b4c4f", "name": "sample-hostname"}, "id": "3be53d4d-93d7-4430-a513-61cb4410624b", "size": 50000000000}}, "ipv6": null, "organization": "89f39224-d0a2-4771-a2f0-1036a9402b97", "commercial_type": "VC1S"}'
    end

    it "fetches and properly parse json metadata" do
      expect(@http_client).to receive(:get)
        .with("/conf?format=json")
        .and_return(double("Net::HTTP Response", body: body, code: "200"))
      plugin.run

      expect(plugin[:scaleway]).not_to be_nil
      expect(plugin[:scaleway]["id"]).to eq("77fab916-e7ff-44c6-a025-ae08837b4c4f")
      expect(plugin[:scaleway]["hostname"]).to eq("sample-hostname")
    end

    it "completes the run despite unavailable metadata" do
      expect(@http_client).to receive(:get)
        .with("/conf?format=json")
        .and_return(double("Net::HTTP Response", body: "", code: "404"))
      plugin.run

      expect(plugin[:scaleway]).not_to be_nil
    end
  end

  describe "without hint or cmdline" do
    it_behaves_like "!scaleway"
  end

  describe "with scaleway hint file" do
    before do
      allow(plugin).to receive(:hint?).with("scaleway").and_return(true)
    end

    it_behaves_like "scaleway"

  end

  describe "with scaleway cmdline" do
    before do
      allow(File).to receive(:read).with("/proc/cmdline").and_return("initrd=initrd showopts console=ttyS0,115200 nousb vga=0 root=/dev/vda scaleway boot=local")
    end

    it_behaves_like "scaleway"

  end
end
