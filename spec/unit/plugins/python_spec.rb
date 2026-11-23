#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Theodore Nordsieck (<theo@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Ohai::System, "plugin python" do
  let(:python_cmd) { "python -c \"import sys; print (sys.version)\"" }
  let(:python3_cmd) { "python3 -c \"import sys; print (sys.version)\"" }
  let(:plugin) do
    plugin = get_plugin("python")
    plugin[:languages] = Mash.new
    plugin
  end

  context "when python works" do
    before do
      allow(plugin).to receive(:shell_out).with(python_cmd)
        .and_return(mock_shell_out(0, "2.5.2 (r252:60911, Jan  4 2009, 17:40:26)\n[GCC 4.3.2]\n", ""))
    end

    it "sets languages[:python][:version]" do
      plugin.run
      expect(plugin.languages[:python][:version]).to eql("2.5.2")
    end

    it "sets languages[:python][:builddate]" do
      plugin.run
      expect(plugin.languages[:python][:builddate]).to eql("Jan 4 2009, 17:40:26")
    end

    it "doesn't run python3" do
      expect(plugin).not_to receive(:shell_out).with(python3_cmd)
      plugin.run
    end
  end

  context "when only python3 is installed" do
    # current distros ship no unversioned "python"; through the shell a
    # missing command exits 127
    before do
      allow(plugin).to receive(:shell_out).with(python_cmd)
        .and_return(mock_shell_out(127, "", "sh: 1: python: not found\n"))
      allow(plugin).to receive(:shell_out).with(python3_cmd)
        .and_return(mock_shell_out(0, "3.11.2 (main, Mar 13 2023, 12:18:29) [GCC 12.2.0]\n", ""))
    end

    it "sets the version from python3" do
      plugin.run
      expect(plugin.languages[:python][:version]).to eql("3.11.2")
    end

    it "sets the build date from python3" do
      plugin.run
      expect(plugin.languages[:python][:builddate]).to eql("Mar 13 2023, 12:18:29")
    end
  end

  context "when running python raises" do
    before do
      allow(plugin).to receive(:shell_out).with(python_cmd).and_raise(Ohai::Exceptions::Exec)
      allow(plugin).to receive(:shell_out).with(python3_cmd)
        .and_return(mock_shell_out(0, "3.12.3 (main, Feb  4 2025, 14:48:35) [GCC 13.3.0]\n", ""))
    end

    it "falls back to python3" do
      plugin.run
      expect(plugin.languages[:python][:version]).to eql("3.12.3")
    end
  end

  context "when neither python nor python3 works" do
    before do
      allow(plugin).to receive(:shell_out).with(python_cmd).and_return(mock_shell_out(127, "", ""))
      allow(plugin).to receive(:shell_out).with(python3_cmd).and_raise(Ohai::Exceptions::Exec)
    end

    it "does not set the languages[:python] tree up" do
      plugin.run
      expect(plugin.languages).not_to have_key(:python)
    end
  end
end
