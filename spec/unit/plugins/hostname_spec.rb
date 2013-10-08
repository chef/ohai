#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Ohai::System, "hostname plugin" do
  before(:each) do
    @plugin = get_plugin("hostname")
    @plugin.stub(:collect_os).and_return(:default)
  end

  it "should set the domain to everything after the first dot of the fqdn" do
    @plugin[:fqdn] = "katie.bethell"
    @plugin.run
    @plugin[:domain].should == "bethell"
  end

  it "should not set a domain if fqdn is not set" do
    @plugin.run
    @plugin[:domain].should == nil
  end
    
end
