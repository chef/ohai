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

    let(:user_info) do
      [
        {
          "Name" => "UserOne",
          "FullName" => "User One",
          "SID" => {
            "BinaryLength" => 28,
            "AccountDomainSid" => "bla",
            "Value" => "blabla",
          },
          "ObjectClass" => "User",
          "Enabled" => false,
        },
        {
          "Name" => "UserTwo",
          "FullName" => "User Two",
          "SID" => {
            "BinaryLength" => 28,
            "AccountDomainSid" => "doo",
            "Value" => "doodoo",
          },
          "ObjectClass" => "User",
          "Enabled" => true,
        },
      ]
    end

    let(:group_info) do
      [
        {
          "Description" => "Group One",
          "Name" => "GroupOne",
          "SID" => {
            "BinaryLength" => 16,
            "AccountDomainSid" => nil,
            "Value" => "foo",
          },
          "ObjectClass" => "Group",
        },
        {
          "Description" => "Group Two",
          "Name" => "GroupTwo",
          "SID" => {
            "BinaryLength" => 16,
            "AccountDomainSid" => nil,
            "Value" => "foo",
          },
          "ObjectClass" => "Group",
        },
      ]
    end

    let(:group_one_info) do
      [
        {
          "Name" => "UserOne",
          "SID" => {
            "BinaryLength" => 28,
            "AccountDomainSid" => nil,
            "Value" => "bar",
          },
          "ObjectClass" => "User",
        },
        {
          "Name" => "UserTwo",
          "SID" => {
            "BinaryLength" => 28,
            "AccountDomainSid" => nil,
            "Value" => "bar",
          },
          "ObjectClass" => "User",
        },
      ]
    end

    let(:group_two_info) do
      [
        {
          "Name" => "UserTwo",
          "SID" => {
            "BinaryLength" => 28,
            "AccountDomainSid" => nil,
            "Value" => "bar",
          },
          "ObjectClass" => "User",
        },
      ]
    end

    before do
      expect(plugin).to receive(:powershell_out)
        .with("get-localuser | convertto-json")
        .and_return(mock_shell_out(0, user_info.to_json, ""))
      expect(plugin).to receive(:powershell_out)
        .with("get-localgroup | convertto-json")
        .and_return(mock_shell_out(0, group_info.to_json, ""))
    end

    def transform(user_data)
      Hash[
        user_data.map do |key, val|
          [key.downcase, val]
        end
      ]
    end

    it "returns lower-cased passwd keys for each local user" do
      {
        "groupone" => group_one_info.to_json,
        "grouptwo" => group_two_info.to_json,
      }.each do |gname, info|
        expect(plugin).to receive(:powershell_out)
          .with("get-localgroupmember -name '#{gname}' | convertto-json")
          .and_return(mock_shell_out(0, "[]", ""))
      end
      plugin.run
      expect(plugin[:etc][:passwd].keys.sort).to eq(%w{userone usertwo}.sort)
    end

    it "returns preserved-case passwd entries for local users" do
      {
        "groupone" => group_one_info.to_json,
        "grouptwo" => group_two_info.to_json,
      }.each do |gname, info|
        expect(plugin).to receive(:powershell_out)
          .with("get-localgroupmember -name '#{gname}' | convertto-json")
          .and_return(mock_shell_out(0, "[]", ""))
      end
      plugin.run
      expect(plugin[:etc][:passwd]["userone"]).to eq(transform(user_info[0]))
    end

    it "returns lower-cased group entries for each local group" do
      {
        "groupone" => group_one_info.to_json,
        "grouptwo" => group_two_info.to_json,
      }.each do |gname, info|
        expect(plugin).to receive(:powershell_out)
          .with("get-localgroupmember -name '#{gname}' | convertto-json")
          .and_return(mock_shell_out(0, "[]", ""))
      end
      plugin.run
      expect(plugin[:etc][:group].keys.sort).to eq(%w{groupone grouptwo}.sort)
    end

    it "returns preserved-cased group entries for local groups" do
      {
        "groupone" => group_one_info.to_json,
        "grouptwo" => group_two_info.to_json,
      }.each do |gname, info|
        expect(plugin).to receive(:powershell_out)
          .with("get-localgroupmember -name '#{gname}' | convertto-json")
          .and_return(mock_shell_out(0, "[]", ""))
      end
      plugin.run
      expect(plugin[:etc][:group]["grouptwo"]).to eq(
        transform(group_info[1]).merge({ "members" => [] })
      )
    end

    it "returns members for groups" do
      {
        "groupone" => group_one_info.to_json,
        "grouptwo" => group_two_info.to_json,
      }.each do |gname, info|
        expect(plugin).to receive(:powershell_out)
          .with("get-localgroupmember -name '#{gname}' | convertto-json")
          .and_return(mock_shell_out(0, info, ""))
      end
      plugin.run
      expect(plugin[:etc][:group]["groupone"]["members"]).to eq(group_one_info)
      expect(plugin[:etc][:group]["grouptwo"]["members"]).to eq(group_two_info)
    end
  end
end
