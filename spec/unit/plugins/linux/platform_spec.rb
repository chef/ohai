#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Ohai::System, "Linux plugin platform" do
  let(:plugin) { get_plugin("linux/platform") }

  describe "#read_os_release_info" do
    let(:file_contents) { "COW=MOO\nDOG=\"BARK\"" }

    it "returns nil if the file does not exist" do
      allow(plugin).to receive(:file_exist?).with("/etc/test-release").and_return(false)
      expect(plugin.read_os_release_info("/etc/test-release")).to be nil
    end

    it "returns a hash of expected contents" do
      allow(plugin).to receive(:file_exist?).with("/etc/test-release").and_return(true)
      allow(plugin).to receive(:file_read).with("/etc/test-release").and_return(file_contents)
      release_info = plugin.read_os_release_info("/etc/test-release")

      expect(release_info["COW"]).to eq("MOO")
      expect(release_info["DOG"]).to eq("BARK")
    end
  end

  describe "#os_release_info" do
    context "when CISCO_RELEASE_INFO is not populated" do
      let(:release_info) { { "ID" => "os_id" } }

      before do
        allow(plugin).to receive(:file_exist?).with("/etc/os-release").and_return(true)
        allow(plugin).to receive(:read_os_release_info).with("/etc/os-release").and_return(release_info)
      end

      it "reads the os-release file" do
        expect(plugin).to receive(:read_os_release_info).with("/etc/os-release").and_return(release_info)
        plugin.os_release_info
      end

      it "returns a hash of expected contents" do
        expect(plugin.os_release_info["ID"]).to eq("os_id")
      end
    end

    context "when CISCO_RELEASE_INFO is populated" do
      let(:release_info) { { "ID" => "os_id", "CISCO_RELEASE_INFO" => "/etc/cisco-release" } }
      let(:cisco_release_info) { { "ID" => "cisco_id" } }

      before do
        allow(plugin).to receive(:file_exist?).with("/etc/os-release").and_return(true)
        allow(plugin).to receive(:file_exist?).with("/etc/cisco-release").and_return(true)
        allow(plugin).to receive(:read_os_release_info).with("/etc/os-release").and_return(release_info)
        allow(plugin).to receive(:read_os_release_info).with("/etc/cisco-release").and_return(cisco_release_info)
      end

      it "reads the os-release AND the cisco-release file" do
        expect(plugin).to receive(:read_os_release_info).with("/etc/os-release").and_return(release_info)
        expect(plugin).to receive(:read_os_release_info).with("/etc/cisco-release").and_return(release_info)
        plugin.os_release_info
      end

      it "returns the ID from the cisco-release file instead of the os-release file" do
        expect(plugin.os_release_info["ID"]).to eq("cisco_id")
      end
    end
  end

  describe "#platform_id_remap" do
    # https://github.com/chef/os_release/blob/main/redhat_7
    it "returns redhat for rhel os-release id" do
      expect(plugin.platform_id_remap("rhel")).to eq("redhat")
    end

    # https://github.com/chef/os_release/blob/main/amazon_2018
    it "returns amazon for amzn os-release id" do
      expect(plugin.platform_id_remap("amzn")).to eq("amazon")
    end

    # https://github.com/chef/os_release/blob/main/oracle_7
    it "returns oracle for ol os-release id" do
      expect(plugin.platform_id_remap("ol")).to eq("oracle")
    end

    # https://github.com/chef/os_release/blob/main/sles_sap_12_3
    it "returns suse for sles_sap os-release id" do
      expect(plugin.platform_id_remap("sles_sap")).to eq("suse")
    end

    # https://github.com/chef/os_release/blob/main/archarm
    it "returns arch for archarm" do
      expect(plugin.platform_id_remap("archarm")).to eq("arch")
    end

    # https://github.com/chef/os_release/blob/main/sles_15_0
    it "returns suse for sles os-release id" do
      expect(plugin.platform_id_remap("sles")).to eq("suse")
    end

    # https://github.com/chef/os_release/blob/main/opensuseleap_15_0
    it "returns opensuseleap for opensuse-leap os-release id" do
      expect(plugin.platform_id_remap("opensuse-leap")).to eq("opensuseleap")
    end

    # https://github.com/chef/os_release/blob/main/xenserver_7_6
    it "returns xenserver for xenenterprise os-release id" do
      expect(plugin.platform_id_remap("xenenterprise")).to eq("xenserver")
    end

    # https://github.com/chef/os_release/blob/main/cumulus_3_7
    it "returns cumulus for cumulus-linux os-release id" do
      expect(plugin.platform_id_remap("cumulus-linux")).to eq("cumulus")
    end

    # https://github.com/chef/os_release/blob/main/clearlinux_1
    it "returns clearlinux for clear-linux-os os-release id" do
      expect(plugin.platform_id_remap("clear-linux-os")).to eq("clearlinux")
    end

    # See https://github.com/chef/os_release/blob/main/xcp-ng_7_4#L3 for an example of why we do this
    it "returns a downcased ID value" do
      expect(plugin.platform_id_remap("XCP-ng")).to eq("xcp-ng")
    end

    it "does not transformation for any other platform" do
      expect(plugin.platform_id_remap("ubuntu")).to eq("ubuntu")
    end

    context "when on a centos subshell on a nexus switch" do
      let(:os_release_content) do
        <<~OS_RELEASE
          NAME="CentOS Linux"
          VERSION="7 (Core)"
          ID="centos"
          ID_LIKE="rhel fedora"
          VERSION_ID="7"
          PRETTY_NAME="CentOS Linux 7 (Core)"

          CISCO_RELEASE_INFO=/etc/shared/os-release
        OS_RELEASE
      end

      let(:cisco_release_content) do
        <<~CISCO_RELEASE
          ID=nexus
          ID_LIKE=wrlinux
          NAME=Nexus
          VERSION="7.0(3)I2(0.475E.6)"
          VERSION_ID="7.0(3)I2"
          PRETTY_NAME="Nexus 7.0(3)I2"
          HOME_URL=http://www.cisco.com
          BUILD_ID=6
          CISCO_RELEASE_INFO=/etc/shared/os-release
        CISCO_RELEASE
      end

      it "returns nexus_centos for centos os-release id" do
        expect(plugin).to receive(:file_exist?).at_least(:once).with("/etc/shared/os-release").and_return(true)
        expect(plugin).to receive(:file_exist?).at_least(:once).with("/etc/os-release").and_return(true)
        expect(plugin).to receive(:file_read).with("/etc/os-release").and_return(os_release_content)
        expect(plugin).to receive(:file_read).with("/etc/shared/os-release").and_return(cisco_release_content)
        expect(plugin.platform_id_remap("centos")).to eq("nexus_centos")
      end
    end
  end

  describe "#platform_family_from_platform" do
    %w{oracle centos redhat scientific xenserver cloudlinux ibm_powerkvm nexus_centos clearos}.each do |p|
      it "returns rhel for #{p} platform" do
        expect(plugin.platform_family_from_platform(p)).to eq("rhel")
      end
    end

    %w{suse sles opensuse opensuse-leap opensuseleap opensuse-tumbleweed opensuse-leap-micro opensuse-microos suse-microos sled sle-hpc sle_hpc sle_rt}.each do |p|
      it "returns suse for #{p} platform_family" do
        expect(plugin.platform_family_from_platform(p)).to eq("suse")
      end
    end

    %w{fedora arista_eos}.each do |p|
      it "returns fedora for #{p} platform_family" do
        expect(plugin.platform_family_from_platform(p)).to eq("fedora")
      end
    end

    %w{nexus ios_xr}.each do |p|
      it "returns wrlinux for #{p} platform_family" do
        expect(plugin.platform_family_from_platform(p)).to eq("wrlinux")
      end
    end

    %w{arch manjaro}.each do |p|
      it "returns arch for #{p} platform_family" do
        expect(plugin.platform_family_from_platform(p)).to eq("arch")
      end
    end

    %w{amazon slackware gentoo exherbo alpine clearlinux}.each do |same_name|
      it "returns #{same_name} for #{same_name} platform_family" do
        expect(plugin.platform_family_from_platform(same_name)).to eq(same_name)
      end
    end

    it "returns mandriva for mangeia platform" do
      expect(plugin.platform_family_from_platform("mangeia")).to eq("mandriva")
    end
  end

  describe "on system with /etc/os-release" do
    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:file_exist?).with("/etc/os-release").and_return(true)
    end

    context "when os-release data is correct" do
      let(:os_data) do
        <<~OS_DATA
          NAME="Ubuntu"
          VERSION="14.04.5 LTS, Trusty Tahr"
          ID=ubuntu
          ID_LIKE=debian
          PRETTY_NAME="Ubuntu 14.04.5 LTS"
          VERSION_ID="14.04"
        OS_DATA
      end

      before do
        expect(plugin).to receive(:file_read).with("/etc/os-release").and_return(os_data)
      end

      it "sets platform, platform_family, and platform_version from os-release" do
        plugin.run
        expect(plugin[:platform]).to eq("ubuntu")
        expect(plugin[:platform_family]).to eq("debian")
        expect(plugin[:platform_version]).to eq("14.04")
      end
    end

    context "when os-release data is missing a version_id" do
      let(:os_data) do
        <<~OS_DATA
          NAME="Arch Linux"
          PRETTY_NAME="Arch Linux"
          ID=arch
          ID_LIKE=archlinux
        OS_DATA
      end

      before do
        expect(plugin).to receive(:file_read).with("/etc/os-release").and_return(os_data)
      end

      it "sets platform_version using kernel version from uname" do
        allow(plugin).to receive(:shell_out).with("/bin/uname -r").and_return(mock_shell_out(0, "3.18.2-2-ARCH\n", ""))
        plugin.run
        expect(plugin[:platform]).to eq("arch")
        expect(plugin[:platform_family]).to eq("arch")
        expect(plugin[:platform_version]).to eq("3.18.2-2-ARCH")
      end
    end

    context "when platform requires remapping" do
      let(:os_data) do
        <<~OS_DATA
          NAME="openSUSE Leap"
          VERSION="15.0"
          ID="opensuse-leap"
          ID_LIKE="suse opensuse"
          VERSION_ID="15.0"
          PRETTY_NAME="openSUSE Leap 15.0"
        OS_DATA
      end

      before do
        expect(plugin).to receive(:file_read).with("/etc/os-release").and_return(os_data)
      end

      it "sets platform, platform_family, and platform_version from os-release" do
        plugin.run
        expect(plugin[:platform]).to eq("opensuseleap")
        expect(plugin[:platform_family]).to eq("suse")
        expect(plugin[:platform_version]).to eq("15.0")
      end
    end

    context "when on centos where version data in os-release is wrong" do
      let(:os_data) do
        <<~OS_DATA
          NAME="CentOS Linux"
          VERSION="7 (Core)"
          ID="centos"
          ID_LIKE="rhel fedora"
          VERSION_ID="7"
          PRETTY_NAME="CentOS Linux 7 (Core)"
        OS_DATA
      end

      before do
        expect(plugin).to receive(:file_read).with("/etc/os-release").and_return(os_data)
        expect(plugin).to receive(:file_read).with("/etc/redhat-release").and_return("CentOS Linux release 7.5.1804 (Core)")
      end

      it "sets platform, platform_family, and platform_version from os-release" do
        plugin.run
        expect(plugin[:platform]).to eq("centos")
        expect(plugin[:platform_family]).to eq("rhel")
        expect(plugin[:platform_version]).to eq("7.5.1804")
      end
    end

    # https://github.com/chef/os_release/blob/main/clearlinux_1
    context "when on clear linux with /etc/os-release" do
      let(:os_data) do
        <<~OS_DATA
          NAME="Clear Linux OS"
          VERSION=1
          ID=clear-linux-os
          ID_LIKE=clear-linux-os
          VERSION_ID=38250
          PRETTY_NAME="Clear Linux OS"
          ANSI_COLOR="1;35"
          HOME_URL="https://clearlinux.org"
          SUPPORT_URL="https://clearlinux.org"
          BUG_REPORT_URL="mailto:dev@lists.clearlinux.org"
          PRIVACY_POLICY_URL="http://www.intel.com/privacy"
          BUILD_ID=38250
        OS_DATA
      end

      before do
        expect(plugin).to receive(:file_read).with("/etc/os-release").and_return(os_data)
      end

      it "sets platform and platform_family to clearlinux" do
        plugin.run
        expect(plugin[:platform]).to eq("clearlinux")
        expect(plugin[:platform_family]).to eq("clearlinux")
        expect(plugin[:platform_version]).to eq("38250")
      end
    end

    context "when on debian and version data in os-release is missing" do
      let(:os_data) do
        <<~OS_DATA
          PRETTY_NAME="Debian GNU/Linux bullseye/sid"
          NAME="Debian GNU/Linux"
          ID=debian
          HOME_URL="https://www.debian.org/"
          SUPPORT_URL="https://www.debian.org/support"
          BUG_REPORT_URL="https://bugs.debian.org/"
        OS_DATA
      end

      before do
        expect(plugin).to receive(:file_read).with("/etc/os-release").and_return(os_data)
        expect(plugin).to receive(:file_read).with("/etc/debian_version").and_return("bullseye/sid")
      end

      it "sets platform, platform_family from os-release and platform_version from debian_version" do
        plugin.run
        expect(plugin[:platform]).to eq("debian")
        expect(plugin[:platform_family]).to eq("debian")
        expect(plugin[:platform_version]).to eq("bullseye/sid")
      end
    end

    context "when os-release has no ID" do
      let(:os_data) do
        <<~OS_DATA
          NAME="Linux"
          VERSION_ID="1.0"
        OS_DATA
      end

      before do
        expect(plugin).to receive(:file_read).with("/etc/os-release").and_return(os_data)
      end

      it "defaults the platform to generic-linux" do
        plugin.run
        expect(plugin[:platform]).to eq("generic-linux")
        expect(plugin[:platform_family]).to be_nil
        expect(plugin[:platform_version]).to eq("1.0")
      end
    end
  end

  describe "on system without /etc/os-release" do
    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:file_exist?).with("/etc/os-release").and_return(false)
    end

    # https://github.com/chef/os_release/blob/main/clearlinux_1
    context "when /usr/lib/os-release exists" do
      let(:os_data) do
        <<~OS_DATA
          NAME="Clear Linux OS"
          VERSION=1
          ID=clear-linux-os
          ID_LIKE=clear-linux-os
          VERSION_ID=38250
          PRETTY_NAME="Clear Linux OS"
          ANSI_COLOR="1;35"
          HOME_URL="https://clearlinux.org"
          SUPPORT_URL="https://clearlinux.org"
          BUG_REPORT_URL="mailto:dev@lists.clearlinux.org"
          PRIVACY_POLICY_URL="http://www.intel.com/privacy"
          BUILD_ID=38250
        OS_DATA
      end

      before do
        allow(plugin).to receive(:file_exist?).with("/usr/lib/os-release").and_return(true)
        allow(plugin).to receive(:file_read).with("/usr/lib/os-release").and_return(os_data)
      end

      it "reads platform, platform_family and platform_version from it" do
        plugin.run
        expect(plugin[:platform]).to eq("clearlinux")
        expect(plugin[:platform_family]).to eq("clearlinux")
        expect(plugin[:platform_version]).to eq("38250")
      end
    end

    context "when /usr/lib/os-release does not exist either" do
      before do
        allow(plugin).to receive(:file_exist?).with("/usr/lib/os-release").and_return(false)
        allow(plugin).to receive(:shell_out).with("/bin/uname -r").and_return(mock_shell_out(0, "2.6.32-754.el6.x86_64\n", ""))
      end

      it "reports generic-linux with the kernel release as platform_version" do
        plugin.run
        expect(plugin[:platform]).to eq("generic-linux")
        expect(plugin[:platform_family]).to be_nil
        expect(plugin[:platform_version]).to eq("2.6.32-754.el6.x86_64")
      end
    end
  end
end
