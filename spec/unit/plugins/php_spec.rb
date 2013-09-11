#
# Author:: Doug MacEachern <dougm@vmware.com>
# Author:: Theodore Nordsieck (<theo@opscode.com>)
# Copyright:: Copyright (c) 2009 VMware, Inc.
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

require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '/spec_helper.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'path', 'ohai_plugin_common.rb'))

describe Ohai::System, "plugin php" do

  before(:each) do
    @plugin = get_plugin("php")
    @plugin[:languages] = Mash.new
    @stdout = "PHP 5.1.6 (cli) (built: Jul 16 2008 19:52:52)\nCopyright (c) 1997-2006 The PHP Group\nZend Engine v2.1.0, Copyright (c) 1998-2006 Zend Technologies\n"
    @plugin.stub(:shell_out).with("php -v").and_return(mock_shell_out(0, @stdout, ""))
  end

  it "should get the php version from running php -V" do
    @plugin.should_receive(:shell_out).with("php -v").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
  end

  it "should set languages[:php][:version]" do
    @plugin.run
    @plugin.languages[:php][:version].should eql("5.1.6")
  end

  it "should not set the languages[:php] tree up if php command fails" do
    @stdout = "PHP 5.1.6 (cli) (built: Jul 16 2008 19:52:52)\nCopyright (c) 1997-2006 The PHP Group\nZend Engine v2.1.0, Copyright (c) 1998-2006 Zend Technologies\n"
    @plugin.stub(:shell_out).with("php -v").and_return(mock_shell_out(1, @stdout, ""))
    @plugin.run
    @plugin.languages.should_not have_key(:php)
  end

  #########

  test_plugin([ "languages", "php" ], [ "php" ]) do | p |
    p.test([ "centos-5.9", "centos-6.4", "ubuntu-10.04", "ubuntu-12.04" ], [ "x86", "x64" ], [[]],
           { "languages" => { "php" => nil }})
    p.test([ "ubuntu-13.04" ], [ "x64" ], [[]],
           { "languages" => { "php" => nil }})
    p.test([ "centos-5.9", "centos-6.4" ], [ "x86", "x64" ], [[ "php" ]],
           { "languages" => { "php" => { "version" => "5.3.3" }}})
    p.test([ "ubuntu-10.04" ], ["x86", "x64"], [[ "php" ]],
           { "languages" => { "php" => { "version" => "5.3.2-1ubuntu4.20" }}})
    p.test([ "ubuntu-12.04" ], [ "x86", "x64" ], [[ "php" ]],
           { "languages" => { "php" => { "version" => "5.3.10-1ubuntu3.7" }}})
    p.test([ "ubuntu-13.04" ], [ "x64" ], [[ "php" ]],
           { "languages" => { "php" => { "version" => "5.4.9-4ubuntu2.2" }}})
  end
end
