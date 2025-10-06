#
# Contributed by: Aaron Kalin (<akalin@martinisoftware.com>)
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

describe Ohai::System, "plugin linode" do
  let(:plugin) { get_plugin("linode") }

  let(:apt_sources) { "# \n\n# deb cdrom:[Ubuntu-Server 20.04.1 LTS _Focal Fossa_ - Release amd64 (20200731)]/ focal main restricted\n\n#deb cdrom:[Ubuntu-Server 20.04.1 LTS _Focal Fossa_ - Release amd64 (20200731)]/ focal main restricted\n\n# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to\n# newer versions of the distribution.\ndeb http://mirrors.linode.com/ubuntu/ focal main restricted\n# deb-src http://mirrors.linode.com/ubuntu/ focal main restricted\n\n## Major bug fix updates produced after the final release of the\n## distribution.\ndeb http://mirrors.linode.com/ubuntu/ focal-updates main restricted\n# deb-src http://mirrors.linode.com/ubuntu/ focal-updates main restricted\n\n## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu\n## team. Also, please note that software in universe WILL NOT receive any\n## review or updates from the Ubuntu security team.\ndeb http://mirrors.linode.com/ubuntu/ focal universe\n# deb-src http://mirrors.linode.com/ubuntu/ focal universe\ndeb http://mirrors.linode.com/ubuntu/ focal-updates universe\n# deb-src http://mirrors.linode.com/ubuntu/ focal-updates universe\n\n## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu \n## team, and may not be under a free licence. Please satisfy yourself as to \n## your rights to use the software. Also, please note that software in \n## multiverse WILL NOT receive any review or updates from the Ubuntu\n## security team.\ndeb http://mirrors.linode.com/ubuntu/ focal multiverse\n# deb-src http://mirrors.linode.com/ubuntu/ focal multiverse\ndeb http://mirrors.linode.com/ubuntu/ focal-updates multiverse\n# deb-src http://mirrors.linode.com/ubuntu/ focal-updates multiverse\n\n## N.B. software from this repository may not have been tested as\n## extensively as that contained in the main release, although it includes\n## newer versions of some applications which may provide useful features.\n## Also, please note that software in backports WILL NOT receive any review\n## or updates from the Ubuntu security team.\ndeb http://mirrors.linode.com/ubuntu/ focal-backports main restricted universe multiverse\n# deb-src http://mirrors.linode.com/ubuntu/ focal-backports main restricted universe multiverse\n\n## Uncomment the following two lines to add software from Canonical's\n## 'partner' repository.\n## This software is not part of Ubuntu, but is offered by Canonical and the\n## respective vendors as a service to Ubuntu users.\n# deb http://archive.canonical.com/ubuntu focal partner\n# deb-src http://archive.canonical.com/ubuntu focal partner\n\ndeb http://security.ubuntu.com/ubuntu focal-security main restricted\n# deb-src http://security.ubuntu.com/ubuntu focal-security main restricted\ndeb http://security.ubuntu.com/ubuntu focal-security universe\n# deb-src http://security.ubuntu.com/ubuntu focal-security universe\ndeb http://security.ubuntu.com/ubuntu focal-security multiverse\n# deb-src http://security.ubuntu.com/ubuntu focal-security multiverse\n\n# This system was installed using small removable media\n# (e.g. netinst, live or single CD). The matching \"deb cdrom\"\n# entries were disabled at the end of the installation process.\n# For information about how to configure apt package sources,\n# see the sources.list(5) manual.\n" }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
    allow(plugin).to receive(:file_exist?).with("/etc/apt/sources.list").and_return(false)
    plugin[:domain] = "nope.example.com"
    plugin[:network] = {
      "interfaces" => {
        "eth0" => {
          "addresses" => {
            "1.2.3.4" => {
              "broadcast" => "67.23.20.255",
              "netmask" => "255.255.255.0",
              "family" => "inet",
            },
            "fe80::4240:95ff:fe47:6eed" => {
              "scope" => "Link",
              "prefixlen" => "64",
              "family" => "inet6",
            },
            "40:40:95:47:6E:ED" => {
              "family" => "lladdr",
            },
          },
        },
      },
    }
  end

  shared_examples_for "!linode" do
    it "does not create the linode mash" do
      plugin.run
      expect(plugin[:linode]).to be_nil
    end
  end

  shared_examples_for "linode" do
    it "creates the linode mash" do
      plugin.run
      expect(plugin[:linode]).not_to be_nil
    end

    it "has public_ip attribute" do
      plugin.run
      expect(plugin[:linode][:public_ip]).not_to be_nil
    end

    it "has correct value for public_ip attribute" do
      plugin.run
      expect(plugin[:linode][:public_ip]).to eq("1.2.3.4")
    end

  end

  context "without linode domain or apt data" do
    it_behaves_like "!linode"
  end

  context "with linode domain" do
    before do
      plugin[:domain] = "members.linode.com"
    end

    it_behaves_like "linode"

    # This test is an interface created according to this guide by Linode
    # http://library.linode.com/networking/configuring-static-ip-interfaces
    context "with configured private ip address as suggested by linode" do
      before do
        plugin[:network][:interfaces]["eth0:1"] = {
          "addresses" => {
            "5.6.7.8" => {
              "broadcast" => "10.176.191.255",
              "netmask" => "255.255.224.0",
              "family" => "inet",
            },
            "fe80::4240:f5ff:feab:2836" => {
              "scope" => "Link",
              "prefixlen" => "64",
              "family" => "inet6",
            },
            "40:40:F5:AB:28:36" => {
              "family" => "lladdr",
            },
          },
        }
      end

      it "detects and sets the private ip" do
        plugin.run
        expect(plugin[:linode][:private_ip]).not_to be_nil
        expect(plugin[:linode][:private_ip]).to eq("5.6.7.8")
      end
    end

  end

  describe "with linode apt sources" do
    before do
      allow(plugin).to receive(:file_exist?).with("/etc/apt/sources.list").and_return(true)
      allow(plugin).to receive(:file_read).with("/etc/apt/sources.list").and_return(apt_sources)
    end

    it_behaves_like "linode"
  end

  describe "with linode hint file" do
    before do
      allow(plugin).to receive(:hint?).with("linode").and_return({})
    end

    it_behaves_like "linode"
  end

  describe "without hint file" do
    before do
      allow(plugin).to receive(:hint?).with("linode").and_return(false)
    end

    it_behaves_like "!linode"
  end

end
