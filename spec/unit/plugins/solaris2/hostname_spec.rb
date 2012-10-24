#
# Author:: Daniel DeLeo <dan@kallistec.com>
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

describe Ohai::System, "Solaris2.X hostname plugin" do
  before(:each) do
    @ohai = Ohai::System.new    
    @plugin = Ohai::DSL::Plugin.new(@ohai, File.expand_path("solaris2/hostname.rb", PLUGIN_PATH))
    @plugin.stub!(:require_plugin).and_return(true)
    @plugin[:os] = "solaris2"
    @plugin.stub!(:from).with("hostname").and_return("kitteh")
    Socket.stub!(:getaddrinfo).and_return( [["AF_INET", 0, "kitteh.inurfridge.eatinurfoodz", "10.1.2.3", 2, 0, 0]] );
  end
  
  it_should_check_from("solaris2::hostname", "hostname", "hostname", "kitteh")
  
  it "should get the fqdn value from socket getaddrinfo" do
    Socket.should_receive(:getaddrinfo)
    @plugin.run
    @plugin["fqdn"].should == "kitteh.inurfridge.eatinurfoodz"
  end
  
end
