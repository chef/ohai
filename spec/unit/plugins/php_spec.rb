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
    @stdout =  <<-OUT
PHP 5.1.6 (cli) (built: Jul 16 2008 19:52:52)
Copyright (c) 1997-2006 The PHP Group
Zend Engine v2.1.0, Copyright (c) 1998-2006 Zend Technologies
OUT
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
    @stdout = <<-OUT
PHP 5.1.6 (cli) (built: Jul 16 2008 19:52:52)
Copyright (c) 1997-2006 The PHP Group
Zend Engine v2.1.0, Copyright (c) 1998-2006 Zend Technologies
OUT
    allow(@plugin).to receive(:shell_out).with("php -v").and_return(mock_shell_out(1, @stdout, ""))
    @plugin.run
    expect(@plugin.languages).not_to have_key(:php)
  end

  it "should parse builddate even if it's suhosin patched" do
    @stdout =  <<-OUT
PHP 5.3.27 with Suhosin-Patch (cli) (built: Aug 30 2013 04:30:30)
Copyright (c) 1997-2013 The PHP Group
Zend Engine v2.3.0, Copyright (c) 1998-2013 Zend Technologies
OUT
    allow(@plugin).to receive(:shell_out).with("php -v").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
    expect(@plugin.languages[:php][:builddate]).to eql("Aug 30 2013 04:30:30")
  end

  it "should not set zend_optcache_version if not compiled with opcache" do
    @stdout =  <<-OUT
PHP 5.1.6 (cli) (built: Jul 16 2008 19:52:52)
Copyright (c) 1997-2006 The PHP Group
Zend Engine v2.1.0, Copyright (c) 1998-2006 Zend Technologies
OUT
    allow(@plugin).to receive(:shell_out).with("php -v").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
    expect(@plugin.languages[:php]).not_to have_key(:zend_opcache_version)
  end

  it "should parse zend_optcache_version if compiled with opcache" do
    @stdout = <<-OUT
PHP 5.5.9-1ubuntu4.5 (cli) (built: Oct 29 2014 11:59:10)
Copyright (c) 1997-2014 The PHP Group
Zend Engine v2.5.0, Copyright (c) 1998-2014 Zend Technologies
    with Zend OPcache v7.0.3, Copyright (c) 1999-2014, by Zend Technologies
OUT
    allow(@plugin).to receive(:shell_out).with("php -v").and_return(mock_shell_out(0, @stdout, ""))
    @plugin.run
    expect(@plugin.languages[:php][:zend_opcache_version]).to eql("7.0.3")
  end
end
