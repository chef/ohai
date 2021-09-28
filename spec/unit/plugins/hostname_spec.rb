#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
require "ohai/mixin/network_helper"

describe Ohai::System, "hostname plugin" do
  before do
    @plugin = get_plugin("hostname")
    allow(@plugin).to receive(:collect_os).and_return(:default)
    allow(@plugin).to receive(:shell_out).with("hostname").and_return(mock_shell_out(0, "katie.local", ""))
  end

  context "default behavior"
  before do
    allow(@plugin).to receive(:resolve_fqdn).and_return("katie.bethell")
  end

  it_should_check_from("linux::hostname", "machinename", "hostname", "katie.local")

  it "uses #resolve_fqdn to find the fqdn" do
    @plugin.run
    expect(@plugin[:fqdn]).to eq("katie.bethell")
  end

  it "sets the domain to everything after the first dot of the fqdn" do
    @plugin.run
    expect(@plugin[:domain]).to eq("bethell")
  end

  it "sets the [short] hostname to everything before the first dot of the fqdn" do
    @plugin.run
    expect(@plugin[:hostname]).to eq("katie")
  end

  context "when a system has a bare hostname without a FQDN" do
    before do
      allow(@plugin).to receive(:collect_os).and_return(:default)
      allow(@plugin).to receive(:shell_out).with("hostname").and_return(mock_shell_out(0, "katie", ""))
    end

    it "correctlies set the [short] hostname" do
      @plugin.run
      expect(@plugin[:hostname]).to eq("katie")
    end
  end

  context "hostname --fqdn when it returns empty string" do
    before do
      allow(@plugin).to receive(:collect_os).and_return(:linux)
      allow(@plugin).to receive(:shell_out).with("hostname -s").and_return(
        mock_shell_out(0, "katie", "")
      )
      allow(@plugin).to receive(:shell_out).with("hostname --fqdn").and_return(
        mock_shell_out(0, "", ""), mock_shell_out(0, "katie.local", "")
      )
    end

    it "is called twice" do
      @plugin.run
      expect(@plugin[:fqdn]).to eq("katie.local")
    end
  end

  context "hostname --fqdn when it works" do
    before do
      allow(@plugin).to receive(:collect_os).and_return(:linux)
      allow(@plugin).to receive(:shell_out).with("hostname -s").and_return(
        mock_shell_out(0, "katie", "")
      )
      allow(@plugin).to receive(:shell_out).with("hostname --fqdn").and_return(
        mock_shell_out(0, "katie.local", "")
      )
    end

    it "is not be called twice" do
      @plugin.run
      expect(@plugin[:fqdn]).to eq("katie.local")
    end
  end
end

describe Ohai::System, "hostname plugin for windows", :windows_only do
  let(:success) { double }

  let(:host) do
    {
      "name" => "local",
      "dnshostname" => "local",
    }
  end

  before do
    @plugin = get_plugin("hostname")
    allow(WmiLite::Wmi).to receive(:new).and_return(success)
    allow(success).to receive(:first_of).with("Win32_ComputerSystem").and_return(host)
  end

  context "when hostname is not set for the machine" do
    it "returns short machine name" do
      addr_object = Addrinfo.getaddrinfo("", nil)
      unqualified_hostname = addr_object.first.getnameinfo.first
      allow(Addrinfo).to receive(:getaddrinfo).with("local", nil).and_return(addr_object)
      @plugin.run
      expect(@plugin[:fqdn]).to eq(unqualified_hostname)
    end
  end

  context "when hostname is set for the machine" do
    it "returns the fqdn of the machine" do
      addr_object = Addrinfo.getaddrinfo("www.kame.net", nil)
      allow(Addrinfo).to receive(:getaddrinfo).with("local", nil).and_return(addr_object)
      @plugin.run
      expect(@plugin[:fqdn]).to eq("mango.itojun.org")
    end
  end
end
