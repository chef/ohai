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

describe Ohai::System, "plugin etc", :unix_only do
  before(:each) do
    @plugin = get_plugin("passwd")
  end

  PasswdEntry = Struct.new(:name, :uid, :gid, :dir, :shell, :gecos)
  GroupEntry = Struct.new(:name, :gid, :mem)

  it "should include a list of all users" do
    expect(Etc).to receive(:passwd).and_yield(PasswdEntry.new("root", 1, 1, "/root", "/bin/zsh", "BOFH")).
      and_yield(PasswdEntry.new("www", 800, 800, "/var/www", "/bin/false", "Serving the web since 1970"))
    @plugin.run
    expect(@plugin[:etc][:passwd]["root"]).to eq(Mash.new(:shell => "/bin/zsh", :gecos => "BOFH", :gid => 1, :uid => 1, :dir => "/root"))
    expect(@plugin[:etc][:passwd]["www"]).to eq(Mash.new(:shell => "/bin/false", :gecos => "Serving the web since 1970", :gid => 800, :uid => 800, :dir => "/var/www"))
  end

  it "should ignore duplicate users" do
    expect(Etc).to receive(:passwd).and_yield(PasswdEntry.new("root", 1, 1, "/root", "/bin/zsh", "BOFH")).
      and_yield(PasswdEntry.new("root", 1, 1, "/", "/bin/false", "I do not belong"))
    @plugin.run
    expect(@plugin[:etc][:passwd]["root"]).to eq(Mash.new(:shell => "/bin/zsh", :gecos => "BOFH", :gid => 1, :uid => 1, :dir => "/root"))
  end

  it "should set the current user" do
    expect(Process).to receive(:euid).and_return("31337")
    expect(Etc).to receive(:getpwuid).and_return(PasswdEntry.new("chef", 31337, 31337, "/home/chef", "/bin/ksh", "Julia Child"))
    @plugin.run
    expect(@plugin[:current_user]).to eq("chef")
  end

  it "should set the available groups" do
    expect(Etc).to receive(:group).and_yield(GroupEntry.new("admin", 100, %w{root chef})).and_yield(GroupEntry.new("www", 800, %w{www deploy}))
    @plugin.run
    expect(@plugin[:etc][:group]["admin"]).to eq(Mash.new(:gid => 100, :members => %w{root chef}))
    expect(@plugin[:etc][:group]["www"]).to eq(Mash.new(:gid => 800, :members => %w{www deploy}))
  end

  if "".respond_to?(:force_encoding)
    it "sets the encoding of strings to the default external encoding" do
      fields = ["root", 1, 1, "/root", "/bin/zsh", "BOFH"]
      fields.each { |f| f.force_encoding(Encoding::ASCII_8BIT) if f.respond_to?(:force_encoding) }
      allow(Etc).to receive(:passwd).and_yield(PasswdEntry.new(*fields))
      @plugin.run
      root = @plugin[:etc][:passwd]["root"]
      expect(root["gecos"].encoding).to eq(Encoding.default_external)
    end
  end
end
