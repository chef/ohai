#
# Author:: Philip (flip) Kromer (<flip@infochimps.com>)
# Copyright:: Copyright (c) 2011 Infochimps, Inc.
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

describe Ohai::System, "plugin virtualbox" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai[:virtualization] = Mash.new({ :system => 'vbox', :role => 'guest'})
    @ohai.stub!(:require_plugin).and_return(true)
    @data = Mash.new({
        :host_info  => { "gui" => { "language_id" => "en_US" }, "v_box_ver" => "4.1.6" },
        :guest_info => {
          :os => { "product" => "Linux", "release" => "2.6.38-8-server" },
          :net => {
            "0" => { "v4" => { "ip" => "10.12.14.16", "broadcast" => "10.0.2.255",   "netmask" => "255.255.255.0"}, "mac" => "08002760826E", "status" => "Up"},
            "1" => { "v4" => { "ip" => "33.33.33.12", "broadcast" => "33.33.33.255", "netmask" => "255.255.255.0"}, "mac" => "080027678BD1", "status" => "Up"},
            "2" => { "v4" => { "ip" => "192.168.1.9" } },
            "3" => { "v4" => { "ip" => "128.64.32.8" } },
            "count" => "4",
          }
        }
      })
    @status = 0
    @stdout = %Q{
Name: /VirtualBox/HostInfo/GUI/LanguageID, value: en_US, timestamp: 1322442422325114000, flags: <NULL>
Name: /VirtualBox/GuestInfo/OS/Product, value: Linux, timestamp: 1322321247819992000, flags: <NULL>
Name: /VirtualBox/GuestInfo/OS/Release, value: 2.6.38-8-server, timestamp: 1322321247821314000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/0/V4/IP, value: 10.12.14.16, timestamp: 1322321247834769000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/0/V4/Broadcast, value: 10.0.2.255, timestamp: 1322321247835088000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/0/V4/Netmask, value: 255.255.255.0, timestamp: 1322321247835363000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/0/MAC, value: 08002760826E, timestamp: 1322321247835622000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/0/Status, value: Up, timestamp: 1322321247835888000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/1/V4/IP, value: 33.33.33.12, timestamp: 1322321247836167000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/1/V4/Broadcast, value: 33.33.33.255, timestamp: 1322321247836423000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/1/V4/Netmask, value: 255.255.255.0, timestamp: 1322321247836686000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/1/MAC, value: 080027678BD1, timestamp: 1322321247836958000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/1/Status, value: Up, timestamp: 1322321247837225000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/2/V4/IP, value: 192.168.1.9, timestamp: 1322321247836167000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/3/V4/IP, value: 128.64.32.8, timestamp: 1322321247836167000, flags: <NULL>
Name: /VirtualBox/GuestInfo/Net/Count, value: 4, timestamp: 1322451057929680000, flags: <NULL>
Name: /VirtualBox/HostInfo/VBoxVer, value: 4.1.6, timestamp: 1322321213817426000, flags: TRANSIENT, RDONLYGUEST
}
    @stderr = ""
    @ext    = (RUBY_PLATFORM =~ /mswin|mingw32|windows/) ? ".exe" : ""
    @ohai.stub!(:run_command).with({:no_status_check=>true, :command=>"VBoxControl#{@ext} guestproperty enumerate"}).and_return([@status, @stdout, @stderr])
  end

  describe "using VboxControl sniffer" do

    it "should sniff the virtualbox info using VBoxControl" do
      @ohai.should_receive(:run_command).with({:no_status_check=>true, :command=>"VBoxControl#{@ext} guestproperty enumerate"}).and_return([@status, @stdout, @stderr])
      @ohai._require_plugin("virtualbox")
    end

    it "should parse the virtualbox sniffer correctly" do
      @ohai._require_plugin("virtualbox")
      @ohai[:virtualbox][:host_info].should  == @data[:host_info]
      @ohai[:virtualbox][:guest_info].should == @data[:guest_info]
      @ohai[:virtualbox][:guest_info][:net][0].should be_nil
      @ohai[:virtualbox][:guest_info][:net]["count"].should == "4"
    end

    it "should set up the virtualbox tree, but fill it with sadness if the virtualbox command fails" do
      @status = 1
      @ohai.stub!(:run_command).with({:no_status_check=>true, :command=>"VBoxControl#{@ext} guestproperty enumerate"}).and_return([@status, @stdout, @stderr])
      @ohai._require_plugin("virtualbox")
      @ohai.virtualbox[:cannot_sniff].should == true
      @ohai.virtualbox[:guest_info].should be_nil
      @ohai.virtualbox[:host_info].should  be_nil
    end
  end

  describe "guessing public/private ips" do
    describe "with sniffed info" do
      it "correctly and in order" do
        @ohai._require_plugin("virtualbox")
        @ohai.get_net_info_from_sniffed.should == ['10.12.14.16', '33.33.33.12', '192.168.1.9', '128.64.32.8']
      end
    end
    describe "with network info" do
      before(:each) do
        @ohai.network Mash.new({
            :interfaces => {
              'eth1' => { :addresses => { '33.33.33.12' => { :family => 'inet' }, '08:00:27:67:8b:d1' => { :family => 'lladdr' } } },
              'eth2' => { :addresses => { '192.168.1.9' => { :family => 'inet' }, '08:00:12:34:56:78' => { :family => 'lladdr' } } },
              'eth3' => { :addresses => { '128.64.32.8' => { :family => 'inet' }, '08:00:98:76:54:32' => { :family => 'lladdr' } } },
              'eth0' => { :addresses => { '10.12.14.16' => { :family => 'inet' }, '08:00:27:60:82:6e' => { :family => 'lladdr' } } },
              'lo'   => { :addresses => { '127.0.0.1'   => { :family => 'inet' }, '::1' => { :family => 'inet6' } }, :encapsulation => 'Loopback' },
            },
            :default_interface => 'eth0'
          })
        @ohai.stub!(:run_command).with({:no_status_check=>true, :command=>"VBoxControl#{@ext} guestproperty enumerate"}).and_return([1, @stdout, @stderr])
        @ohai._require_plugin("virtualbox")
      end
      it "correctly" do
        @ohai.get_net_info_from_network.should == ['10.12.14.16', '33.33.33.12', '192.168.1.9', '128.64.32.8']
      end
      it "lists default_interface first" do
        @ohai.network[:default_interface] = 'eth2'
        @ohai.get_net_info_from_network.should == ['192.168.1.9', '10.12.14.16', '33.33.33.12', '128.64.32.8']
      end
    end
    describe "normalizing" do
      def with_ips(ips)
        @ohai._require_plugin("virtualbox")
        @ohai.stub!(:get_net_info_from_sniffed).and_return(ips)
        @ohai.normalize_virtualbox_info
      end
      it "correctly and in order" do
        with_ips(['10.12.14.16', '33.33.33.12', '192.168.1.9', '128.64.32.8'])
        @ohai.virtualbox[:private_ips].should  == ['10.12.14.16', '33.33.33.12', '192.168.1.9']
        @ohai.virtualbox[:local_ipv4].should   ==  '33.33.33.12'
        @ohai.virtualbox[:public_ips].should   == ['128.64.32.8']
        @ohai.virtualbox[:public_ipv4].should  ==  '128.64.32.8'
      end
      it "with no public ips, kidnaps first non-host-local ip" do
        with_ips(['10.12.14.16', '33.33.33.12'])
        @ohai.virtualbox[:private_ips].should  == ['33.33.33.12']
        @ohai.virtualbox[:local_ipv4].should   ==  '33.33.33.12'
        @ohai.virtualbox[:public_ips].should   == ['10.12.14.16']
        @ohai.virtualbox[:public_ipv4].should  ==  '10.12.14.16'
        with_ips(['33.33.33.12', '10.12.14.16'])
        @ohai.virtualbox[:private_ips].should  == ['33.33.33.12']
        @ohai.virtualbox[:public_ips].should   == ['10.12.14.16']
        with_ips(['33.33.33.12', '33.33.33.40'])
        @ohai.virtualbox[:private_ips].should  == ['33.33.33.12', '33.33.33.40']
        @ohai.virtualbox[:public_ips].should   == []
      end
      it "is ok even if no private IPs" do
        with_ips(['8.8.8.8', '128.64.32.8'])
        @ohai.virtualbox[:private_ips].should  == []
        @ohai.virtualbox[:local_ipv4].should   ==  nil
        @ohai.virtualbox[:public_ips].should   == ['8.8.8.8', '128.64.32.8']
        @ohai.virtualbox[:public_ipv4].should  ==  '8.8.8.8'
      end
    end
  end
end


