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

describe Ohai::System, "plugin groovy" do
  let(:plugin) { get_plugin("groovy") }

  before(:each) do
    plugin[:languages] = Mash.new
  end

  it "shells out to groovy -v" do
    allow(plugin).to receive(:shell_out).with("groovy -v").and_return(mock_shell_out(0, "", ""))
    expect(plugin).to receive(:shell_out).with("groovy -v")
    plugin.run
  end

  it "sets languages[:groovy][:version] on newer groovy versions" do
    new_stdout = "Groovy Version: 2.4.6 JVM: 1.8.0_60 Vendor: Oracle Corporation OS: Mac OS X\n"
    allow(plugin).to receive(:shell_out).with("groovy -v").and_return(mock_shell_out(0, new_stdout, ""))
    plugin.run
    expect(plugin.languages[:groovy][:version]).to eql("2.4.6")
  end

  it "sets languages[:groovy][:version] on older groovy versions" do
    old_stdout = "Groovy Version: 1.6.3 JVM: 1.6.0_0\n"
    allow(plugin).to receive(:shell_out).with("groovy -v").and_return(mock_shell_out(0, old_stdout, ""))
    plugin.run
    expect(plugin.languages[:groovy][:version]).to eql("1.6.3")
  end

  it "sets languages[:groovy][:jvm]" do
    new_stdout = "Groovy Version: 2.4.6 JVM: 1.8.0_60 Vendor: Oracle Corporation OS: Mac OS X\n"
    allow(plugin).to receive(:shell_out).with("groovy -v").and_return(mock_shell_out(0, new_stdout, ""))
    plugin.run
    expect(plugin.languages[:groovy][:jvm]).to eql("1.8.0_60")
  end

  it "does not set languages[:groovy] if groovy command fails" do
    allow(plugin).to receive(:shell_out).with("groovy -v").and_return(mock_shell_out(1, "", ""))
    plugin.run
    expect(plugin.languages).not_to have_key(:groovy)
  end

  it "does not set languages[:groovy] if groovy command doesn't exist" do
    allow(plugin).to receive(:shell_out).and_raise(Ohai::Exceptions::Exec)
    plugin.run
    expect(plugin.languages).not_to have_key(:groovy)
  end
end
