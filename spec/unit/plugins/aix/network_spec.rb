#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "AIX network plugin" do

  before(:each) do
    @route_n_get_0 = <<-ROUTE_N_GET_0
   route to: default
destination: default
       mask: default
    gateway: 172.29.128.13
  interface: en0
interf addr: 172.29.174.58
      flags: <UP,GATEWAY,DONE>
 recvpipe  sendpipe  ssthresh  rtt,msec    rttvar  hopcount      mtu     expire
       0         0         0         0         0         0         0       -79
ROUTE_N_GET_0

    @lsdev_Cc_if = <<-LSDEV_CC_IF
en0 Available  Standard Ethernet Network Interface
LSDEV_CC_IF

    @ifconfig_en0 = <<-IFCONFIG_EN0
en0: flags=1e080863,480<UP,BROADCAST,NOTRAILERS,RUNNING,SIMPLEX,MULTICAST,GROUPRT,64BIT,CHECKSUM_OFFLOAD(ACTIVE),CHAIN> metric 1
        inet 172.29.174.58 netmask 0xffffc000 broadcast 172.29.191.255
        inet 172.29.174.59 broadcast 172.29.191.255
        inet 172.29.174.60 netmask 0xffffc000 broadcast 172.29.191.255
        inet6 ::1%1/0
     tcp_sendspace 262144 tcp_recvspace 262144 rfc1323 1
IFCONFIG_EN0

    @netstat_nrf_inet = <<-NETSTAT_NRF_INET
Destination        Gateway           Flags   Refs     Use  If   Exp  Groups
Route Tree for Protocol Family 2 (Internet):
default            172.29.128.13     UG        0    587683 en0      -      -
172.29.128.0       172.29.174.58     UHSb      0         0 en0      -      -   =>
172.29.128/18      172.29.174.58     U         7   1035485 en0      -      -
172.29.191.255     172.29.174.58     UHSb      0         1 en0      -      -
NETSTAT_NRF_INET

    @aix_arp_an = <<-ARP_AN
  ? (172.29.131.16) at 6e:87:70:0:40:3 [ethernet] stored in bucket 16

  ? (10.153.50.202) at 34:40:b5:ab:fb:5a [ethernet] stored in bucket 40

  ? (10.153.1.99) at 52:54:0:8e:f2:fb [ethernet] stored in bucket 58

  ? (172.29.132.250) at 34:40:b5:a5:d7:1e [ethernet] stored in bucket 59

  ? (172.29.132.253) at 34:40:b5:a5:d7:2a [ethernet] stored in bucket 62

  ? (172.29.128.13) at 60:73:5c:69:42:44 [ethernet] stored in bucket 139

bucket:    0     contains:    0 entries
There are 6 entries in the arp table.
ARP_AN

    @ohai = Ohai::System.new
    @ohai.stub(:require_plugin).and_return(true)
    @ohai[:network] = Mash.new
    @ohai.stub(:popen4).with("route -n get 0").and_yield(nil, StringIO.new, StringIO.new(@route_n_get_0), nil)
    @ohai.stub(:popen4).with("lsdev -Cc if").and_yield(nil, StringIO.new, StringIO.new(@lsdev_Cc_if), nil)
    @ohai.stub(:popen4).with("ifconfig en0").and_yield(nil, StringIO.new, StringIO.new(@ifconfig_en0), nil)
    @ohai.stub(:popen4).with("entstat -d en0 | grep \"Hardware Address\"").and_yield(nil, StringIO.new, StringIO.new("Hardware Address: be:42:80:00:b0:05"), nil)
    @ohai.stub(:popen4).with("netstat -nrf inet").and_yield(nil, StringIO.new, StringIO.new(@netstat_nrf_inet), nil)
    @ohai.stub(:popen4).with("netstat -nrf inet6").and_yield(nil, StringIO.new, StringIO.new("::1%1  ::1%1  UH 1 109392 en0  -  -"), nil)
    @ohai.stub(:popen4).with("arp -an").and_yield(nil, StringIO.new, StringIO.new(@aix_arp_an), nil)
    @ohai._require_plugin("aix::network")    
  end

  describe "run" do

    it "detects network information" do
      @ohai['network'].should_not be_nil
    end

    it "detects the interfaces" do
      @ohai['network']['interfaces'].keys.sort.should == ["en0"]
    end

    it "detects the ip addresses of the interfaces" do
      @ohai['network']['interfaces']['en0']['addresses'].keys.should include('172.29.174.58')
    end
  end

  describe "route -n get 0" do

    it "returns the default gateway of the system's network" do
      @ohai[:network][:default_gateway].should == '172.29.128.13'
    end

    it "returns the default interface of the system's network" do
      @ohai[:network][:default_interface].should == 'en0'
    end
  end

  describe "lsdev -Cc if" do

    it "detects the state of the interfaces in the system" do
      @ohai['network']['interfaces']['en0'][:state].should == "up"
    end

    it "detects the description of the interfaces in the system" do
      @ohai['network']['interfaces']['en0'][:description].should == "Standard Ethernet Network Interface"
    end

    describe "ifconfig interface" do
      it "detects the CHAIN network flag" do
        @ohai['network']['interfaces']['en0'][:flags].should include('CHAIN')
      end

      it "detects the metric network flag" do
        @ohai['network']['interfaces']['en0'][:metric].should == '1'
      end

      context "inet entries" do
        before do
          @inet_entry = @ohai['network']['interfaces']['en0'][:addresses]["172.29.174.58"]
        end
        it "detects the family" do
          @inet_entry[:family].should == 'inet'
        end

        it "detects the netmask" do
          @inet_entry[:netmask].should == '255.255.192.0'
        end

        it "detects the broadcast" do
          @inet_entry[:broadcast].should == '172.29.191.255'
        end

        it "detects all key-values" do
          @ohai['network']['interfaces']['en0'][:tcp_sendspace].should == "262144"
          @ohai['network']['interfaces']['en0'][:tcp_recvspace].should == "262144"
          @ohai['network']['interfaces']['en0'][:rfc1323].should == "1"
        end

        # For an output with no netmask like inet 172.29.174.59 broadcast 172.29.191.255
        context "with no netmask in the output" do
          before do
            @inet_entry = @ohai['network']['interfaces']['en0'][:addresses]["172.29.174.59"]
            @ohai.stub(:popen4).with("ifconfig en0").and_yield(nil, StringIO.new, StringIO.new("inet 172.29.174.59 broadcast 172.29.191.255"), nil)
          end

          it "detects the default prefixlen" do
            @inet_entry[:prefixlen].should == '32'
          end

          it "detects the default netmask" do
            @inet_entry[:netmask].should == '255.255.255.255'
          end
        end
      end

      context "inet6 entries" do
        before do
          @inet_entry = @ohai['network']['interfaces']['en0'][:addresses]["::1%1"]
          @ohai.stub(:popen4).with("ifconfig en0").and_yield(nil, StringIO.new, StringIO.new("inet6 ::1%1/0"), nil)
        end

        it "detects the prefixlen" do
          @inet_entry[:prefixlen].should == '0'
        end

        it "detects the family" do
          @inet_entry[:family].should == 'inet6'
        end
      end
    end

    context "entstat -d interface" do
      before do
        @inet_interface_addresses = @ohai['network']['interfaces']['en0'][:addresses]["BE:42:80:00:B0:05"]
      end
      it "detects the family" do
        @inet_interface_addresses[:family].should == 'lladdr'
      end
    end
  end

  describe "netstat -nrf family" do
    context "inet" do

      it "detects the route destinations" do
        @ohai['network']['interfaces']['en0'][:routes][0][:destination].should == "default"
        @ohai['network']['interfaces']['en0'][:routes][1][:destination].should == "172.29.128.0"
      end

      it "detects the route family" do
        @ohai['network']['interfaces']['en0'][:routes][0][:family].should == "inet"
      end

      it "detects the route gateway" do
        @ohai['network']['interfaces']['en0'][:routes][0][:via].should == "172.29.128.13"
      end

      it "detects the route flags" do
        @ohai['network']['interfaces']['en0'][:routes][0][:flags].should == "UG"
      end
    end

    context "inet6" do

      it "detects the route destinations" do
        @ohai['network']['interfaces']['en0'][:routes][4][:destination].should == "::1%1"
      end

      it "detects the route family" do
        @ohai['network']['interfaces']['en0'][:routes][4][:family].should == "inet6"
      end

      it "detects the route gateway" do
        @ohai['network']['interfaces']['en0'][:routes][4][:via].should == "::1%1"
      end

      it "detects the route flags" do
        @ohai['network']['interfaces']['en0'][:routes][4][:flags].should == "UH"
      end
    end
  end

  describe "arp -an" do

    it "supresses the hostname entries" do
      @ohai['network']['arp'][0][:remote_host].should == "?"
    end

    it "detects the remote ip entry" do
      @ohai['network']['arp'][0][:remote_ip].should == "172.29.131.16"
    end

    it "detects the remote mac entry" do
      @ohai['network']['arp'][0][:remote_mac].should == "6e:87:70:0:40:3"
    end
  end

  describe "hex_to_dec_netmask method" do
    it "converts a netmask from hexadecimal form to decimal form" do
      @ohai.hex_to_dec_netmask('0xffff0000').should == "255.255.0.0"
    end
  end
end
