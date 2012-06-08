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

sigar_available = begin
  require 'sigar'
  true
rescue LoadError
  false
end

require 'ohai'

describe Ohai::System, "Sigar network route plugin" do

  if sigar_available

    before(:each) do
      @ohai = Ohai::System.new
      @sigar = double("Sigar")
      @net_info_conf={
        :default_gateway => "192.168.1.254",
        :default_gateway_interface => "eth0",
        :primary_dns => "192.168.1.254",
        :secondary_dns => "8.8.8.8",
        :host_name => "localhost"
      }
      net_info=double("Sigar::NetInfo")
      @net_info_conf.each_pair do |k,v|
        net_info.stub(k).and_return(v)
      end
      @net_route_conf={
        :destination => "192.168.1.0",
        :gateway => "0.0.0.0",
        :mask => "255.255.255.0",
        :flags => 1,
        :refcnt => 0,
        :use => 0,
        :metric => 0,
        :mtu => 0,
        :window => 0,
        :irtt => 0,
        :ifname => "eth0"
      }
      net_route=double("Sigar::NetRoute")
      @net_route_conf.each_pair do |k,v|
        net_route.stub(k).and_return(v)
      end
      @net_interface_conf={
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
      }
      net_conf=double("Sigar::NetConf")
      @net_interface_conf.each_pair do |k,v|
        net_conf.stub(k).and_return(v)
      end
      @net_interface_stat={
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
      }
      net_stat=double("Sigar::NetStat")
      @net_interface_stat.each_pair do |k,v|
        net_stat.stub(k).and_return(v)
      end
      @net_arp_conf={
        :address => "192.168.1.5",
        :flags => 2,
        :hwaddr => "00:15:62:96:01:D0",
        :ifname => "eth0",
        :type => "ether",
      }
      net_arp=double("Sigar::NetArp")
      @net_arp_conf.each_pair do |k,v|
        net_arp.stub(k).and_return(v)
      end
      @sigar.stub(:fqdn).and_return("localhost.localdomain")
      @sigar.should_receive(:net_info).at_least(2).times.and_return(net_info)
      @sigar.should_receive(:net_interface_list).once.and_return(["eth0"])
      @sigar.should_receive(:net_interface_config).with("eth0").and_return(net_conf)
      @sigar.should_receive(:net_interface_stat).with("eth0").and_return(net_stat)
      @sigar.should_receive(:arp_list).once.and_return([net_arp])

      # Since we mock net_route_list here, flags never gets called
      @sigar.should_receive(:net_route_list).once.and_return([net_route])
      Sigar.should_receive(:new).at_least(2).times.and_return(@sigar)
      @ohai.require_plugin("os")
      @ohai[:os]="sigar"
      Ohai::Log.should_receive(:warn).with(/unable to detect ip6address/).once
      @ohai.require_plugin("network")
      @ohai.require_plugin("sigar::network_route")
    end

    it "should set the routes" do
      @ohai[:network][:interfaces][:eth0].should have_key(:route)
    end

    it "should set the route details" do
      @net_route_conf.each_pair do |k,v|
        # Work around the above mocking of net_route_list skipping the call to flags()
        if k == :flags
          v="U"
          @ohai[:network][:interfaces][:eth0][:route]["192.168.1.0"][k] = v
        end
        @ohai[:network][:interfaces][:eth0][:route]["192.168.1.0"].should have_key(k)
        @ohai[:network][:interfaces][:eth0][:route]["192.168.1.0"][k].should eql(v)
      end
    end

  else
    pending "Sigar not available, skipping sigar tests"
  end
end
