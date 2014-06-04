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
    @plugin = get_plugin("nodejs")
    @plugin[:languages] = Mash.new
    @stdout = "v0.8.11\n"
    @plugin.stub(:shell_out).with("node -v").and_return(mock_shell_out(0, @stdout, ""))
  end

  it "should get the nodejs version from running node -v" do
    @plugin.should_receive(:shell_out).with("node -v").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
  end

  it "should set languages[:nodejs][:version]" do
    @plugin.run
    @plugin.languages[:nodejs][:version].should eql("0.8.11")
  end

  it "should not set the languages[:nodejs] tree up if node command fails" do
    @stdout = "v0.8.11\n"
    @plugin.stub(:shell_out).with("node -v").and_return(mock_shell_out(1, @stdout, ""))
    @plugin.run
    @plugin.languages.should_not have_key(:nodejs)
  end

end
