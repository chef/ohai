#
# Author:: Caleb Tennis (<caleb.tennis@gmail.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '/spec_helper.rb'))

describe Ohai::System, "Init package" do
  let(:plugin) {
    p = get_plugin("init_package")
    p.stub(:collect_os).and_return("linux")
    p
  }

  let(:proc1_content) { "init\n" }
  let(:proc_1_file_path) { "/proc/1/comm" }
  let(:proc_1_file) { double(proc_1_file_path, :gets => proc1_content) }

  before(:each) do
    File.stub(:exists?).with(proc_1_file_path).and_return(true)
    File.stub(:open).with(proc_1_file_path).and_return(proc_1_file)
  end

  it "should set init_package to init" do
    plugin.run
    plugin[:init_package].should == "init"
  end

  describe "when init_package is systemd" do
    let(:proc1_content) { "systemd\n" }

    it "should set init_package to systemd" do
      plugin.run
      plugin[:init_package].should == "systemd"
    end
  end
end
