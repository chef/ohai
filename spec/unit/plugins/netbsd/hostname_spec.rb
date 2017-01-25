#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "NetBSD hostname plugin" do
  before(:each) do
    @plugin = get_plugin("hostname")
    allow(@plugin).to receive(:collect_os).and_return(:netbsd)
    allow(@plugin).to receive(:shell_out).with("hostname -s").and_return(mock_shell_out(0, "katie\n", ""))
    allow(@plugin).to receive(:shell_out).with("hostname").and_return(mock_shell_out(0, "katie.local", ""))
    allow(@plugin).to receive(:resolve_fqdn).and_return("katie.bethell")
  end

  it_should_check_from("linux::hostname", "hostname", "hostname -s", "katie")

  it_should_check_from("linux::hostname", "machinename", "hostname", "katie.local")

  it "should use #resolve_fqdn to find the fqdn" do
    @plugin.run
    expect(@plugin[:fqdn]).to eq("katie.bethell")
  end

  it "should set the domain to everything after the first dot of the fqdn" do
    @plugin.run
    expect(@plugin[:domain]).to eq("bethell")
  end
end
