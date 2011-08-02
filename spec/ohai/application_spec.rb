#
# Author:: Toomas Pelberg (<toomas.pelberg@playtech.com>)
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'ohai/application'

describe Ohai::System, "CLI interface" do
  
  before(:each) do
    @ohai=Ohai::Application.new  
  end
  
  it "should tell about -d" do
    @ohai.options.should have_key(:directory)
    @ohai.options[:directory][:on].should eql(:on)
    @ohai.options[:directory][:short].should eql("-d DIRECTORY")
  end
  
  it "should tell about -f" do
    @ohai.options.should have_key(:file)
    @ohai.options[:file][:on].should eql(:on)
    @ohai.options[:file][:short].should eql("-f FILE")
  end
  
  it "should tell about -l" do
    @ohai.options.should have_key(:log_level)
    @ohai.options[:log_level][:on].should eql(:on)
    @ohai.options[:log_level][:short].should eql("-l LEVEL")
  end
  
  it "should tell about -L" do
    @ohai.options.should have_key(:log_location)
    @ohai.options[:log_location][:on].should eql(:on)
    @ohai.options[:log_location][:short].should eql("-L LOGLOCATION")
  end
  
  it "[OHAI-144] help should tell about attributes" do
    @ohai.options.should have_key(:help)
    @ohai.options[:help][:on].should eql(:tail)
    @ohai.options[:help][:description].should match(/attributes/)
  end
  
end
