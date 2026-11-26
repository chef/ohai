# frozen_string_literal: true
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright (c) 2026 Tim Smith
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

describe Ohai::System, "AIX virtualization uname -L parsing" do
  let(:plugin) { get_plugin("aix/virtualization") }

  def uname_l(output)
    allow(plugin).to receive(:shell_out).with("uname -L").and_return(mock_shell_out(0, output, ""))
  end

  before do
    allow(plugin).to receive(:collect_os).and_return(:aix)
    allow(plugin).to receive(:shell_out).with("uname -W").and_return(mock_shell_out(0, "0\n", ""))
    allow(plugin).to receive(:shell_out).with("lswpar -L").and_return(mock_shell_out(0, "", ""))
  end

  # uname -L prints "-1 NULL" when the system is not an LPAR (AIX uname
  # command reference)
  it "sets no LPAR attributes when uname -L prints -1 NULL" do
    uname_l("-1 NULL\n")
    plugin.run
    expect(plugin[:virtualization]).not_to have_key(:lpar_no)
    expect(plugin[:virtualization]).not_to have_key(:lpar_name)
  end

  it "sets no LPAR attributes when uname -L prints 1 NULL with no newline" do
    uname_l("1 NULL")
    plugin.run
    expect(plugin[:virtualization]).not_to have_key(:lpar_no)
    expect(plugin[:virtualization]).not_to have_key(:lpar_name)
  end

  # today's behavior: the name keeps the trailing newline, so it isn't "NULL"
  it "sets the LPAR attributes when uname -L prints 1 NULL with a newline" do
    uname_l("1 NULL\n")
    plugin.run
    expect(plugin[:virtualization][:lpar_no]).to eq(1)
    expect(plugin[:virtualization][:lpar_name]).to eq("NULL\n")
  end
end
