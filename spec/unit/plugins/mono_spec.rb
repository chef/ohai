#
# Author:: Doug MacEachern <dougm@vmware.com>
# Copyright:: Copyright (c) 2009 VMware, Inc.
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

describe Ohai::System, "plugin mono" do
  let(:plugin) { get_plugin("mono") }

  before(:each) do
    plugin[:languages] = Mash.new
    @stdout = <<-OUT
Mono JIT compiler version 4.2.3 (Stable 4.2.3.4/832de4b Wed Mar 30 13:57:48 PDT 2016)
Copyright (C) 2002-2014 Novell, Inc, Xamarin Inc and Contributors. www.mono-project.com
	TLS:           normal
	SIGSEGV:       altstack
	Notification:  kqueue
	Architecture:  amd64
	Disabled:      none
	Misc:          softdebug
	LLVM:          supported, not enabled.
	GC:            sgen
OUT
    allow(plugin).to receive(:shell_out).with("mono -V").and_return(mock_shell_out(0, @stdout, ""))
  end

  it "gets the mono version from running mono -V" do
    expect(plugin).to receive(:shell_out).with("mono -V").and_return(mock_shell_out(0, @stdout, ""))
    plugin.run
  end

  it "sets languages[:mono][:version]" do
    plugin.run
    expect(plugin.languages[:mono][:version]).to eql("4.2.3")
  end

  it "sets languages[:mono][:builddate]" do
    plugin.run
    expect(plugin.languages[:mono][:builddate]).to eql("Wed Mar 30 13:57:48 PDT 2016")
  end

  it "does not set the languages[:mono] if mono command fails" do
    allow(plugin).to receive(:shell_out).with("mono -V").and_return(mock_shell_out(1, @stdout, ""))
    plugin.run
    expect(plugin.languages).not_to have_key(:mono)
  end

  it "does not set languages[:mono] if mono command doesn't exist" do
    allow(plugin).to receive(:shell_out).and_raise(Ohai::Exceptions::Exec)
    plugin.run
    expect(plugin.languages).not_to have_key(:mono)
  end
end
