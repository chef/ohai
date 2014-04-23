#
# Author:: Toomas Pelberg (toomas.pelberg@playtech.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

tmp = ENV['TMPDIR'] || ENV['TMP'] || ENV['TEMP'] || '/tmp'

describe Ohai::System, "plugin fail" do
  
  before(:all) do
    begin
      Dir.mkdir("#{tmp}/plugins")
    rescue Errno::EEXIST
      # Ignore it
    end
    fail_plugin=File.open("#{tmp}/plugins/fail.rb","w+")
    fail_plugin.write("provides \"fail\"require 'thiswillblowupinyourface'\nk=MissingClassName.new\nfail \"ohnoes\"")
    fail_plugin.close
    real_plugin=File.open("#{tmp}/plugins/real.rb","w+")
    real_plugin.write("provides \"real\"\nreal \"useful\"\n")
    real_plugin.close
    @plugin_path=Ohai::Config[:plugin_path]
  end
  
  before(:each) do
    Ohai::Config[:plugin_path]=["#{tmp}/plugins"]
    @ohai=Ohai::System.new
  end
  
  after(:all) do
    File.delete("#{tmp}/plugins/fail.rb")
    File.delete("#{tmp}/plugins/real.rb")
    begin
      Dir.delete("#{tmp}/plugins")
    rescue
      # Don't care if it fails
    end
    Ohai::Config[:plugin_path]=@plugin_path
  end
  
  it "should continue gracefully if plugin loading fails" do
    @ohai.require_plugin("fail")
    @ohai.require_plugin("real")
    @ohai.data[:real].should eql("useful")
    @ohai.data.should_not have_key("fail")
  end
end
