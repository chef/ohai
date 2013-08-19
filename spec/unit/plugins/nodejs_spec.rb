#
# Author:: Jacques Marneweck (<jacques@powertrip.co.za>)
# Author:: Theodore Nordsieck (<theo@opscode.com>)
# Copyright:: Copyright (c) Jacques Marneweck
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

describe Ohai::System, "plugin nodejs" do

  before(:each) do
    ohai = Ohai::System.new
    loader = Ohai::Loader.new(ohai)
    @plugin = loader.load_plugin(File.join(PLUGIN_PATH, "nodejs.rb")).new(ohai)
    @plugin[:languages] = Mash.new
    @status = 0
    @stdout = "v0.8.11\n"
    @stderr = ""
    @plugin.stub(:run_command).with({:no_status_check=>true, :command=>"node -v"}).and_return([@status, @stdout, @stderr])
  end

  it "should get the nodejs version from running node -v" do
    @plugin.should_receive(:run_command).with({:no_status_check=>true, :command=>"node -v"}).and_return([0, "v0.8.11\n", ""])
    @plugin.run
  end

  it "should set languages[:nodejs][:version]" do
    @plugin.run
    @plugin.languages[:nodejs][:version].should eql("0.8.11")
  end

  it "should not set the languages[:nodejs] tree up if node command fails" do
    @status = 1
    @stdout = "v0.8.11\n"
    @stderr = ""
    @plugin.stub(:run_command).with({:no_status_check=>true, :command=>"node -v"}).and_return([@status, @stdout, @stderr])
    @plugin.run
    @plugin.languages.should_not have_key(:nodejs)
  end

  #############

  require File.expand_path(File.dirname(__FILE__) + '/../path/ohai_plugin_common.rb')

  expected = [{
                :env => [[]],
                :platform => ["centos-6.4", "ubuntu-10.04", "ubuntu-12.04"],
                :arch => ["x86", "x64"],
                :ohai => { "languages" => { "nodejs" => nil }},
              },{
                :env => [[]],
                :platform => ["ubuntu-13.04"],
                :arch => ["x64"],
                :ohai => { "languages" => { "nodejs" => nil }},
              },{
                :env => [["nodejs"]],
                :platform => ["centos-6.4", "ubuntu-10.04", "ubuntu-12.04"],
                :arch => ["x86", "x64"],
                :ohai => { "languages" => { "nodejs" => { "version" => "0.10.2" }}},
              },{
                :env => [["nodejs"]],
                :platform => ["ubuntu-13.04"],
                :arch => ["x64"],
                :ohai => { "languages" => { "nodejs" => { "version" => "0.10.2" }}},
              }]

  include_context "cross platform data"
  it_behaves_like "a plugin", ["languages", "nodejs"], expected, ["node"]
end
