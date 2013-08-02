#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Theodore Nordsieck (<theo@opscode.com>)
# Copyright:: Copyright (c) 2008-2013 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../path/ohai_plugin_common.rb')


describe Ohai::System, "Linux kernel plugin" do
  before(:each) do
    @ohai = Ohai::System.new
    Ohai::Loader.new(@ohai).load_plugin(File.join(PLUGIN_PATH, "linux/kernel.rb"), "lkern")
    @plugin = @ohai.plugins[:lkern][:plugin].new(@ohai)
    @plugin.stub(:from).with("uname -o").and_return("Linux")
    @plugin.should_receive(:popen4).with("env lsmod").at_least(1).times
    @plugin[:kernel] = {}
    @plugin.run
  end

  it_should_check_from_deep_mash("linux::kernel", "kernel", "os", "uname -o", "Linux")
end

###############################

expected = [{
              :env => [[]],
              :platform => ["centos-5.9", "centos-6.4", "ubuntu-10.04", "ubuntu-12.04"],
              :arch => ["x86", "x64"],
              :ohai => { "kernel" => { "os" => "GNU/Linux" }},
            },{
              :env => [[]],
              :platform => ["ubuntu-13.04"],
              :arch => ["x64"],
              :ohai => { "kernel" => { "os" => "GNU/Linux" }},
            }]

OhaiPluginCommon.new.check_expected ["kernel", "linux/kernel"], expected, ["uname", "lsmod"]
