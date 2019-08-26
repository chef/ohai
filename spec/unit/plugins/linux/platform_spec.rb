#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2008-2018, Chef Software Inc.
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
      allow(File).to receive(:exist?).with("/etc/test-release").and_return(false)
      expect(plugin.read_os_release_info("/etc/test-release")).to be nil
    end

    it "returns a hash of expected contents" do
      allow(File).to receive(:exist?).with("/etc/test-release").and_return(true)
      allow(File).to receive(:read).with("/etc/test-release").and_return(file_contents)
      release_info = plugin.read_os_release_info("/etc/test-release")

      expect(release_info["COW"]).to eq("MOO")
      expect(release_info["DOG"]).to eq("BARK")
    end
  end

  describe "#os_release_info" do
    context "when CISCO_RELEASE_INFO is not populated" do
      let(:release_info) { { "ID" => "os_id" } }

      before do
        allow(File).to receive(:exist?).with("/etc/os-release").and_return(true)
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
        allow(File).to receive(:exist?).with("/etc/os-release").and_return(true)
        allow(File).to receive(:exist?).with("/etc/cisco-release").and_return(true)
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
    # https://github.com/chef/os_release/blob/master/redhat_7
    it "returns redhat for rhel os-release id" do
      expect(plugin.platform_id_remap("rhel")).to eq("redhat")
    end

    # https://github.com/chef/os_release/blob/master/amazon_2018
    it "returns amazon for amzn os-release id" do
      expect(plugin.platform_id_remap("amzn")).to eq("amazon")
    end

    # https://github.com/chef/os_release/blob/master/oracle_7
    it "returns oracle for ol os-release id" do
      expect(plugin.platform_id_remap("ol")).to eq("oracle")
    end

    # https://github.com/chef/os_release/blob/master/sles_sap_12_3
    it "returns suse for sles_sap os-release id" do
      expect(plugin.platform_id_remap("sles_sap")).to eq("suse")
    end

    # https://github.com/chef/os_release/blob/master/archarm
    it "returns arch for archarm" do
      expect(plugin.platform_id_remap("archarm")).to eq("arch")
    end

    # https://github.com/chef/os_release/blob/master/sles_15_0
    it "returns suse for sles os-release id" do
      expect(plugin.platform_id_remap("sles")).to eq("suse")
    end

    # https://github.com/chef/os_release/blob/master/opensuseleap_15_0
    it "returns opensuseleap for opensuse-leap os-release id" do
      expect(plugin.platform_id_remap("opensuse-leap")).to eq("opensuseleap")
    end

    # https://github.com/chef/os_release/blob/master/xenserver_7_6
    it "returns xenserver for xenenterprise os-release id" do
      expect(plugin.platform_id_remap("xenenterprise")).to eq("xenserver")
    end

    # https://github.com/chef/os_release/blob/master/cumulus_3_7
    it "returns cumulus for cumulus-linux os-release id" do
      expect(plugin.platform_id_remap("cumulus-linux")).to eq("cumulus")
    end

    it "does not transformation for any other platform" do
      expect(plugin.platform_id_remap("ubuntu")).to eq("ubuntu")
    end

    context "on a centos subshell on a nexus switch" do
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
        expect(File).to receive(:exist?).at_least(:once).with("/etc/shared/os-release").and_return(true)
        expect(File).to receive(:exist?).at_least(:once).with("/etc/os-release").and_return(true)
        expect(File).to receive(:read).with("/etc/os-release").and_return(os_release_content)
        expect(File).to receive(:read).with("/etc/shared/os-release").and_return(cisco_release_content)
        expect(plugin.platform_id_remap("centos")).to eq("nexus_centos")
      end
    end
  end

  describe "#platform_family_from_platform" do
    %w{oracle centos redhat scientific enterpriseenterprise xenserver cloudlinux ibm_powerkvm parallels nexus_centos clearos bigip}.each do |p|
      it "returns rhel for #{p} platform" do
        expect(plugin.platform_family_from_platform(p)).to eq("rhel")
      end
    end

    %w{suse sles opensuse opensuseleap sled}.each do |p|
      it "returns suse for #{p} platform_family" do
        expect(plugin.platform_family_from_platform(p)).to eq("suse")
      end
    end

    %w{fedora pidora arista_eos}.each do |p|
      it "returns fedora for #{p} platform_family" do
        expect(plugin.platform_family_from_platform(p)).to eq("fedora")
      end
    end

    %w{nexus ios_xr}.each do |p|
      it "returns wrlinux for #{p} platform_family" do
        expect(plugin.platform_family_from_platform(p)).to eq("wrlinux")
      end
    end

    %w{arch manjaro antergos}.each do |p|
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
      allow(::File).to receive(:exist?).with("/etc/os-release").and_return(true)
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
        expect(File).to receive(:read).with("/etc/os-release").and_return(os_data)
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
        expect(File).to receive(:read).with("/etc/os-release").and_return(os_data)
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
        expect(File).to receive(:read).with("/etc/os-release").and_return(os_data)
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
        expect(File).to receive(:read).with("/etc/os-release").and_return(os_data)
        expect(File).to receive(:read).with("/etc/redhat-release").and_return("CentOS Linux release 7.5.1804 (Core)")
      end

      it "sets platform, platform_family, and platform_version from os-release" do
        plugin.run
        expect(plugin[:platform]).to eq("centos")
        expect(plugin[:platform_family]).to eq("rhel")
        expect(plugin[:platform_version]).to eq("7.5.1804")
      end
    end
  end

  context "on system without /etc/os-release (legacy)" do
    let(:have_debian_version) { false }
    let(:have_redhat_release) { false }
    let(:have_exherbo_release) { false }
    let(:have_eos_release) { false }
    let(:have_suse_release) { false }
    let(:have_system_release) { false }
    let(:have_slackware_version) { false }
    let(:have_enterprise_release) { false }
    let(:have_oracle_release) { false }
    let(:have_parallels_release) { false }
    let(:have_os_release) { false }
    let(:have_os_release) { false }
    let(:have_usr_lib_os_release) { false }
    let(:have_cisco_release) { false }
    let(:have_f5_release) { false }

    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      plugin[:lsb] = Mash.new
      allow(File).to receive(:exist?).with("/etc/debian_version").and_return(have_debian_version)
      allow(File).to receive(:exist?).with("/etc/redhat-release").and_return(have_redhat_release)
      allow(File).to receive(:exist?).with("/etc/exherbo-release").and_return(have_exherbo_release)
      allow(File).to receive(:exist?).with("/etc/Eos-release").and_return(have_eos_release)
      allow(File).to receive(:exist?).with("/etc/SuSE-release").and_return(have_suse_release)
      allow(File).to receive(:exist?).with("/etc/system-release").and_return(have_system_release)
      allow(File).to receive(:exist?).with("/etc/slackware-version").and_return(have_slackware_version)
      allow(File).to receive(:exist?).with("/etc/enterprise-release").and_return(have_enterprise_release)
      allow(File).to receive(:exist?).with("/etc/oracle-release").and_return(have_oracle_release)
      allow(File).to receive(:exist?).with("/etc/parallels-release").and_return(have_parallels_release)
      allow(File).to receive(:exist?).with("/etc/os-release").and_return(have_os_release)
      allow(File).to receive(:exist?).with("/etc/f5-release").and_return(have_f5_release)
      allow(File).to receive(:exist?).with("/usr/lib/os-release").and_return(have_usr_lib_os_release)
      allow(File).to receive(:exist?).with("/etc/shared/os-release").and_return(have_cisco_release)

      allow(File).to receive(:read).with("PLEASE STUB ALL File.read CALLS")
    end

    describe "on lsb compliant distributions" do
      before do
        plugin[:lsb][:id] = "Ubuntu"
        plugin[:lsb][:release] = "18.04"
      end

      it "sets platform to lowercased lsb[:id]" do
        plugin.run
        expect(plugin[:platform]).to eq("ubuntu")
      end

      it "sets platform_version to lsb[:release]" do
        plugin.run
        expect(plugin[:platform_version]).to eq("18.04")
      end

      it "sets platform to ubuntu and platform_family to debian [:lsb][:id] contains Ubuntu" do
        plugin[:lsb][:id] = "Ubuntu"
        plugin.run
        expect(plugin[:platform]).to eq("ubuntu")
        expect(plugin[:platform_family]).to eq("debian")
      end

      it "sets platform to debian and platform_family to debian [:lsb][:id] contains Debian" do
        plugin[:lsb][:id] = "Debian"
        plugin.run
        expect(plugin[:platform]).to eq("debian")
        expect(plugin[:platform_family]).to eq("debian")
      end

      it "sets platform to redhat and platform_family to rhel when [:lsb][:id] contains Redhat" do
        plugin[:lsb][:id] = "RedHatEnterpriseServer"
        plugin[:lsb][:release] = "7.5"
        plugin.run
        expect(plugin[:platform]).to eq("redhat")
        expect(plugin[:platform_family]).to eq("rhel")
      end

      it "sets platform to amazon and platform_family to rhel when [:lsb][:id] contains Amazon" do
        plugin[:lsb][:id] = "AmazonAMI"
        plugin[:lsb][:release] = "2018.03"
        plugin.run
        expect(plugin[:platform]).to eq("amazon")
        expect(plugin[:platform_family]).to eq("amazon")
      end

      it "sets platform to scientific when [:lsb][:id] contains ScientificSL" do
        plugin[:lsb][:id] = "ScientificSL"
        plugin[:lsb][:release] = "7.5"
        plugin.run
        expect(plugin[:platform]).to eq("scientific")
      end

      it "sets platform to ibm_powerkvm and platform_family to rhel when [:lsb][:id] contains IBM_PowerKVM" do
        plugin[:lsb][:id] = "IBM_PowerKVM"
        plugin[:lsb][:release] = "2.1"
        plugin.run
        expect(plugin[:platform]).to eq("ibm_powerkvm")
        expect(plugin[:platform_family]).to eq("rhel")
      end
    end

    describe "on debian" do

      let(:have_debian_version) { true }

      before do
        plugin.lsb = nil
      end

      it "reads the version from /etc/debian_version" do
        expect(File).to receive(:read).with("/etc/debian_version").and_return("9.5")
        plugin.run
        expect(plugin[:platform_version]).to eq("9.5")
      end

      it "correctlies strip any newlines" do
        expect(File).to receive(:read).with("/etc/debian_version").and_return("9.5\n")
        plugin.run
        expect(plugin[:platform_version]).to eq("9.5")
      end

      # Ubuntu has /etc/debian_version as well
      it "detects Ubuntu as itself rather than debian" do
        plugin[:lsb][:id] = "Ubuntu"
        plugin[:lsb][:release] = "18.04"
        plugin.run
        expect(plugin[:platform]).to eq("ubuntu")
      end
    end

    describe "on slackware" do

      let(:have_slackware_version) { true }

      before do
        plugin.lsb = nil
      end

      it "sets platform and platform_family to slackware" do
        expect(File).to receive(:read).with("/etc/slackware-version").and_return("Slackware 12.0.0")
        plugin.run
        expect(plugin[:platform]).to eq("slackware")
        expect(plugin[:platform_family]).to eq("slackware")
      end

      it "sets platform_version on slackware" do
        expect(File).to receive(:read).with("/etc/slackware-version").and_return("Slackware 12.0.0")
        plugin.run
        expect(plugin[:platform_version]).to eq("12.0.0")
      end
    end

    describe "on arista eos" do

      let(:have_system_release) { true }
      let(:have_redhat_release) { true }
      let(:have_eos_release) { true }

      before do
        plugin.lsb = nil
      end

      it "sets platform to arista_eos" do
        expect(File).to receive(:read).with("/etc/Eos-release").and_return("Arista Networks EOS 4.21.1.1F")
        plugin.run
        expect(plugin[:platform]).to eq("arista_eos")
        expect(plugin[:platform_family]).to eq("fedora")
        expect(plugin[:platform_version]).to eq("4.21.1.1F")
      end
    end

    describe "on f5 big-ip" do

      let(:have_f5_release) { true }

      before do
        plugin.lsb = nil
      end

      it "sets platform to bigip" do
        expect(File).to receive(:read).with("/etc/f5-release").and_return("BIG-IP release 13.0.0 (Final)")
        plugin.run
        expect(plugin[:platform]).to eq("bigip")
        expect(plugin[:platform_family]).to eq("rhel")
        expect(plugin[:platform_version]).to eq("13.0.0")
      end
    end

    describe "on exherbo" do

      let(:have_exherbo_release) { true }

      before do
        allow(plugin).to receive(:shell_out).with("/bin/uname -r").and_return(mock_shell_out(0, "3.18.2-2-ARCH\n", ""))
        plugin.lsb = nil
      end

      it "sets platform and platform_family to exherbo" do
        plugin.run
        expect(plugin[:platform]).to eq("exherbo")
        expect(plugin[:platform_family]).to eq("exherbo")
      end

      it "sets platform_version to kernel release" do
        plugin.run
        expect(plugin[:platform_version]).to eq("3.18.2-2-ARCH")
      end

    end

    describe "on redhat breeds" do
      describe "with lsb_release results" do
        it "sets the platform to redhat and platform_family to rhel even if the LSB name is something absurd but redhat like" do
          plugin[:lsb][:id] = "RedHatEnterpriseServer"
          plugin[:lsb][:release] = "7.5"
          plugin.run
          expect(plugin[:platform]).to eq("redhat")
          expect(plugin[:platform_version]).to eq("7.5")
          expect(plugin[:platform_family]).to eq("rhel")
        end

        it "sets the platform to centos and platform_family to rhel" do
          plugin[:lsb][:id] = "CentOS"
          plugin[:lsb][:release] = "7.5"
          plugin.run
          expect(plugin[:platform]).to eq("centos")
          expect(plugin[:platform_version]).to eq("7.5")
          expect(plugin[:platform_family]).to eq("rhel")
        end
      end

      describe "without lsb_release results" do

        let(:have_redhat_release) { true }

        before do
          plugin.lsb = nil
        end

        it "reads the platform as centos and version as 7.5" do
          expect(File).to receive(:read).with("/etc/redhat-release").and_return("CentOS Linux release 7.5.1804 (Core)")
          plugin.run
          expect(plugin[:platform]).to eq("centos")
          expect(plugin[:platform_version]).to eq("7.5.1804")
        end

        it "reads platform of Red Hat with a space" do
          expect(File).to receive(:read).with("/etc/redhat-release").and_return("Red Hat Enterprise Linux Server release 6.5 (Santiago)")
          plugin.run
          expect(plugin[:platform]).to eq("redhat")
        end

        it "reads the platform as redhat without a space" do
          expect(File).to receive(:read).with("/etc/redhat-release").and_return("RedHat release 5.3")
          plugin.run
          expect(plugin[:platform]).to eq("redhat")
          expect(plugin[:platform_version]).to eq("5.3")
        end
      end

    end

    describe "on pcs linux" do

      let(:have_redhat_release) { true }
      let(:have_parallels_release) { true }

      describe "with lsb_result" do

        it "reads the platform as parallels and version as 6.0.5" do
          plugin[:lsb][:id] = "CloudLinuxServer"
          plugin[:lsb][:release] = "6.5"
          allow(File).to receive(:read).with("/etc/redhat-release").and_return("CloudLinux Server release 6.5 (Pavel Popovich)")
          expect(File).to receive(:read).with("/etc/parallels-release").and_return("Parallels Cloud Server 6.0.5 (20007)")
          plugin.run
          expect(plugin[:platform]).to eq("parallels")
          expect(plugin[:platform_version]).to eq("6.0.5")
          expect(plugin[:platform_family]).to eq("rhel")
        end
      end

      describe "without lsb_results" do

        before do
          plugin.lsb = nil
        end

        it "reads the platform as parallels and version as 6.0.5" do
          allow(File).to receive(:read).with("/etc/redhat-release").and_return("CloudLinux Server release 6.5 (Pavel Popovich)")
          expect(File).to receive(:read).with("/etc/parallels-release").and_return("Parallels Cloud Server 6.0.5 (20007)")
          plugin.run
          expect(plugin[:platform]).to eq("parallels")
          expect(plugin[:platform_version]).to eq("6.0.5")
          expect(plugin[:platform_family]).to eq("rhel")
        end
      end
    end

    describe "on oracle enterprise linux" do

      let(:have_redhat_release) { true }

      context "with lsb_results" do

        context "on version 5.x" do

          let(:have_enterprise_release) { true }

          it "reads the platform as oracle and version as 5.7" do
            plugin[:lsb][:id] = "EnterpriseEnterpriseServer"
            plugin[:lsb][:release] = "5.7"
            allow(File).to receive(:read).with("/etc/redhat-release").and_return("Red Hat Enterprise Linux Server release 5.7 (Tikanga)")
            expect(File).to receive(:read).with("/etc/enterprise-release").and_return("Enterprise Linux Enterprise Linux Server release 5.7 (Carthage)")
            plugin.run
            expect(plugin[:platform]).to eq("oracle")
            expect(plugin[:platform_version]).to eq("5.7")
          end
        end

        context "on version 6.x" do

          let(:have_oracle_release) { true }

          it "reads the platform as oracle and version as 6.1" do
            plugin[:lsb][:id] = "OracleServer"
            plugin[:lsb][:release] = "6.1"
            allow(File).to receive(:read).with("/etc/redhat-release").and_return("Red Hat Enterprise Linux Server release 6.1 (Santiago)")
            expect(File).to receive(:read).with("/etc/oracle-release").and_return("Oracle Linux Server release 6.1")
            plugin.run
            expect(plugin[:platform]).to eq("oracle")
            expect(plugin[:platform_version]).to eq("6.1")
          end

        end
      end

      context "without lsb_results" do
        before do
          plugin.lsb = nil
        end

        context "on version 5.x" do

          let(:have_enterprise_release) { true }

          it "reads the platform as oracle and version as 5" do
            allow(File).to receive(:read).with("/etc/redhat-release").and_return("Enterprise Linux Enterprise Linux Server release 5 (Carthage)")
            expect(File).to receive(:read).with("/etc/enterprise-release").and_return("Enterprise Linux Enterprise Linux Server release 5 (Carthage)")
            plugin.run
            expect(plugin[:platform]).to eq("oracle")
            expect(plugin[:platform_version]).to eq("5")
          end

          it "reads the platform as oracle and version as 5.1" do
            allow(File).to receive(:read).with("/etc/redhat-release").and_return("Enterprise Linux Enterprise Linux Server release 5.1 (Carthage)")
            expect(File).to receive(:read).with("/etc/enterprise-release").and_return("Enterprise Linux Enterprise Linux Server release 5.1 (Carthage)")
            plugin.run
            expect(plugin[:platform]).to eq("oracle")
            expect(plugin[:platform_version]).to eq("5.1")
          end

          it "reads the platform as oracle and version as 5.7" do
            allow(File).to receive(:read).with("/etc/redhat-release").and_return("Red Hat Enterprise Linux Server release 5.7 (Tikanga)")
            expect(File).to receive(:read).with("/etc/enterprise-release").and_return("Enterprise Linux Enterprise Linux Server release 5.7 (Carthage)")
            plugin.run
            expect(plugin[:platform]).to eq("oracle")
            expect(plugin[:platform_version]).to eq("5.7")
          end

        end

        context "on version 6.x" do

          let(:have_oracle_release) { true }

          it "reads the platform as oracle and version as 6.0" do
            allow(File).to receive(:read).with("/etc/redhat-release").and_return("Red Hat Enterprise Linux Server release 6.0 (Santiago)")
            expect(File).to receive(:read).with("/etc/oracle-release").and_return("Oracle Linux Server release 6.0")
            plugin.run
            expect(plugin[:platform]).to eq("oracle")
            expect(plugin[:platform_version]).to eq("6.0")
          end

          it "reads the platform as oracle and version as 6.1" do
            allow(File).to receive(:read).with("/etc/redhat-release").and_return("Red Hat Enterprise Linux Server release 6.1 (Santiago)")
            expect(File).to receive(:read).with("/etc/oracle-release").and_return("Oracle Linux Server release 6.1")
            plugin.run
            expect(plugin[:platform]).to eq("oracle")
            expect(plugin[:platform_version]).to eq("6.1")
          end
        end
      end
    end

    describe "on suse" do
      context "on versions that have no /etc/os-release but /etc/SuSE-release (e.g. SLES12.1)" do
        let(:have_suse_release) { true }
        let(:have_os_release) { false }

        describe "with lsb_release results" do
          before do
            plugin[:lsb][:id] = "SUSE LINUX"
          end

          it "reads the platform as opensuse on openSUSE" do
            plugin[:lsb][:release] = "12.1"
            expect(File).to receive(:read).with("/etc/SuSE-release").and_return("openSUSE 12.1 (x86_64)\nVERSION = 12.1\nCODENAME = Asparagus\n")
            plugin.run
            expect(plugin[:platform]).to eq("opensuse")
            expect(plugin[:platform_family]).to eq("suse")
          end
        end
      end

      context "on openSUSE and older SLES versions" do
        let(:have_suse_release) { true }

        describe "without lsb_release results" do
          before do
            plugin.lsb = nil
          end

          it "sets platform and platform_family to suse and bogus verion to 10.0" do
            expect(File).to receive(:read).with("/etc/SuSE-release").at_least(:once).and_return("VERSION = 10.0")
            plugin.run
            expect(plugin[:platform]).to eq("suse")
            expect(plugin[:platform_family]).to eq("suse")
          end

          it "reads the version as 11.2" do
            expect(File).to receive(:read).with("/etc/SuSE-release").and_return("SUSE Linux Enterprise Server 11.2 (i586)\nVERSION = 11\nPATCHLEVEL = 2\n")
            plugin.run
            expect(plugin[:platform]).to eq("suse")
            expect(plugin[:platform_version]).to eq("11.2")
            expect(plugin[:platform_family]).to eq("suse")
          end

          it "[OHAI-272] should read the version as 11.3" do
            expect(File).to receive(:read).with("/etc/SuSE-release").exactly(1).times.and_return("openSUSE 11.3 (x86_64)\nVERSION = 11.3")
            plugin.run
            expect(plugin[:platform]).to eq("opensuse")
            expect(plugin[:platform_version]).to eq("11.3")
            expect(plugin[:platform_family]).to eq("suse")
          end

          it "[OHAI-272] should read the version as 11.4" do
            expect(File).to receive(:read).with("/etc/SuSE-release").exactly(1).times.and_return("openSUSE 11.4 (i586)\nVERSION = 11.4\nCODENAME = Celadon")
            plugin.run
            expect(plugin[:platform]).to eq("opensuse")
            expect(plugin[:platform_version]).to eq("11.4")
            expect(plugin[:platform_family]).to eq("suse")
          end

          it "reads the platform as opensuse on openSUSE" do
            expect(File).to receive(:read).with("/etc/SuSE-release").and_return("openSUSE 12.2 (x86_64)\nVERSION = 12.2\nCODENAME = Mantis\n")
            plugin.run
            expect(plugin[:platform]).to eq("opensuse")
            expect(plugin[:platform_family]).to eq("suse")
          end

          it "reads the platform as opensuseleap on openSUSE Leap" do
            expect(File).to receive(:read).with("/etc/SuSE-release").and_return("openSUSE 42.1 (x86_64)\nVERSION = 42.1\nCODENAME = Malachite\n")
            plugin.run
            expect(plugin[:platform]).to eq("opensuseleap")
            expect(plugin[:platform_family]).to eq("suse")
          end
        end
      end
    end

    describe "on clearlinux" do
      let(:have_usr_lib_os_release) { true }
      let(:usr_lib_os_release_content) do
        <<~CLEARLINUX_RELEASE
          NAME="Clear Linux OS"
          VERSION=1
          ID=clear-linux-os
          ID_LIKE=clear-linux-os
          VERSION_ID=26290
          PRETTY_NAME="Clear Linux OS"
        CLEARLINUX_RELEASE
      end

      before do
        expect(File).to receive(:read).with("/usr/lib/os-release").and_return(usr_lib_os_release_content)
      end

      it "sets platform to clearlinux and platform_family to clearlinux" do
        plugin.lsb = nil
        plugin.run
        expect(plugin[:platform]).to eq("clearlinux")
        expect(plugin[:platform_family]).to eq("clearlinux")
        expect(plugin[:platform_version]).to eq("26290")
      end
    end
  end
end
