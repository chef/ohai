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

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '/spec_helper.rb'))

describe Ohai::System, "plugin php" do

  before(:each) do
    @plugin = get_plugin("php")
    @plugin[:languages] = Mash.new
    @stdout = "PHP 5.1.6 (cli) (built: Jul 16 2008 19:52:52)\nCopyright (c) 1997-2006 The PHP Group\nZend Engine v2.1.0, Copyright (c) 1998-2006 Zend Technologies\n"
    allow(@plugin).to receive(:shell_out).with("php -v").and_return(mock_shell_out(0, @stdout, ""))
  end

  it "should get the php version from running php -V" do
    expect(@plugin).to receive(:shell_out).with("php -v").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
  end

  it "should set languages[:php][:version]" do
    @plugin.run
    expect(@plugin.languages[:php][:version]).to eql("5.1.6")
  end

  it "should not set the languages[:php] tree up if php command fails" do
    @stdout = "PHP 5.1.6 (cli) (built: Jul 16 2008 19:52:52)\nCopyright (c) 1997-2006 The PHP Group\nZend Engine v2.1.0, Copyright (c) 1998-2006 Zend Technologies\n"
    allow(@plugin).to receive(:shell_out).with("php -v").and_return(mock_shell_out(1, @stdout, ""))
    @plugin.run
    expect(@plugin.languages).not_to have_key(:php)
  end

  it "should parse builddate even if it's suhosin patched" do
    @stdout = "PHP 5.3.27 with Suhosin-Patch (cli) (built: Aug 30 2013 04:30:30) \nCopyright (c) 1997-2013 The PHP Group\nZend Engine v2.3.0, Copyright (c) 1998-2013 Zend Technologies"
    allow(@plugin).to receive(:shell_out).with("php -v").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
    expect(@plugin.languages[:php][:builddate]).to eql("Aug 30 2013 04:30:30")
  end

end
