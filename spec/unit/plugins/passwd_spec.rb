#
# License:: Apache License, Version 2.0
# Copyright:: Copyright (c) Chef Software Inc.
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
require "json"

describe Ohai::System, "plugin etc" do
  context "when on posix", :unix_only do
    let(:plugin) { get_plugin("passwd") }

    PasswdEntry = Struct.new(:name, :uid, :gid, :dir, :shell, :gecos)
    GroupEntry = Struct.new(:name, :gid, :mem)

    it "includes a list of all users" do
      expect(Etc).to receive(:passwd).and_yield(PasswdEntry.new("root", 1, 1, "/root", "/bin/zsh", "BOFH"))
        .and_yield(PasswdEntry.new("www", 800, 800, "/var/www", "/bin/false", "Serving the web since 1970"))
      plugin.run
      expect(plugin[:etc][:passwd]["root"]).to eq(Mash.new(shell: "/bin/zsh", gecos: "BOFH", gid: 1, uid: 1, dir: "/root"))
      expect(plugin[:etc][:passwd]["www"]).to eq(Mash.new(shell: "/bin/false", gecos: "Serving the web since 1970", gid: 800, uid: 800, dir: "/var/www"))
    end

    it "ignores duplicate users" do
      expect(Etc).to receive(:passwd).and_yield(PasswdEntry.new("root", 1, 1, "/root", "/bin/zsh", "BOFH"))
        .and_yield(PasswdEntry.new("root", 1, 1, "/", "/bin/false", "I do not belong"))
      plugin.run
      expect(plugin[:etc][:passwd]["root"]).to eq(Mash.new(shell: "/bin/zsh", gecos: "BOFH", gid: 1, uid: 1, dir: "/root"))
    end

    it "sets the current user" do
      expect(Process).to receive(:euid).and_return("31337")
      expect(Etc).to receive(:getpwuid).and_return(PasswdEntry.new("chef", 31337, 31337, "/home/chef", "/bin/ksh", "Julia Child"))
      plugin.run
      expect(plugin[:current_user]).to eq("chef")
    end

    it "sets the available groups" do
      expect(Etc).to receive(:group).and_yield(GroupEntry.new("admin", 100, %w{root chef})).and_yield(GroupEntry.new("www", 800, %w{www deploy}))
      plugin.run
      expect(plugin[:etc][:group]["admin"]).to eq(Mash.new(gid: 100, members: %w{root chef}))
      expect(plugin[:etc][:group]["www"]).to eq(Mash.new(gid: 800, members: %w{www deploy}))
    end

    if "".respond_to?(:force_encoding)
      it "sets the encoding of strings to the default external encoding" do
        fields = ["root", 1, 1, "/root", "/bin/zsh", "BOFH"]
        fields.each { |f| f.force_encoding(Encoding::ASCII_8BIT) if f.respond_to?(:force_encoding) }
        allow(Etc).to receive(:passwd).and_yield(PasswdEntry.new(*fields))
        plugin.run
        root = plugin[:etc][:passwd]["root"]
        expect(root["gecos"].encoding).to eq(Encoding.default_external)
      end
    end
  end

  context "when on windows", :windows_only do
    let(:plugin) do
      get_plugin("passwd").tap do |plugin|
        plugin[:platform_family] = "windows"
      end
    end

    USERS = [
      {
        "AccountType" => 512,
        "Disabled" => false,
        "Name" => "userone",
        "FullName" => "User One",
        "SID" => "bla bla bla",
        "SIDType" => 1,
        "Status" => "OK",
      },
      {
        "AccountType" => 512,
        "Disabled" => false,
        "FullName" => "User Two",
        "Name" => "usertwo",
        "SID" => "bla bla bla2",
        "SIDType" => 1,
        "Status" => "OK",
      },
    ].freeze

    GROUPS = [
      {
        "Description" => "Group One",
        "Domain" => "THIS-MACHINE",
        "Name" => "GroupOne",
        "SID" => "foo foo foo",
        "SidType" => 4,
        "Status" => "OK",
      },
      {
        "Description" => "Group Two",
        "Domain" => "THIS-MACHINE",
        "Name" => "GroupTwo",
        "SID" => "foo foo foo2",
        "SidType" => 4,
        "Status" => "OK",
      },
    ].freeze

    GROUP_ONE_MEMBERS = [
      {
        "groupcomponent" => "Win32_Group.Domain=\"THIS-MACHINE\",Name=\"GroupOne\"",
        "partcomponent" => "\\\\VCRS-PRODWIN05\\root\\cimv2:Win32_UserAccount.Domain=\"THIS-MACHINE\",Name=\"UserOne\"",
      },
      {
        "groupcomponent" => "Win32_Group.Domain=\"THIS-MACHINE\",Name=\"GroupOne\"",
        "partcomponent" => "\\\\VCRS-PRODWIN05\\root\\cimv2:Win32_UserAccount.Domain=\"THIS-MACHINE\",Name=\"UserTwo\"",
      },
    ].freeze

    GROUP_TWO_MEMBERS = [
      {
        "groupcomponent" => "Win32_Group.Domain=\"THIS-MACHINE\",Name=\"GroupOne\"",
        "partcomponent" => "\\\\VCRS-PRODWIN05\\root\\cimv2:Win32_SystemAccount.Domain=\"THIS-MACHINE\",Name=\"GroupOne\"",
      },
    ].freeze

    before do
      require "wmi-lite/wmi" unless defined?(WmiLite::Wmi)
      properties = USERS[0].map { |k, v| double(name: k) }
      wmi_user_list = USERS.map do |user|
        wmi_ole_object = double properties_: properties
        user.each do |key, val|
          allow(wmi_ole_object).to receive(:invoke).with(key).and_return(val)
        end
        WmiLite::Wmi::Instance.new(wmi_ole_object)
      end
      allow_any_instance_of(WmiLite::Wmi).to receive(:query)
        .with("SELECT * FROM Win32_UserAccount WHERE LocalAccount = True")
        .and_return(wmi_user_list)

      properties = GROUPS[0].map { |k, v| double(name: k) }
      wmi_group_list = GROUPS.map do |group|
        wmi_ole_object = double properties_: properties
        group.each do |key, val|
          allow(wmi_ole_object).to receive(:invoke).with(key).and_return(val)
        end
        WmiLite::Wmi::Instance.new(wmi_ole_object)
      end
      allow_any_instance_of(WmiLite::Wmi).to receive(:query)
        .with("SELECT * FROM Win32_Group WHERE LocalAccount = True")
        .and_return(wmi_group_list)

    end

    def transform(user_data)
      Hash[
        user_data.map do |key, val|
          [key.downcase, val]
        end
      ]
    end

    it "returns lower-cased passwd keys for each local user" do
      allow_any_instance_of(WmiLite::Wmi).to receive(:query)
        .with("SELECT * FROM Win32_GroupUser WHERE GroupComponent=\"Win32_Group.Domain='THIS-MACHINE',Name='GroupOne'\"")
        .and_return([])

      allow_any_instance_of(WmiLite::Wmi).to receive(:query)
        .with("SELECT * FROM Win32_GroupUser WHERE GroupComponent=\"Win32_Group.Domain='THIS-MACHINE',Name='GroupTwo'\"")
        .and_return([])

      plugin.run
      expect(plugin[:etc][:passwd].keys.sort).to eq(%w{userone usertwo}.sort)
    end

    it "returns preserved-case passwd entries for local users" do
      allow_any_instance_of(WmiLite::Wmi).to receive(:query)
        .with("SELECT * FROM Win32_GroupUser WHERE GroupComponent=\"Win32_Group.Domain='THIS-MACHINE',Name='GroupOne'\"")
        .and_return([])

      allow_any_instance_of(WmiLite::Wmi).to receive(:query)
        .with("SELECT * FROM Win32_GroupUser WHERE GroupComponent=\"Win32_Group.Domain='THIS-MACHINE',Name='GroupTwo'\"")
        .and_return([])

      plugin.run
      expect(plugin[:etc][:passwd]["userone"]).to eq(transform(USERS[0]))
    end

    it "returns lower-cased group entries for each local group" do
      allow_any_instance_of(WmiLite::Wmi).to receive(:query)
        .with("SELECT * FROM Win32_GroupUser WHERE GroupComponent=\"Win32_Group.Domain='THIS-MACHINE',Name='GroupOne'\"")
        .and_return([])

      allow_any_instance_of(WmiLite::Wmi).to receive(:query)
        .with("SELECT * FROM Win32_GroupUser WHERE GroupComponent=\"Win32_Group.Domain='THIS-MACHINE',Name='GroupTwo'\"")
        .and_return([])

      plugin.run
      expect(plugin[:etc][:group].keys.sort).to eq(%w{groupone grouptwo}.sort)
    end

    it "returns preserved-cased group entries for local groups" do
      allow_any_instance_of(WmiLite::Wmi).to receive(:query)
        .with("SELECT * FROM Win32_GroupUser WHERE GroupComponent=\"Win32_Group.Domain='THIS-MACHINE',Name='GroupOne'\"")
        .and_return([])

      allow_any_instance_of(WmiLite::Wmi).to receive(:query)
        .with("SELECT * FROM Win32_GroupUser WHERE GroupComponent=\"Win32_Group.Domain='THIS-MACHINE',Name='GroupTwo'\"")
        .and_return([])

      plugin.run
      expect(plugin[:etc][:group]["grouptwo"]).to eq(
        transform(GROUPS[1]).merge({ "members" => [] })
      )
    end

    it "returns members for groups" do
      properties = GROUP_ONE_MEMBERS[0].map { |k, v| double(name: k) }
      g1_members = GROUP_ONE_MEMBERS.map do |member|
        wmi_ole_object = double properties_: properties
        member.each do |key, val|
          allow(wmi_ole_object).to receive(:invoke).with(key).and_return(val)
        end
        WmiLite::Wmi::Instance.new(wmi_ole_object)
      end
      allow_any_instance_of(WmiLite::Wmi).to receive(:query)
        .with("SELECT * FROM Win32_GroupUser WHERE GroupComponent=\"Win32_Group.Domain='THIS-MACHINE',Name='GroupOne'\"")
        .and_return(g1_members)

      g2_members = GROUP_TWO_MEMBERS.map do |member|
        wmi_ole_object = double properties_: properties
        member.each do |key, val|
          allow(wmi_ole_object).to receive(:invoke).with(key).and_return(val)
        end
        WmiLite::Wmi::Instance.new(wmi_ole_object)
      end
      allow_any_instance_of(WmiLite::Wmi).to receive(:query)
        .with("SELECT * FROM Win32_GroupUser WHERE GroupComponent=\"Win32_Group.Domain='THIS-MACHINE',Name='GroupTwo'\"")
        .and_return(g2_members)

      plugin.run
      expect(plugin[:etc][:group]["groupone"]["members"]).to eq([
        { "name" => "UserOne", "type" => :user },
        { "name" => "UserTwo", "type" => :user },
      ])
      expect(plugin[:etc][:group]["grouptwo"]["members"]).to eq([
        { "name" => "GroupOne", "type" => :group },
      ])
    end
  end
end
