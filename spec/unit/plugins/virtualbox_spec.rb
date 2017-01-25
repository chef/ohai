# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../../spec_helper.rb"

vbox_output = <<EOF
Oracle VM VirtualBox Guest Additions Command Line Management Interface Version 5.0.2
(C) 2008-2015 Oracle Corporation
All rights reserved.

Name: /VirtualBox/GuestInfo/OS/Product, value: Linux, timestamp: 1448390422246549000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/0/V4/IP, value: 10.0.2.15, timestamp: 1448390422248366000, flags: <NULL>
Name: /VirtualBox/HostInfo/GUI/LanguageID, value: en_US, timestamp: 1448390412061749000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/0/MAC, value: 080027FBB38C, timestamp: 1448390422248652000, flags: <NULL>
Name: /VirtualBox/GuestInfo/OS/ServicePack, value: <NULL>, timestamp: 1448390422246976000, flags: <NULL>
Name: /VirtualBox/HostInfo/VBoxVerExt, value: 5.0.10, timestamp: 1448390411701508000, flags: TRANSIENT, RDONLYGUEST
Name: /VirtualBox/GuestInfo/Net/0/V4/Netmask, value: 255.255.255.0, timestamp: 1448390422248569000, flags: <NULL>
Name: /VirtualBox/GuestInfo/OS/Version, value: #36~14.04.1-Ubuntu SMP Thu Oct 8 10:21:08 UTC 2015, timestamp: 1448390422246810000, flags: <NULL>
Name: /VirtualBox/GuestAdd/VersionExt, value: 5.0.2, timestamp: 1448390422247220000, flags: <NULL>
Name: /VirtualBox/GuestAdd/Revision, value: 102096, timestamp: 1448390422247266000, flags: <NULL>
Name: /VirtualBox/HostGuest/SysprepExec, value: <NULL>, timestamp: 1448390411701168000, flags: TRANSIENT, RDONLYGUEST
Name: /VirtualBox/GuestInfo/OS/LoggedInUsers, value: 1, timestamp: 1448390452251425000, flags: TRANSIENT, TRANSRESET
Name: /VirtualBox/GuestInfo/Net/0/Status, value: Up, timestamp: 1448390422248755000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/0/Name, value: eth0, timestamp: 1448390422248814000, flags: <NULL>
Name: /VirtualBox/HostGuest/SysprepArgs, value: <NULL>, timestamp: 1448390411701220000, flags: TRANSIENT, RDONLYGUEST
Name: /VirtualBox/GuestAdd/Version, value: 5.0.2, timestamp: 1448390422247066000, flags: <NULL>
Name: /VirtualBox/HostInfo/VBoxRev, value: 104061, timestamp: 1448390411701536000, flags: TRANSIENT, RDONLYGUEST
Name: /VirtualBox/GuestInfo/Net/0/V4/Broadcast, value: 10.0.2.255, timestamp: 1448390422248498000, flags: <NULL>
Name: /VirtualBox/HostInfo/VBoxVer, value: 5.0.10, timestamp: 1448390411701485000, flags: TRANSIENT, RDONLYGUEST
Name: /VirtualBox/GuestInfo/OS/LoggedInUsersList, value: tim, timestamp: 1448390452251274000, flags: TRANSIENT, TRANSRESET
Name: /VirtualBox/GuestInfo/Net/Count, value: 1, timestamp: 1448391352440445000, flags: <NULL>
Name: /VirtualBox/GuestInfo/OS/Release, value: 3.19.0-31-generic, timestamp: 1448390422246638000, flags: <NULL>
Name: /VirtualBox/GuestInfo/OS/NoLoggedInUsers, value: false, timestamp: 1448390452251532000, flags: TRANSIENT, TRANSRESET
EOF

describe Ohai::System, "plugin virtualbox" do
  context "when VBoxControl shellout fails" do
    it "should not set the virtualbox attribute" do
      plugin = get_plugin("virtualbox")
      allow(plugin).to receive(:shell_out).with("VBoxControl guestproperty enumerate").and_return(mock_shell_out(1, "", ""))
      plugin.run
      expect(plugin).not_to have_key(:virtualbox)
    end
  end

  context "when VBoxControl shellout succeeds" do
    let(:plugin) { get_plugin("virtualbox") }

    before(:each) do
      allow(plugin).to receive(:shell_out).with("VBoxControl guestproperty enumerate").and_return(mock_shell_out(0, vbox_output, ""))
      plugin.run
    end

    it "should set the host version" do
      expect(plugin[:virtualbox][:host][:version]).to eql("5.0.10")
    end

    it "should set the host revision" do
      expect(plugin[:virtualbox][:host][:revision]).to eql("104061")
    end

    it "should set the host language" do
      expect(plugin[:virtualbox][:host][:language]).to eql("en_US")
    end

    it "should set the guest additions version" do
      expect(plugin[:virtualbox][:guest][:guest_additions_version]).to eql("5.0.2")
    end

    it "should set the guest additions revision" do
      expect(plugin[:virtualbox][:guest][:guest_additions_revision]).to eql("102096")
    end
  end
end
