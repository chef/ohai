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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Ohai::System, "Network plugin" do

  before(:each) do
    @ohai = Ohai::System.new
    @ohai.require_plugin("network")
  end
  
  it "should get the list of interfaces" do
    @ohai[:network][:interfaces].should have_at_least(1).items
  end
  
  it "should have the loopback interface" do
    @ohai[:network][:interfaces].keys.grep(/lo/).should have_at_least(1).items
  end
  
  it "should have the default interface set" do
    @ohai[:network].should have_key(:default_interface)
  end
  
  it "should have the default gateway set" do
    @ohai[:network].should have_key(:default_gateway)
  end
  
  it "should have addresses defined on interfaces" do
    @ohai[:network][:interfaces].each_key do |interface|
      @ohai[:network][:interfaces][interface][:addresses].should have_at_least(1).item
    end
  end
  
  it "should have encapsulation defined on interfaces" do
    @ohai[:network][:interfaces].each_key do |interface|
      @ohai[:network][:interfaces][interface].should have_key(:encapsulation)
    end
  end
  
  it "should have flags defined on interfaces" do
    @ohai[:network][:interfaces].each_key do |interface|
      @ohai[:network][:interfaces][interface].should have_key(:flags)
    end
  end
  
end
