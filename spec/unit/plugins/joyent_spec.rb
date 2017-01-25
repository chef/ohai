#
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

require_relative "../../spec_helper.rb"

describe Ohai::System, "plugin joyent" do
  let(:plugin) { get_plugin("joyent") }

  describe "without joyent" do
    before(:each) do
      allow(plugin).to receive(:is_smartos?).and_return(false)
    end

    it "DOES NOT create joyent mash" do
      plugin.run
      expect(plugin[:joyent]).to be_nil
    end
  end

  describe "with joyent" do
    before(:each) do
      allow(plugin).to receive(:is_smartos?).and_return(true)
      plugin[:virtualization] = Mash.new
      plugin[:virtualization][:guest_uuid] = "global"
    end

    it "creates joyent mash" do
      plugin.run
      expect(plugin[:joyent]).not_to be_nil
    end

    describe "under global zone" do
      before(:each) do
        plugin.run
      end

      it "detects global zone" do
        expect(plugin[:joyent][:sm_uuid]).to eql "global"
      end

      it "DOES NOT create sm_id" do
        expect(plugin[:joyent][:sm_id]).to be_nil
      end
    end

    describe "under smartmachine" do
      before(:each) do
        plugin[:virtualization][:guest_uuid] = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx"
        plugin[:virtualization][:guest_id] = "30"

        etc_product = <<-EOS
Name: Joyent Instance
Image: pkgbuild 16.3.1
Documentation: https://docs.joyent.com/images/smartos/pkgbuild
      EOS

        pkg_install_conf = <<-EOS
GPG_KEYRING_VERIFY=/opt/local/etc/gnupg/pkgsrc.gpg
GPG_KEYRING_PKGVULN=/opt/local/share/gnupg/pkgsrc-security.gpg
PKG_PATH=https://pkgsrc.joyent.com/packages/SmartOS/2016Q3/x86_64/All
VERIFIED_INSTALLATION=trusted
      EOS

        allow(::File).to receive(:read).with("/etc/product").and_return(etc_product)
        allow(::File).to receive(:read).with("/opt/local/etc/pkg_install.conf").and_return(pkg_install_conf)
        plugin.run
      end

      it "retrieves zone uuid" do
        expect(plugin[:joyent][:sm_uuid]).to eql "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx"
      end

      it "collects sm_id" do
        expect(plugin[:joyent][:sm_id]).to eql "30"
      end

      it "collects images" do
        expect(plugin[:joyent][:sm_image_id]).to eql "pkgbuild"
        expect(plugin[:joyent][:sm_image_ver]).to eql "16.3.1"
      end

      it "collects pkgsrc" do
        expect(plugin[:joyent][:sm_pkgsrc]).to eql "https://pkgsrc.joyent.com/packages/SmartOS/2016Q3/x86_64/All"
      end
    end
  end
end
