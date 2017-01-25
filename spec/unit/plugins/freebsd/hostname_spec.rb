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

describe Ohai::System, "FreeBSD hostname plugin" do
  before(:each) do
    @plugin = get_plugin("hostname")
    allow(@plugin).to receive(:collect_os).and_return(:freebsd)
    allow(@plugin).to receive(:shell_out).with("hostname -s").and_return(mock_shell_out(0, "katie", ""))
    allow(@plugin).to receive(:shell_out).with("hostname -f").and_return(mock_shell_out(0, "katie.bethell", ""))
    allow(@plugin).to receive(:shell_out).with("hostname").and_return(mock_shell_out(0, "katie.local", ""))
  end

  it_should_check_from("freebsd::hostname", "hostname", "hostname -s", "katie")

  it_should_check_from("freebsd::hostname", "fqdn", "hostname -f", "katie.bethell")

  it_should_check_from("freebsd::hostname", "machinename", "hostname", "katie.local")
end
