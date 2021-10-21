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

describe Ohai::System, "Linux hostname plugin" do
  before do
    @plugin = get_plugin("hostname")
    allow(@plugin).to receive(:collect_os).and_return(:linux)
    allow(@plugin).to receive(:shell_out).with("hostname -s").and_return(mock_shell_out(0, "katie", ""))
    allow(@plugin).to receive(:canonicalize_hostname).with("katie.local").and_return("katie.bethell")
    allow(@plugin).to receive(:shell_out).with("hostname").and_return(mock_shell_out(0, "katie.local", ""))
  end

  it_should_check_from("linux::hostname", "hostname", "hostname -s", "katie")

  it_should_check_from("linux::hostname", "fqdn", "hostname --fqdn", "katie.bethell")

  it_should_check_from("linux::hostname", "machinename", "hostname", "katie.local")

  describe "when domain name is unset" do
    before do
      allow(@plugin).to receive(:canonicalize_hostname).with("katie.local").and_raise(RuntimeError)
    end

    it "does not raise an error" do
      expect { @plugin.run }.not_to raise_error
    end

    it "does not set fqdn" do
      @plugin.run
      expect(@plugin.fqdn).to eq(nil)
    end

  end

end
