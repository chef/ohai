#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008, 2012 Opscode, Inc.
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

require File.expand_path("../../../spec_helper", __FILE__)

describe Ohai::DSL::Plugin do
  before(:each) do
    @ohai = Ohai::System.new
    @plugin = Ohai::DSL::Plugin.new(@ohai, "")
  end

  describe "when accessing data via method_missing" do

    it "should take a missing method and store the method name as a key, with its arguments as values" do
      @plugin.guns_n_roses("chinese democracy")
      @plugin.data["guns_n_roses"].should eql("chinese democracy")
    end

    it "should return the current value of the method name" do
      @plugin.guns_n_roses("chinese democracy").should eql("chinese democracy")
    end

    it "should allow you to get the value of a key by calling method_missing with no arguments" do
      @plugin.guns_n_roses("chinese democracy")
      @plugin.guns_n_roses.should eql("chinese democracy")
    end
  end

  describe "when checking attribute existence" do
    before(:each) do
      @plugin.metallica("death magnetic")
    end

    it "should return true if an attribute exists with the given name" do
      @plugin.attribute?("metallica").should eql(true)
    end

    it "should return false if an attribute does not exist with the given name" do
      @plugin.attribute?("alice in chains").should eql(false)
    end
  end

  describe "when setting attributes" do
    it "should let you set an attribute" do
      @plugin.set_attribute(:tea, "is soothing")
      @plugin.data["tea"].should eql("is soothing")
    end
  end

  describe "when getting attributes" do
    before(:each) do
      @plugin.set_attribute(:tea, "is soothing")
    end

    it "should let you get an attribute" do
      @plugin.get_attribute("tea").should eql("is soothing")
    end
  end
end

