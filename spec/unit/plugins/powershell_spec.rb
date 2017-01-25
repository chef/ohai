#
# Copyright:: Copyright (c) 2014 Chef Software, Inc
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

describe Ohai::System, "plugin powershell" do
  let(:plugin) { get_plugin("powershell") }

  before do
    stub_const("::RbConfig::CONFIG", { "host_os" => "windows" })
  end

  before(:each) do
    plugin[:languages] = Mash.new
  end

  it "sets languages[:powershell][:version] for v4" do

    v4_output = <<END

Name                           Value
----                           -----
PSVersion                      4.0
WSManStackVersion              3.0
SerializationVersion           1.1.0.1
CLRVersion                     4.0.30319.34014
BuildVersion                   6.3.9600.16394
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0}
PSRemotingProtocolVersion      2.2

END
    compat_version_array = ["1.0", "2.0", "3.0", "4.0"]

    allow(plugin).to receive(:shell_out).with(anything()).and_return(mock_shell_out(0, v4_output, ""))
    allow(plugin).to receive(:parse_compatible_versions).and_return(compat_version_array)
    plugin.run
    expect(plugin.languages[:powershell][:version]).to eql("4.0")
    expect(plugin.languages[:powershell][:ws_man_stack_version]).to eql("3.0")
    expect(plugin.languages[:powershell][:serialization_version]).to eql("1.1.0.1")
    expect(plugin.languages[:powershell][:clr_version]).to eql("4.0.30319.34014")
    expect(plugin.languages[:powershell][:build_version]).to eql("6.3.9600.16394")
    expect(plugin.languages[:powershell][:compatible_versions]).to eql(["1.0", "2.0", "3.0", "4.0"])
    expect(plugin.languages[:powershell][:remoting_protocol_version]).to eql("2.2")
  end

  it "does not set the languages[:powershell] tree up if powershell command fails" do
    error_output = <<END
'powershell.exe' is not recognized as an internal or external command,
operable program or batch file.
END

    allow(plugin).to receive(:shell_out).with(anything).and_return(mock_shell_out(1, error_output, ""))
    plugin.run
    expect(plugin.languages).not_to have_key(:powershell)
  end

end
