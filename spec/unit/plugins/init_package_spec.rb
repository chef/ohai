#
# Author:: Caleb Tennis (<caleb.tennis@gmail.com>)
# Copyright:: Copyright (c) 2012-2016 Chef Software, Inc.
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

describe Ohai::System, "Init package" do
  let(:plugin) do
    p = get_plugin("init_package")
    allow(p).to receive(:collect_os).and_return("linux")
    p
  end

  let(:proc1_content) { "init\n" }
  let(:proc1_exists) { true }
  let(:proc_1_file_path) { "/proc/1/comm" }
  let(:proc_1_file) { double(proc_1_file_path, :gets => proc1_content) }

  before(:each) do
    allow(File).to receive(:exists?).with(proc_1_file_path).and_return(proc1_exists)
    allow(File).to receive(:open).with(proc_1_file_path).and_return(proc_1_file)
  end

  it "should set init_package to init" do
    plugin.run
    expect(plugin[:init_package]).to eq("init")
  end

  describe "when init_package is systemd" do
    let(:proc1_content) { "systemd\n" }

    it "should set init_package to systemd" do
      plugin.run
      expect(plugin[:init_package]).to eq("systemd")
    end
  end

  describe "when /proc/1/comm doesn't exist" do
    let(:proc1_exists) { false }

    it "should set init_package to init" do
      plugin.run
      expect(plugin[:init_package]).to eq("init")
    end
  end
end
