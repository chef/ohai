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
require 'sigar'

describe Ohai::System, "network plugin" do

  before(:each) do
    @ohai = Ohai::System.new
    @interface_list=%w(lo eth0 eth1 vboxnet0)
    @sigar=mock('Sigar')
    @net_info=mock('Sigar::NetInfo')
    @net_interface_conf={
      :eth0 => {
        :flags => 2115,
        :destination => "192.168.1.1",
        :mtu => 1500,
        :type => "Ethernet",
        :hwaddr => "00:11:22:33:44:55:66",
        :address => "192.168.1.1",
        :broadcast => "192.168.1.255",
        :netmask => "255.255.255.0",
        :address6 => nil,
    },
      :eth1 => {
        :flags => 2115,
        :destination => "192.168.2.1",
        :mtu => 1500,
        :type => "Ethernet",
        :hwaddr => "00:11:22:33:44:55:67",
        :address => "192.168.2.1",
        :broadcast => "192.168.2.255",
        :netmask => "255.255.255.0",
        :address6 => nil,
    },
      :lo => {
        :flags => 73,
        :destination => "127.0.0.1",
        :mtu => 16436,
        :type => "Local loopback",
        :hwaddr => "00:00:00:00:00:00",
        :address => "127.0.0.1",
        :broadcast => "0.0.0.0",
        :netmask => "255.255.255.255",
        :address6 => nil,
    },
      :vboxnet0 => {
        :flags => 2050,
        :destination => "0.0.0.0",
        :mtu => 1500,
        :type => "Ethernet",
        :hwaddr => "0A:00:27:00:00:00",
        :address => "0.0.0.0",
        :broadcast => "0.0.0.0",
        :netmask => "0.0.0.0",
        :address6 => "::",
        :prefix6_length => 0,
        :scope6 => 0
    }}
    @net_info.stub!(:default_gateway).and_return("127.0.0.1")
    @net_info.stub!(:primary_dns).and_return("127.0.0.1")
    @net_info.stub!(:secondary_dns).and_return("127.0.0.2")
    @net_info.stub!(:default_gateway_interface).and_return("eth1")
    Sigar.should_receive(:new).and_return(@sigar)
    @sigar.should_receive(:net_info).exactly(4).times.and_return(@net_info)
    @sigar.should_receive(:net_interface_list).once.and_return(@interface_list)
    @interface_list.each do |interface|
      net_config=mock('Sigar::NetConf')
      @net_interface_conf[interface.to_sym].each_pair do |k,v|
        net_config.stub!(k.to_sym).and_return(v)
      end
      @sigar.should_receive(:net_interface_config).with(interface).once.and_return(net_config)
      @sigar.should_receive(:net_interface_stat).with(interface).once.and_return(nil)
    end
    @ohai.stub!(:require_plugin).and_return(true)
    @ohai._require_plugin("network")
    print "Network data: "
    p @ohai[:network]
  end

  it "should get the default gateway" do
    @ohai[:network][:default_gateway].should eql("127.0.0.1")
  end
  
  it "should get the secondary dns" do
    @ohai[:network][:secondary_dns].should eql("127.0.0.2")
  end
  
  it "should get the default_interface" do
    @ohai[:network][:default_interface].should eql("eth1")
  end
  
  it "should get the interface list" do
    @ohai[:network][:interfaces].should have_key("lo")
    @ohai[:network][:interfaces].should have_key("eth0")
    @ohai[:network][:interfaces].should have_key("eth1")
    @ohai[:network][:interfaces].should have_key("vboxnet0")
  end
  
end
