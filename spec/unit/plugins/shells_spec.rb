#
# Author:: Tim Smith (<tsmith@chef.io>)
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

describe Ohai::System, "plugin shells" do
  let(:plugin) { get_plugin("shells") }

  # content from OS X 10.11
  shell_file = ["# List of acceptable shells for chpass(1).\n",
                "# Ftpd will not allow users to connect who are not using\n",
                "# one of these shells.\n",
                "\n",
                "/bin/bash\n",
                "/bin/csh\n",
                "/bin/ksh\n",
                "/bin/sh\n",
                "/bin/tcsh\n",
                "/bin/zsh\n"]

  let(:shell_file_content) { shell_file }

  it "does not set shells attribute if /etc/shells does not exist" do
    allow(::File).to receive(:exist?).with("/etc/shells").and_return(false)
    plugin.run
    expect(plugin).not_to have_key(:shells)
  end

  it "sets shells to an array of shells if /etc/shells exists" do
    allow(::File).to receive(:readlines).with("/etc/shells").and_return(shell_file_content)
    allow(::File).to receive(:exist?).with("/etc/shells").and_return(true)
    plugin.run
    expect(plugin.shells).to match_array([
                                           "/bin/bash",
                                           "/bin/csh",
                                           "/bin/ksh",
                                           "/bin/sh",
                                           "/bin/tcsh",
                                           "/bin/zsh",
                                         ])
  end
end
