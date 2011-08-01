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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require 'sigar'
require 'ohai'

describe Ohai::System, "Sigar network plugin" do

  before(:each) do
    @ohai = Ohai::System.new
    @interface_list=%w(lo eth0 eth1 vboxnet0)
    @sigar=double("Sigar")
    @net_info=double("Sigar::NetInfo")
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
        :tx_queue_len => 1000,
        :prefix6_length => 0,
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
        :tx_queue_len => 1000,
        :prefix6_length => 0,
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
        :tx_queue_len => 0,
        :prefix6_length => 0,
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
        :scope6 => 0,
        :tx_queue_len => 1000
    }}
    @net_interface_stat={
      :eth0 => {
        :rx_bytes=>1369035618, 
        :rx_dropped=>0,
        :rx_errors=>0,
        :rx_frame=>0,
        :rx_overruns=>0,
        :rx_packets=>7271669,
        :speed=>-1,
        :tx_bytes=>3482843666,
        :tx_carrier=>0,
        :tx_collisions=>0,
        :tx_dropped=>0,
        :tx_errors=>0,
        :tx_overruns=>0,
        :tx_packets=>4392794
      },
      :eth1 => {
        :rx_bytes=>335127,
        :rx_dropped=>0,
        :rx_errors=>0,
        :rx_frame=>0,
        :rx_overruns=>0,
        :rx_packets=>2402,
        :speed=>-1,
        :tx_bytes=>335126,
        :tx_carrier=>0,
        :tx_collisions=>0,
        :tx_dropped=>0,
        :tx_errors=>0,
        :tx_overruns=>0,
        :tx_packets=>2402
      },
      :vboxnet0 => {
        :rx_bytes=> 535126,
        :rx_dropped=>0,
        :rx_errors=>3,
        :rx_frame=>0,
        :rx_overruns=>7,
        :rx_packets=>2402,
        :speed=>-1,
        :tx_bytes=>5126,
        :tx_carrier=>3,
        :tx_collisions=>2,
        :tx_dropped=>1,
        :tx_errors=>0,
        :tx_overruns=>7,
        :tx_packets=>2402
      },
      :lo => {
        :rx_bytes=>335126,
        :rx_dropped=>0,
        :rx_errors=>0,
        :rx_frame=>0,
        :rx_overruns=>0,
        :rx_packets=>2402,
        :speed=>-1,
        :tx_bytes=>335126,
        :tx_carrier=>0,
        :tx_collisions=>0,
        :tx_dropped=>0,
        :tx_errors=>0,
        :tx_overruns=>0,
        :tx_packets=>2402
      }
    }
    @net_arp=double("Sigar::Arp")
    @net_arp.stub(:address).and_return("192.168.1.5")
    @net_arp.stub(:flags).and_return("2")
    @net_arp.stub(:hwaddr).and_return("00:15:62:96:01:D0")
    @net_arp.stub(:ifname).and_return("eth0")
    @net_arp.stub(:type).and_return("ether")
    @net_info.stub(:default_gateway).and_return("192.168.1.254")
    @net_info.stub(:primary_dns).and_return("192.168.1.254")
    @net_info.stub(:secondary_dns).and_return("8.8.8.8")
    @net_info.stub(:default_gateway_interface).and_return("eth1")
    @sigar.should_receive(:net_info).once.and_return(@net_info)
    @sigar.should_receive(:net_interface_list).once.and_return(@interface_list)
    @sigar.should_receive(:arp_list).once.and_return([@net_arp])
    @interface_list.each do |interface|
      net_config=double('Sigar::NetConf')
      @net_interface_conf[interface.to_sym].each_pair do |k,v|
        net_config.stub!(k.to_sym).and_return(v)
      end
      net_stat=double('Sigar::NetStat')
      @net_interface_stat[interface.to_sym].each_pair do |k,v|
        net_stat.stub!(k.to_sym).and_return(v)
      end
      @sigar.should_receive(:net_interface_config).with(interface).once.and_return(net_config)
      @sigar.should_receive(:net_interface_stat).with(interface).once.and_return(net_stat)
    end
    Sigar.should_receive(:new).and_return(@sigar)
    @ohai.require_plugin("os")
    @ohai[:os]="sigar"
    @ohai.require_plugin("network")
  end
  
  it "should get the default gateway" do
    @ohai[:network][:default_gateway].should eql("192.168.1.254")
  end
  
  it "should get the secondary dns" do
    @ohai[:network][:secondary_dns].should eql("8.8.8.8")
  end
  
  it "should get the default_interface" do
    @ohai[:network][:default_interface].should eql("eth1")
  end
  
  it "should get the interface list" do
    @interface_list.each do |interface|
      @ohai[:network][:interfaces].should have_key(interface)
    end
  end

  it "should get the interface config details" do
    @interface_list.each do |interface|
      @net_interface_conf[interface.to_sym].each_pair do |k,v|
        next if ["flags","type"].member?(k.to_s)
        @ohai[:network][:interfaces][interface][k].should eql(v) if @ohai[:network][:interfaces][interface].has_key?(k)
      end
    end
  end

  it "should get the interface stat details" do
    @interface_list.each do |interface|
      if @net_interface_stat.has_key?(interface.to_sym)
        @net_interface_stat[interface.to_sym].each_pair do |k,v|
          [:rx,:tx].each do |stat|
            @ohai[:counters][:network][:interfaces][interface][stat][k].should eql(v) if @ohai[:counters][:network][:interfaces][interface].has_key?(stat) && @ohai[:counters][:network][:interfaces][interface][stat].has_key?(k)
          end
        end
      end
    end
  end

end
