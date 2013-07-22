#
# Author:: Doug MacEachern <dougm@vmware.com>
# Copyright:: Copyright (c) 2009 VMware, Inc.
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
    @ohai = Ohai::System.new
    Ohai::Loader.new(@ohai).load_plugin(File.join(PLUGIN_PATH, "php.rb"), "php")
    @plugin = @ohai.plugins[:php][:plugin].new(@ohai)
    @plugin[:languages] = Mash.new
    @status = 0
    @stdout = "PHP 5.1.6 (cli) (built: Jul 16 2008 19:52:52)\nCopyright (c) 1997-2006 The PHP Group\nZend Engine v2.1.0, Copyright (c) 1998-2006 Zend Technologies\n"
    @stderr = ""
    @plugin.stub(:run_command).with({:no_status_check=>true, :command=>"php -v"}).and_return([@status, @stdout, @stderr])
  end

  it "should get the php version from running php -V" do
    @plugin.should_receive(:run_command).with({:no_status_check=>true, :command=>"php -v"}).and_return([0, "PHP 5.1.6 (cli) (built: Jul 16 2008 19:52:52)\nCopyright (c) 1997-2006 The PHP Group\nZend Engine v2.1.0, Copyright (c) 1998-2006 Zend Technologies\n", ""])
    @plugin.run
  end

  it "should set languages[:php][:version]" do
    @plugin.run
    @plugin.languages[:php][:version].should eql("5.1.6")
  end

  it "should not set the languages[:php] tree up if php command fails" do
    @status = 1
    @stdout = "PHP 5.1.6 (cli) (built: Jul 16 2008 19:52:52)\nCopyright (c) 1997-2006 The PHP Group\nZend Engine v2.1.0, Copyright (c) 1998-2006 Zend Technologies\n"
    @stderr = ""
    @plugin.stub(:run_command).with({:no_status_check=>true, :command=>"php -v"}).and_return([@status, @stdout, @stderr])
    @plugin.run
    @plugin.languages.should_not have_key(:php)
  end
end

#########

expected = [{
              :env => [],
              :platform => "centos-5.9",
              :arch => "x86",
              :ohai => { "languages" => {}},
            },{
              :env => ["php"],
              :platform => "centos-5.9",
              :arch => "x86",
              :ohai => { "languages" => { "php" => { "version" => "5.3.3"}}},
            },{
              :env => [],
              :platform => "centos-5.9",
              :arch => "x64",
              :ohai => { "languages" => {}},
            },{
              :env => ["php"],
              :platform => "centos-5.9",
              :arch => "x64",
              :ohai => { "languages" => { "php" => { "version" => "5.3.3" }}},
            },{
              :env => [],
              :platform => "centos-6.4",
              :arch => "x86",
              :ohai => { "languages" => {}},
            },{
              :env => ["php"],
              :platform => "centos-6.4",
              :arch => "x86",
              :ohai => { "languages" => { "php" => { "version" => "5.3.3" }}},
            },{
              :env => [],
              :platform => "centos-6.4",
              :arch => "x64",
              :ohai => { "languages" => {}},
            },{
              :env => ["php"],
              :platform => "centos-6.4",
              :arch => "x64",
              :ohai => { "languages" => { "php" => { "version" => "5.3.3" }}},
            },{
              :env => [],
              :platform => "ubuntu-10.04",
              :arch => "x86",
              :ohai => { "languages" => {}},
            },{
              :env => [:php],
              :platform => "ubuntu-10.04",
              :arch => "x86",
              :ohai => { "languages" => { "php" => { "version" => "5.3.2-1ubuntu4.20" }}},
            },{
              :env => [],
              :platform => "ubuntu-10.04",
              :arch => "x64",
              :ohai => { "languages" => {}},
            },{
              :env => [:php],
              :platform => "ubuntu-10.04",
              :arch => "x64",
              :ohai => { "languages" => { "php" => { "version" => "5.3.2-1ubuntu4.20" }}},
            },{
              :env => [],
              :platform => "ubuntu-12.04",
              :arch => "x86",
              :ohai => { "languages" => {}},
            },{
              :env => [:php],
              :platform => "ubuntu-12.04",
              :arch => "x86",
              :ohai => { "languages" => { "php" => { "version" => "5.3.10-1ubuntu3.7" }}},
            },{
              :env => [],
              :platform => "ubuntu-12.04",
              :arch => "x64",
              :ohai => { "languages" => {}},
            },{
              :env => [:php],
              :platform => "ubuntu-12.04",
              :arch => "x64",
              :ohai => { "languages" => { "php" => { "version" => "5.3.10-1ubuntu3.7" }}},
            },{
              :env => [],
              :platform => "ubuntu-13.04",
              :arch => "x64",
              :ohai => { "languages" => {}},
            },{
              :env => [:php],
              :platform => "ubuntu-13.04",
              :arch => "x64",
              :ohai => { "languages" => { "php" => { "version" => "5.4.9-4ubuntu2.2" }}},
            }]

describe Ohai::System, "cross platform data" do
  before (:all) do
    @opc = OhaiPluginCommon.new
    @opc.set_path '/../path'
  end

  before (:each) do
    @ohai = Ohai::System.new
  end

  expected.each do |e|
    it "provides data when the platform is '#{e[:platform]}', the architecture is '#{e[:arch]}' and the environment is '#{e[:env]}'" do
      @opc.set_env e[:platform], e[:arch], e[:env]
      @ohai.require_plugin "php"
      @opc.subsumes?(@ohai.data, e[:ohai]).should be_true
    end
  end
end
