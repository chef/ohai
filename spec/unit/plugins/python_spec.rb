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

require_relative "../../spec_helper.rb"

describe Ohai::System, "plugin python" do
  let(:stdout) { "2.5.2 (r252:60911, Jan  4 2009, 17:40:26)\n[GCC 4.3.2]\n" }

  let(:retval) { 0 }

  let(:plugin) do
    plugin = get_plugin("python")
    plugin[:languages] = Mash.new
    expect(plugin).to receive(:shell_out).with("python -c \"import sys; print (sys.version)\"").and_return(mock_shell_out(retval, stdout, ""))
    plugin
  end

  it "gets the python version from printing sys.version and sys.platform" do
    plugin.run
  end

  it "sets languages[:python][:version]" do
    plugin.run
    expect(plugin.languages[:python][:version]).to eql("2.5.2")
  end

  context "when the python command fails" do
    let(:retval) { 1 }

    it "does not set the languages[:python] tree up" do
      plugin.run
      expect(plugin.languages).not_to have_key(:python)
    end
  end
end
