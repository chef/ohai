#
# Author:: Lance Albertson <lance@osuosl.org>
# Copyright:: Copyright (c) 2021 Oregon State University
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

describe Ohai::System, "Linux os_release plugin" do
  let(:plugin) { get_plugin("linux/os_release") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  let(:os_release_debian) do
    <<~OS_RELEASE
      PRETTY_NAME="Debian GNU/Linux 10 (buster)"
      NAME="Debian GNU/Linux"
      VERSION_ID="10"
      VERSION="10 (buster)"
      VERSION_CODENAME=buster
      ID=debian
      HOME_URL="https://www.debian.org/"
      SUPPORT_URL="https://www.debian.org/support"
      BUG_REPORT_URL="https://bugs.debian.org/"
    OS_RELEASE
  end

  let(:os_release_ubuntu) do
    <<~OS_RELEASE
      NAME="Ubuntu"
      VERSION="20.04.2 LTS (Focal Fossa)"
      ID=ubuntu
      ID_LIKE=debian
      PRETTY_NAME="Ubuntu 20.04.2 LTS"
      VERSION_ID="20.04"
      HOME_URL="https://www.ubuntu.com/"
      SUPPORT_URL="https://help.ubuntu.com/"
      BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
      PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
      VERSION_CODENAME=focal
      UBUNTU_CODENAME=focal
    OS_RELEASE
  end

  let(:os_release_centos) do
    <<~OS_RELEASE
      NAME="CentOS Linux"
      VERSION="8"
      ID="centos"
      ID_LIKE="rhel fedora"
      VERSION_ID="8"
      PLATFORM_ID="platform:el8"
      PRETTY_NAME="CentOS Linux 8"
      ANSI_COLOR="0;31"
      CPE_NAME="cpe:/o:centos:centos:8"
      HOME_URL="https://centos.org/"
      BUG_REPORT_URL="https://bugs.centos.org/"
      CENTOS_MANTISBT_PROJECT="CentOS-8"
      CENTOS_MANTISBT_PROJECT_VERSION="8"
    OS_RELEASE
  end

  let(:os_release_amazon) do
    <<~OS_RELEASE
      NAME="Amazon Linux"
      VERSION="2"
      ID="amzn"
      ID_LIKE="centos rhel fedora"
      VERSION_ID="2"
      PRETTY_NAME="Amazon Linux 2"
      ANSI_COLOR="0;33"
      CPE_NAME="cpe:2.3:o:amazon:amazon_linux:2"
      HOME_URL="https://amazonlinux.com/"
    OS_RELEASE
  end

  let(:os_release_fedora) do
    <<~OS_RELEASE
      NAME=Fedora
      VERSION="33 (Container Image)"
      ID=fedora
      VERSION_ID=33
      VERSION_CODENAME=""
      PLATFORM_ID="platform:f33"
      PRETTY_NAME="Fedora 33 (Container Image)"
      ANSI_COLOR="0;38;2;60;110;180"
      LOGO=fedora-logo-icon
      CPE_NAME="cpe:/o:fedoraproject:fedora:33"
      HOME_URL="https://fedoraproject.org/"
      DOCUMENTATION_URL="https://docs.fedoraproject.org/en-US/fedora/f33/system-administrators-guide/"
      SUPPORT_URL="https://fedoraproject.org/wiki/Communicating_and_getting_help"
      BUG_REPORT_URL="https://bugzilla.redhat.com/"
      REDHAT_BUGZILLA_PRODUCT="Fedora"
      REDHAT_BUGZILLA_PRODUCT_VERSION=33
      REDHAT_SUPPORT_PRODUCT="Fedora"
      REDHAT_SUPPORT_PRODUCT_VERSION=33
      PRIVACY_POLICY_URL="https://fedoraproject.org/wiki/Legal:PrivacyPolicy"
      VARIANT="Container Image"
      VARIANT_ID=container
    OS_RELEASE
  end

  let(:os_release_opensuse) do
    <<~OS_RELEASE
      NAME="openSUSE Leap"
      VERSION="15.2"
      ID="opensuse-leap"
      ID_LIKE="suse opensuse"
      VERSION_ID="15.2"
      PRETTY_NAME="openSUSE Leap 15.2"
      ANSI_COLOR="0;32"
      CPE_NAME="cpe:/o:opensuse:leap:15.2"
      BUG_REPORT_URL="https://bugs.opensuse.org"
      HOME_URL="https://www.opensuse.org/"
    OS_RELEASE
  end

  it "populates os_release on debian" do
    expect(plugin).to receive(:file_exist?).at_least(:once).with("/etc/os-release").and_return(true)
    expect(plugin).to receive(:file_read).with("/etc/os-release").and_return(os_release_debian)
    plugin.run
    expect(plugin[:os_release].to_hash).to eq({
      "pretty_name" => "Debian GNU/Linux 10 (buster)",
      "name" => "Debian GNU/Linux",
      "version_id" => "10",
      "version" => "10 (buster)",
      "version_codename" => "buster",
      "id" => "debian",
      "home_url" => "https://www.debian.org/",
      "support_url" => "https://www.debian.org/support",
      "bug_report_url" => "https://bugs.debian.org/",
    })
  end

  it "populates os_release on ubuntu" do
    expect(plugin).to receive(:file_exist?).at_least(:once).with("/etc/os-release").and_return(true)
    expect(plugin).to receive(:file_read).with("/etc/os-release").and_return(os_release_ubuntu)
    plugin.run
    expect(plugin[:os_release].to_hash).to eq({
      "bug_report_url" => "https://bugs.launchpad.net/ubuntu/",
      "home_url" => "https://www.ubuntu.com/",
      "id" => "ubuntu",
      "id_like" => %w{debian},
      "name" => "Ubuntu",
      "pretty_name" => "Ubuntu 20.04.2 LTS",
      "privacy_policy_url" => "https://www.ubuntu.com/legal/terms-and-policies/privacy-policy",
      "support_url" => "https://help.ubuntu.com/",
      "ubuntu_codename" => "focal",
      "version" => "20.04.2 LTS (Focal Fossa)",
      "version_codename" => "focal",
      "version_id" => "20.04",
    })
  end

  it "populates os_release on fedora" do
    expect(plugin).to receive(:file_exist?).at_least(:once).with("/etc/os-release").and_return(true)
    expect(plugin).to receive(:file_read).with("/etc/os-release").and_return(os_release_fedora)
    plugin.run
    expect(plugin[:os_release].to_hash).to eq({
      "ansi_color" => "0;38;2;60;110;180",
      "bug_report_url" => "https://bugzilla.redhat.com/",
      "cpe_name" => "cpe:/o:fedoraproject:fedora:33",
      "documentation_url" => "https://docs.fedoraproject.org/en-US/fedora/f33/system-administrators-guide/",
      "home_url" => "https://fedoraproject.org/",
      "id" => "fedora",
      "logo" => "fedora-logo-icon",
      "name" => "Fedora",
      "platform_id" => "platform:f33",
      "pretty_name" => "Fedora 33 (Container Image)",
      "privacy_policy_url" => "https://fedoraproject.org/wiki/Legal:PrivacyPolicy",
      "redhat_bugzilla_product" => "Fedora",
      "redhat_bugzilla_product_version" => "33",
      "redhat_support_product" => "Fedora",
      "redhat_support_product_version" => "33",
      "support_url" => "https://fedoraproject.org/wiki/Communicating_and_getting_help",
      "variant" => "Container Image",
      "variant_id" => "container",
      "version" => "33 (Container Image)",
      "version_codename" => "",
      "version_id" => "33",
    })
  end

  it "populates os_release on centos" do
    expect(plugin).to receive(:file_exist?).at_least(:once).with("/etc/os-release").and_return(true)
    expect(plugin).to receive(:file_read).with("/etc/os-release").and_return(os_release_centos)
    plugin.run
    expect(plugin[:os_release].to_hash).to eq({
      "ansi_color" => "0;31",
      "bug_report_url" => "https://bugs.centos.org/",
      "centos_mantisbt_project" => "CentOS-8",
      "centos_mantisbt_project_version" => "8",
      "cpe_name" => "cpe:/o:centos:centos:8",
      "home_url" => "https://centos.org/",
      "id" => "centos",
      "id_like" => %w{rhel fedora},
      "name" => "CentOS Linux",
      "platform_id" => "platform:el8",
      "pretty_name" => "CentOS Linux 8",
      "version" => "8",
      "version_id" => "8",
    })
  end

  it "populates os_release on amazon" do
    expect(plugin).to receive(:file_exist?).at_least(:once).with("/etc/os-release").and_return(true)
    expect(plugin).to receive(:file_read).with("/etc/os-release").and_return(os_release_amazon)
    plugin.run
    expect(plugin[:os_release].to_hash).to eq({
      "ansi_color" => "0;33",
      "cpe_name" => "cpe:2.3:o:amazon:amazon_linux:2",
      "home_url" => "https://amazonlinux.com/",
      "id" => "amzn",
      "id_like" => %w{centos rhel fedora},
      "name" => "Amazon Linux",
      "pretty_name" => "Amazon Linux 2",
      "version" => "2",
      "version_id" => "2",
    })
  end

  it "populates os_release on opensuse" do
    expect(plugin).to receive(:file_exist?).at_least(:once).with("/etc/os-release").and_return(true)
    expect(plugin).to receive(:file_read).with("/etc/os-release").and_return(os_release_opensuse)
    plugin.run
    expect(plugin[:os_release].to_hash).to eq({
      "ansi_color" => "0;32",
      "bug_report_url" => "https://bugs.opensuse.org",
      "cpe_name" => "cpe:/o:opensuse:leap:15.2",
      "home_url" => "https://www.opensuse.org/",
      "id" => "opensuse-leap",
      "id_like" => %w{suse opensuse},
      "name" => "openSUSE Leap",
      "pretty_name" => "openSUSE Leap 15.2",
      "version" => "15.2",
      "version_id" => "15.2",
    })
  end

  it "does not populate os_release if /etc/os-release is not available" do
    expect(plugin).to receive(:file_exist?).at_least(:once).with("/etc/os-release").and_return(false)
    plugin.run
    expect(plugin[:os_release]).to eq({})
  end
end
