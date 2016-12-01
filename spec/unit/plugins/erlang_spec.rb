#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Theodore Nordsieck (<theo@chef.io>)
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

require File.expand_path(File.dirname(__FILE__) + "/../../spec_helper.rb")

describe Ohai::System, "plugin erlang" do
  let(:plugin) { get_plugin("erlang") }

  before do
    plugin[:languages] = Mash.new
    erl_v_output = "Erlang (SMP,ASYNC_THREADS,HIPE) (BEAM) emulator version 7.3\n"
    erl_systeminfo_output = "\"18\"\r\n\"7.3\"\r\n\"2.10\"\r\n"
    allow(plugin).to receive(:shell_out).with("erl +V")
                                        .and_return(mock_shell_out(0, "", erl_v_output))
    allow(plugin).to receive(:shell_out).with("erl -eval 'erlang:display(erlang:system_info(otp_release)), erlang:display(erlang:system_info(version)), erlang:display(erlang:system_info(nif_version)), halt().'  -noshell")
                                        .and_return(mock_shell_out(0, erl_systeminfo_output, ""))
  end

  it "sets languages[:erlang][:options]" do
    plugin.run
    expect(plugin.languages[:erlang][:options]).to eql(%w{SMP ASYNC_THREADS HIPE})
  end

  it "sets languages[:erlang][:emulator]" do
    plugin.run
    expect(plugin.languages[:erlang][:emulator]).to eql("BEAM")
  end

  it "sets languages[:erlang][:version]" do
    plugin.run
    expect(plugin.languages[:erlang][:version]).to eql("18")
  end

  it "sets languages[:erlang][:erts_version]" do
    plugin.run
    expect(plugin.languages[:erlang][:erts_version]).to eql("7.3")
  end

  it "sets languages[:erlang][:nif_version]" do
    plugin.run
    expect(plugin.languages[:erlang][:nif_version]).to eql("2.10")
  end

  it "does not set languages[:erlang] if the erl commands fails" do
    allow(plugin).to receive(:shell_out).and_return(mock_shell_out(1, "", ""))
    plugin.run
    expect(plugin.languages).not_to have_key(:erlang)
  end

  it "does not set languages[:erlang] if the erl command doesn't exist" do
    allow(plugin).to receive(:shell_out).and_raise(Ohai::Exceptions::Exec)
    plugin.run
    expect(plugin.languages).not_to have_key(:erlang)
  end
end
