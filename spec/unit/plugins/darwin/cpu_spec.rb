#
# Author:: Nathan L Smith (<nlloyds@gmail.com>)
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


require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "Darwin cpu plugin" do
  before(:each) do
    @plugin = get_plugin("darwin/cpu")
    
    @plugin.stub(:from).with("sysctl -n hw.physicalcpu").and_return("1")
    @plugin.stub(:from).with("sysctl -n hw.logicalcpu").and_return("2")
  end

  it "should set cpu[:total] to 2" do
    @plugin.run
    @plugin[:cpu][:total].should == 2
  end

  it "should set cpu[:real] to 1" do
    @plugin.run
    @plugin[:cpu][:real].should == 1
  end
end
