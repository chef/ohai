#
# Author:: Davide Cavalca <dcavalca@fb.com>
# Copyright:: Copyright (c) 2016 Facebook
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

describe Ohai::System, "Linux sessions plugin" do
  let(:plugin) { get_plugin("linux/sessions") }

  before(:each) do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  it "should populate sessions if loginctl is found" do
    loginctl_out = <<-LOGINCTL_OUT
        c1        118 Debian-gdm       seat0
       318          0 root
        46          0 root
       306       1000 joe
LOGINCTL_OUT
    allow(plugin).to receive(:which).with("loginctl").and_return("/bin/loginctl")
    allow(plugin).to receive(:shell_out).with("/bin/loginctl --no-pager --no-legend --no-ask-password list-sessions").and_return(mock_shell_out(0, loginctl_out, ""))
    plugin.run
    expect(plugin[:sessions].to_hash).to eq({
      "by_session" => {
        "c1" => {
          "session" => "c1",
          "uid" => "118",
          "user" => "Debian-gdm",
          "seat" => "seat0",
        },
        "318" => {
          "session" => "318",
          "uid" => "0",
          "user" => "root",
          "seat" => nil,
        },
        "46" => {
          "session" => "46",
          "uid" => "0",
          "user" => "root",
          "seat" => nil,
        },
        "306" => {
          "session" => "306",
          "uid" => "1000",
          "user" => "joe",
          "seat" => nil,
        },
      },
      "by_user" => {
        "Debian-gdm" => [{
          "session" => "c1",
          "uid" => "118",
          "user" => "Debian-gdm",
          "seat" => "seat0",
        }],
        "root" => [{
          "session" => "318",
          "uid" => "0",
          "user" => "root",
          "seat" => nil,
        }, {
          "session" => "46",
          "uid" => "0",
          "user" => "root",
          "seat" => nil,
        }],
        "joe" => [{
          "session" => "306",
          "uid" => "1000",
          "user" => "joe",
          "seat" => nil,
        }],
      },
    })
  end

  it "should not populate sessions if loginctl is not found" do
    allow(plugin).to receive(:which).with("loginctl").and_return(false)
    plugin.run
    expect(plugin[:sessions]).to be(nil)
  end
end
