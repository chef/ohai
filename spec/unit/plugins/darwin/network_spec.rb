#
#  Author:: Alan Harper <alan@aussiegeek.net>
#  Copyright:: Copyright (c) 2012 Opscode, Inc.
#  License:: Apache License, Version 2.0
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "Darwin Network Plugin" do
  before do
    darwin_ifconfig = <<-DARWIN_IFCONFIG
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
        options=3<RXCSUM,TXCSUM>
        inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1
        inet 127.0.0.1 netmask 0xff000000
        inet6 ::1 prefixlen 128
        inet6 fd54:185f:37df:cad2:ba8d:12ff:fe3a:32de prefixlen 128
gif0: flags=8010<POINTOPOINT,MULTICAST> mtu 1280
stf0: flags=0<> mtu 1280
en1: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
        ether b8:8d:12:3a:32:de
        inet6 fe80::ba8d:12ff:fe3a:32de%en1 prefixlen 64 scopeid 0x4
        inet 10.20.10.144 netmask 0xffffff00 broadcast 10.20.10.255
        inet6 2001:44b8:4186:1100:ba8d:12ff:fe3a:32de prefixlen 64 autoconf
        inet6 2001:44b8:4186:1100:7dba:7a60:97a:e14a prefixlen 64 autoconf temporary
        media: autoselect
        status: active
p2p0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> mtu 2304
        ether 0a:8d:12:3a:32:de
        media: autoselect
        status: inactive
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
        options=2b<RXCSUM,TXCSUM,VLAN_HWTAGGING,TSO4>
        ether 3c:07:54:4e:0e:35
        media: autoselect (none)
        status: inactive
fw0: flags=8822<BROADCAST,SMART,SIMPLEX,MULTICAST> mtu 4078
        lladdr a4:b1:97:ff:fe:b9:3a:d4
        media: autoselect <full-duplex>
        status: inactive
utun0: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1380
        inet6 fe80::ba8d:12ff:fe3a:32de%utun0 prefixlen 64 scopeid 0x8
        inet6 fd00:6587:52d7:c87:ba8d:12ff:fe3a:32de prefixlen 64
    DARWIN_IFCONFIG

    darwin_arp = <<-DARWIN_ARP
? (10.20.10.1) at 0:4:ed:de:41:bf on en1 ifscope [ethernet]
? (10.20.10.2) at 0:1e:c9:55:7e:ee on en1 ifscope [ethernet]
? (10.20.10.6) at 34:15:9e:18:a1:20 on en1 ifscope [ethernet]
? (10.20.10.57) at cc:8:e0:e0:8a:2 on en1 ifscope [ethernet]
? (10.20.10.61) at 28:37:37:12:5:77 on en1 ifscope [ethernet]
? (10.20.10.73) at e0:f8:47:8:86:2 on en1 ifscope [ethernet]
? (10.20.10.130) at 68:a8:6d:da:2b:24 on en1 ifscope [ethernet]
? (10.20.10.138) at 8:0:37:8c:d2:23 on en1 ifscope [ethernet]
? (10.20.10.141) at b8:8d:12:28:c5:90 on en1 ifscope [ethernet]
? (10.20.10.166) at 0:1b:63:a0:1:3a on en1 ifscope [ethernet]
? (10.20.10.174) at 98:d6:bb:bd:37:ad on en1 ifscope [ethernet]
? (10.20.10.178) at 24:ab:81:2d:a3:c5 on en1 ifscope [ethernet]
? (10.20.10.181) at 78:a3:e4:e4:16:32 on en1 ifscope [ethernet]
? (10.20.10.185) at 0:26:8:9a:e8:a3 on en1 ifscope [ethernet]
? (10.20.10.200) at b8:8d:12:55:7f:7f on en1 ifscope [ethernet]
? (10.20.10.255) at ff:ff:ff:ff:ff:ff on en1 ifscope [ethernet]
    DARWIN_ARP

    darwin_route = <<-DARWIN_ROUTE
   route to: default
destination: default
       mask: default
    gateway: 10.20.10.1
  interface: en1
      flags: <UP,GATEWAY,DONE,STATIC,PRCLONING>
 recvpipe  sendpipe  ssthresh  rtt,msec    rttvar  hopcount      mtu     expire
       0         0         0         0         0         0      1500         0
    DARWIN_ROUTE

    darwin_netstat = <<-DARWIN_NETSTAT
Name  Mtu   Network       Address            Ipkts Ierrs     Ibytes    Opkts Oerrs     Obytes  Coll Drop
lo0   16384 <Link#1>                        174982     0   25774844   174982     0   25774844     0
lo0   16384 fe80::1%lo0 fe80:1::1           174982     -   25774844   174982     -   25774844     -   -
lo0   16384 127           127.0.0.1         174982     -   25774844   174982     -   25774844     -   -
lo0   16384 ::1/128     ::1                 174982     -   25774844   174982     -   25774844     -   -
lo0   16384 fd54:185f:3 fd54:185f:37df:ca   174982     -   25774844   174982     -   25774844     -   -
gif0* 1280  <Link#2>                             0     0          0        0     0          0     0
stf0* 1280  <Link#3>                             0     0          0        0     0          0     0
en1   1500  <Link#4>    b8:8d:12:3a:32:de  5921903     0 2530556736 14314573     0 18228234970     0
en1   1500  fe80::ba8d: fe80:4::ba8d:12ff  5921903     - 2530556736 14314573     - 18228234970     -   -
en1   1500  10.20.10/24   10.20.10.144     5921903     - 2530556736 14314573     - 18228234970     -   -
en1   1500  2001:44b8:4 2001:44b8:4186:11  5921903     - 2530556736 14314573     - 18228234970     -   -
en1   1500  2001:44b8:4 2001:44b8:4186:11  5921903     - 2530556736 14314573     - 18228234970     -   -
p2p0  2304  <Link#5>    0a:8d:12:3a:32:de        0     0          0        0     0          0     0
en0   1500  <Link#6>    3c:07:54:4e:0e:35        0     0          0        0     0       2394     0
fw0*  4078  <Link#7>    a4:b1:97:ff:fe:b9:3a:d4        0     0          0        0     0       1038     0
utun0 1380  <Link#8>                             5     0        324       13     0        740     0
utun0 1380  fe80::ba8d: fe80:8::ba8d:12ff        5     -        324       13     -        740     -   -
utun0 1380  fd00:6587:5 fd00:6587:52d7:c8        5     -        324       13     -        740     -   -
    DARWIN_NETSTAT

    darwin_sysctl = <<-DARWIN_SYSCTL
net.local.stream.sendspace: 8192
net.local.stream.recvspace: 8192
net.local.stream.tracemdns: 0
net.local.dgram.maxdgram: 2048
net.local.dgram.recvspace: 4096
net.local.inflight: 0
net.inet.ip.portrange.lowfirst: 1023
net.inet.ip.portrange.lowlast: 600
net.inet.ip.portrange.first: 49152
net.inet.ip.portrange.last: 65535
net.inet.ip.portrange.hifirst: 49152
net.inet.ip.portrange.hilast: 65535
net.inet.ip.forwarding: 1
net.inet.ip.redirect: 1
net.inet.ip.ttl: 64
net.inet.ip.rtexpire: 12
net.inet.ip.rtminexpire: 10
net.inet.ip.rtmaxcache: 128
net.inet.ip.sourceroute: 0
net.inet.ip.intr_queue_maxlen: 50
net.inet.ip.intr_queue_drops: 0
net.inet.ip.accept_sourceroute: 0
net.inet.ip.keepfaith: 0
net.inet.ip.gifttl: 30
net.inet.ip.subnets_are_local: 0
net.inet.ip.mcast.maxgrpsrc: 512
net.inet.ip.mcast.maxsocksrc: 128
net.inet.ip.mcast.loop: 1
net.inet.ip.check_route_selfref: 1
net.inet.ip.use_route_genid: 1
net.inet.ip.dummynet.hash_size: 64
net.inet.ip.dummynet.curr_time: 0
net.inet.ip.dummynet.ready_heap: 0
net.inet.ip.dummynet.extract_heap: 0
net.inet.ip.dummynet.searches: 0
net.inet.ip.dummynet.search_steps: 0
net.inet.ip.dummynet.expire: 1
net.inet.ip.dummynet.max_chain_len: 16
net.inet.ip.dummynet.red_lookup_depth: 256
net.inet.ip.dummynet.red_avg_pkt_size: 512
net.inet.ip.dummynet.red_max_pkt_size: 1500
net.inet.ip.dummynet.debug: 0
net.inet.ip.fw.enable: 1
net.inet.ip.fw.autoinc_step: 100
net.inet.ip.fw.one_pass: 0
net.inet.ip.fw.debug: 0
net.inet.ip.fw.verbose: 0
net.inet.ip.fw.verbose_limit: 0
net.inet.ip.fw.dyn_buckets: 256
net.inet.ip.fw.curr_dyn_buckets: 256
net.inet.ip.fw.dyn_count: 0
net.inet.ip.fw.dyn_max: 4096
net.inet.ip.fw.static_count: 2
net.inet.ip.fw.dyn_ack_lifetime: 300
net.inet.ip.fw.dyn_syn_lifetime: 20
net.inet.ip.fw.dyn_fin_lifetime: 1
net.inet.ip.fw.dyn_rst_lifetime: 1
net.inet.ip.fw.dyn_udp_lifetime: 10
net.inet.ip.fw.dyn_short_lifetime: 5
net.inet.ip.fw.dyn_keepalive: 1
net.inet.ip.maxfragpackets: 1536
net.inet.ip.maxfragsperpacket: 128
net.inet.ip.maxfrags: 3072
net.inet.ip.scopedroute: 1
net.inet.ip.check_interface: 0
net.inet.ip.linklocal.in.allowbadttl: 1
net.inet.ip.random_id: 1
net.inet.ip.maxchainsent: 0
net.inet.ip.select_srcif_debug: 0
net.inet.icmp.maskrepl: 0
net.inet.icmp.icmplim: 250
net.inet.icmp.timestamp: 0
net.inet.icmp.drop_redirect: 0
net.inet.icmp.log_redirect: 0
net.inet.icmp.bmcastecho: 1
net.inet.igmp.recvifkludge: 1
net.inet.igmp.sendra: 1
net.inet.igmp.sendlocal: 1
net.inet.igmp.v1enable: 1
net.inet.igmp.v2enable: 1
net.inet.igmp.legacysupp: 0
net.inet.igmp.default_version: 3
net.inet.igmp.gsrdelay: 10
net.inet.igmp.debug: 0
net.inet.tcp.rfc1323: 1
net.inet.tcp.rfc1644: 0
net.inet.tcp.mssdflt: 512
net.inet.tcp.keepidle: 7200000
net.inet.tcp.keepintvl: 75000
net.inet.tcp.sendspace: 65536
net.inet.tcp.recvspace: 65536
net.inet.tcp.keepinit: 75000
net.inet.tcp.v6mssdflt: 1024
net.inet.tcp.log_in_vain: 0
net.inet.tcp.blackhole: 0
net.inet.tcp.delayed_ack: 3
net.inet.tcp.tcp_lq_overflow: 1
net.inet.tcp.recvbg: 0
net.inet.tcp.drop_synfin: 1
net.inet.tcp.reass.maxsegments: 3072
net.inet.tcp.reass.cursegments: 0
net.inet.tcp.reass.overflows: 0
net.inet.tcp.slowlink_wsize: 8192
net.inet.tcp.maxseg_unacked: 8
net.inet.tcp.rfc3465: 1
net.inet.tcp.rfc3465_lim2: 1
net.inet.tcp.rtt_samples_per_slot: 20
net.inet.tcp.recv_allowed_iaj: 5
net.inet.tcp.acc_iaj_high_thresh: 100
net.inet.tcp.rexmt_thresh: 2
net.inet.tcp.path_mtu_discovery: 1
net.inet.tcp.slowstart_flightsize: 1
net.inet.tcp.local_slowstart_flightsize: 8
net.inet.tcp.tso: 1
net.inet.tcp.ecn_initiate_out: 0
net.inet.tcp.ecn_negotiate_in: 0
net.inet.tcp.packetchain: 50
net.inet.tcp.socket_unlocked_on_output: 1
net.inet.tcp.rfc3390: 1
net.inet.tcp.min_iaj_win: 4
net.inet.tcp.acc_iaj_react_limit: 200
net.inet.tcp.sack: 1
net.inet.tcp.sack_maxholes: 128
net.inet.tcp.sack_globalmaxholes: 65536
net.inet.tcp.sack_globalholes: 0
net.inet.tcp.minmss: 216
net.inet.tcp.minmssoverload: 0
net.inet.tcp.do_tcpdrain: 0
net.inet.tcp.pcbcount: 86
net.inet.tcp.icmp_may_rst: 1
net.inet.tcp.strict_rfc1948: 0
net.inet.tcp.isn_reseed_interval: 0
net.inet.tcp.background_io_enabled: 1
net.inet.tcp.rtt_min: 100
net.inet.tcp.rexmt_slop: 200
net.inet.tcp.randomize_ports: 0
net.inet.tcp.newreno_sockets: 81
net.inet.tcp.background_sockets: -1
net.inet.tcp.tcbhashsize: 4096
net.inet.tcp.background_io_trigger: 5
net.inet.tcp.msl: 15000
net.inet.tcp.max_persist_timeout: 0
net.inet.tcp.always_keepalive: 0
net.inet.tcp.timer_fastmode_idlemax: 20
net.inet.tcp.broken_peer_syn_rxmit_thres: 7
net.inet.tcp.tcp_timer_advanced: 5
net.inet.tcp.tcp_resched_timerlist: 12209
net.inet.tcp.pmtud_blackhole_detection: 1
net.inet.tcp.pmtud_blackhole_mss: 1200
net.inet.tcp.timer_fastquantum: 100
net.inet.tcp.timer_slowquantum: 500
net.inet.tcp.win_scale_factor: 3
net.inet.tcp.in_sw_cksum: 5658081
net.inet.tcp.in_sw_cksum_bytes: 2198681467
net.inet.tcp.out_sw_cksum: 14166053
net.inet.tcp.out_sw_cksum_bytes: 17732561863
net.inet.tcp.sockthreshold: 64
net.inet.tcp.bg_target_qdelay: 100
net.inet.tcp.bg_allowed_increase: 2
net.inet.tcp.bg_tether_shift: 1
net.inet.tcp.bg_ss_fltsz: 2
net.inet.udp.checksum: 1
net.inet.udp.maxdgram: 9216
net.inet.udp.recvspace: 42080
net.inet.udp.in_sw_cksum: 19639
net.inet.udp.in_sw_cksum_bytes: 3928092
net.inet.udp.out_sw_cksum: 17436
net.inet.udp.out_sw_cksum_bytes: 2495444
net.inet.udp.log_in_vain: 0
net.inet.udp.blackhole: 0
net.inet.udp.pcbcount: 72
net.inet.udp.randomize_ports: 1
net.inet.ipsec.def_policy: 1
net.inet.ipsec.esp_trans_deflev: 1
net.inet.ipsec.esp_net_deflev: 1
net.inet.ipsec.ah_trans_deflev: 1
net.inet.ipsec.ah_net_deflev: 1
net.inet.ipsec.ah_cleartos: 1
net.inet.ipsec.ah_offsetmask: 0
net.inet.ipsec.dfbit: 0
net.inet.ipsec.ecn: 0
net.inet.ipsec.debug: 0
net.inet.ipsec.esp_randpad: -1
net.inet.ipsec.bypass: 0
net.inet.ipsec.esp_port: 4500
net.inet.raw.maxdgram: 8192
net.inet.raw.recvspace: 8192
net.link.generic.system.ifcount: 10
net.link.generic.system.dlil_verbose: 0
net.link.generic.system.multi_threaded_input: 1
net.link.generic.system.dlil_input_sanity_check: 0
net.link.ether.inet.prune_intvl: 300
net.link.ether.inet.max_age: 1200
net.link.ether.inet.host_down_time: 20
net.link.ether.inet.apple_hwcksum_tx: 1
net.link.ether.inet.apple_hwcksum_rx: 1
net.link.ether.inet.arp_llreach_base: 30
net.link.ether.inet.maxtries: 5
net.link.ether.inet.useloopback: 1
net.link.ether.inet.proxyall: 0
net.link.ether.inet.sendllconflict: 0
net.link.ether.inet.log_arp_warnings: 0
net.link.ether.inet.keep_announcements: 1
net.link.ether.inet.send_conflicting_probes: 1
net.link.bridge.log_stp: 0
net.link.bridge.debug: 0
net.key.debug: 0
net.key.spi_trycnt: 1000
net.key.spi_minval: 256
net.key.spi_maxval: 268435455
net.key.int_random: 60
net.key.larval_lifetime: 30
net.key.blockacq_count: 10
net.key.blockacq_lifetime: 20
net.key.esp_keymin: 256
net.key.esp_auth: 0
net.key.ah_keymin: 128
net.key.prefered_oldsa: 0
net.key.natt_keepalive_interval: 20
net.inet6.ip6.forwarding: 0
net.inet6.ip6.redirect: 1
net.inet6.ip6.hlim: 64
net.inet6.ip6.maxfragpackets: 1536
net.inet6.ip6.accept_rtadv: 0
net.inet6.ip6.keepfaith: 0
net.inet6.ip6.log_interval: 5
net.inet6.ip6.hdrnestlimit: 15
net.inet6.ip6.dad_count: 1
net.inet6.ip6.auto_flowlabel: 1
net.inet6.ip6.defmcasthlim: 1
net.inet6.ip6.gifhlim: 0
net.inet6.ip6.kame_version: 2009/apple-darwin
net.inet6.ip6.use_deprecated: 1
net.inet6.ip6.rr_prune: 5
net.inet6.ip6.v6only: 0
net.inet6.ip6.rtexpire: 3600
net.inet6.ip6.rtminexpire: 10
net.inet6.ip6.rtmaxcache: 128
net.inet6.ip6.use_tempaddr: 1
net.inet6.ip6.temppltime: 86400
net.inet6.ip6.tempvltime: 604800
net.inet6.ip6.auto_linklocal: 1
net.inet6.ip6.prefer_tempaddr: 1
net.inet6.ip6.use_defaultzone: 0
net.inet6.ip6.maxfrags: 12288
net.inet6.ip6.mcast_pmtu: 0
net.inet6.ip6.neighborgcthresh: 1024
net.inet6.ip6.maxifprefixes: 16
net.inet6.ip6.maxifdefrouters: 16
net.inet6.ip6.maxdynroutes: 1024
net.inet6.ip6.fw.enable: 1
net.inet6.ip6.fw.debug: 0
net.inet6.ip6.fw.verbose: 0
net.inet6.ip6.fw.verbose_limit: 0
net.inet6.ip6.scopedroute: 1
net.inet6.ip6.select_srcif_debug: 0
net.inet6.ip6.mcast.maxgrpsrc: 512
net.inet6.ip6.mcast.maxsocksrc: 128
net.inet6.ip6.mcast.loop: 1
net.inet6.ip6.only_allow_rfc4193_prefixes: 0
net.inet6.ipsec6.def_policy: 1
net.inet6.ipsec6.esp_trans_deflev: 1
net.inet6.ipsec6.esp_net_deflev: 1
net.inet6.ipsec6.ah_trans_deflev: 1
net.inet6.ipsec6.ah_net_deflev: 1
net.inet6.ipsec6.ecn: 0
net.inet6.ipsec6.debug: 0
net.inet6.ipsec6.esp_randpad: -1
net.inet6.icmp6.rediraccept: 1
net.inet6.icmp6.redirtimeout: 600
net.inet6.icmp6.nd6_prune: 1
net.inet6.icmp6.nd6_delay: 5
net.inet6.icmp6.nd6_umaxtries: 3
net.inet6.icmp6.nd6_mmaxtries: 3
net.inet6.icmp6.nd6_useloopback: 1
net.inet6.icmp6.nodeinfo: 3
net.inet6.icmp6.errppslimit: 500
net.inet6.icmp6.nd6_maxnudhint: 0
net.inet6.icmp6.nd6_debug: 0
net.inet6.icmp6.nd6_accept_6to4: 1
net.inet6.icmp6.nd6_onlink_ns_rfc4861: 0
net.inet6.icmp6.nd6_llreach_base: 30
net.inet6.mld.gsrdelay: 10
net.inet6.mld.v1enable: 1
net.inet6.mld.use_allow: 1
net.inet6.mld.debug: 0
net.idle.route.expire_timeout: 30
net.idle.route.drain_interval: 10
net.statistics: 1
net.alf.loglevel: 55
net.alf.perm: 0
net.alf.defaultaction: 1
net.alf.mqcount: 0
net.smb.fs.version: 107000
net.smb.fs.loglevel: 0
net.smb.fs.kern_ntlmssp: 0
net.smb.fs.kern_deprecatePreXPServers: 1
net.smb.fs.kern_deadtimer: 60
net.smb.fs.kern_hard_deadtimer: 600
net.smb.fs.kern_soft_deadtimer: 30
net.smb.fs.tcpsndbuf: 261120
net.smb.fs.tcprcvbuf: 261120
    DARWIN_SYSCTL

    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)

    @stdin_ifconfig = StringIO.new
    @stdin_arp = StringIO.new
    @stdin_sysctl = StringIO.new
    @stdin_netstat = StringIO.new

    @ifconfig_lines = darwin_ifconfig.split("\n")
    @arp_lines = darwin_arp.split("\n")
    @netstat_lines = darwin_netstat.split("\n")
    @sysctl_lines = darwin_sysctl.split("\n")

    @ohai.stub(:from).with("route -n get default").and_return(darwin_route)
    @ohai.stub(:popen4).with("netstat -i -d -l -b -n")

    Ohai::Log.should_receive(:warn).with(/unable to detect/).exactly(3).times
    @ohai._require_plugin("network")
  end

  describe "gathering IP layer address info" do
    before do
      @ohai.stub!(:popen4).with("arp -an").and_yield(nil, @stdin_arp, @arp_lines, nil)
      @ohai.stub!(:popen4).with("ifconfig -a").and_yield(nil, @stdin_ifconfig, @ifconfig_lines, nil)
      @ohai.stub(:popen4).with("netstat -i -d -l -b -n").and_yield(nil, @stdin_netstat, @netstat_lines, nil)
      @ohai.stub(:popen4).with("sysctl net").and_yield(nil, @stdin_sysctl, @sysctl_lines, nil)
      @ohai._require_plugin("darwin::network")
    end

    it "completes the run" do
      @ohai['network'].should_not be_nil
    end

    it "detects the interfaces" do
      @ohai['network']['interfaces'].keys.sort.should == ["en0", "en1", "fw0", "gif0", "lo0", "p2p0", "stf0", "utun0"]
    end

    it "detects the ipv4 addresses of the ethernet interface" do
      @ohai['network']['interfaces']['en1']['addresses'].keys.should include('10.20.10.144')
      @ohai['network']['interfaces']['en1']['addresses']['10.20.10.144']['netmask'].should == '255.255.255.0'
      @ohai['network']['interfaces']['en1']['addresses']['10.20.10.144']['broadcast'].should == '10.20.10.255'
      @ohai['network']['interfaces']['en1']['addresses']['10.20.10.144']['family'].should == 'inet'
    end

    it "detects the ipv6 addresses of the ethernet interface" do
      @ohai['network']['interfaces']['en1']['addresses'].keys.should include('fe80::ba8d:12ff:fe3a:32de')
      @ohai['network']['interfaces']['en1']['addresses']['fe80::ba8d:12ff:fe3a:32de']['scope'].should == 'Link'
      @ohai['network']['interfaces']['en1']['addresses']['fe80::ba8d:12ff:fe3a:32de']['prefixlen'].should == '64'
      @ohai['network']['interfaces']['en1']['addresses']['fe80::ba8d:12ff:fe3a:32de']['family'].should == 'inet6'

      @ohai['network']['interfaces']['en1']['addresses'].keys.should include('2001:44b8:4186:1100:ba8d:12ff:fe3a:32de')
      @ohai['network']['interfaces']['en1']['addresses']['2001:44b8:4186:1100:ba8d:12ff:fe3a:32de']['scope'].should == 'Global'
      @ohai['network']['interfaces']['en1']['addresses']['2001:44b8:4186:1100:ba8d:12ff:fe3a:32de']['prefixlen'].should == '64'
      @ohai['network']['interfaces']['en1']['addresses']['2001:44b8:4186:1100:ba8d:12ff:fe3a:32de']['family'].should == 'inet6'
    end

    it "detects the mac addresses of the ethernet interface" do
      @ohai['network']['interfaces']['en1']['addresses'].keys.should include('b8:8d:12:3a:32:de')
      @ohai['network']['interfaces']['en1']['addresses']['b8:8d:12:3a:32:de']['family'].should == 'lladdr'
    end

    it "detects the encapsulation type of the ethernet interface" do
      @ohai['network']['interfaces']['en1']['encapsulation'].should == 'Ethernet'
    end

    it "detects the flags of the ethernet interface" do
      @ohai['network']['interfaces']['en1']['flags'].sort.should == ["BROADCAST", "MULTICAST", "RUNNING", "SIMPLEX", "SMART", "UP"]
    end


    it "detects the mtu of the ethernet interface" do
      @ohai['network']['interfaces']['en1']['mtu'].should == "1500"
    end

    it "detects the ipv4 addresses of the loopback interface" do
      @ohai['network']['interfaces']['lo0']['addresses'].keys.should include('127.0.0.1')
      @ohai['network']['interfaces']['lo0']['addresses']['127.0.0.1']['netmask'].should == '255.0.0.0'
      @ohai['network']['interfaces']['lo0']['addresses']['127.0.0.1']['family'].should == 'inet'
    end

    it "detects the ipv6 addresses of the loopback interface" do
      @ohai['network']['interfaces']['lo0']['addresses'].keys.should include('::1')
      @ohai['network']['interfaces']['lo0']['addresses']['::1']['scope'].should == 'Node'
      @ohai['network']['interfaces']['lo0']['addresses']['::1']['prefixlen'].should == '128'
      @ohai['network']['interfaces']['lo0']['addresses']['::1']['family'].should == 'inet6'
    end

    it "detects the encapsulation type of the loopback interface" do
      @ohai['network']['interfaces']['lo0']['encapsulation'].should == 'Loopback'
    end

    it "detects the flags of the ethernet interface" do
      @ohai['network']['interfaces']['lo0']['flags'].sort.should == ["LOOPBACK", "MULTICAST", "RUNNING", "UP"]
    end

    it "detects the mtu of the loopback interface" do
      @ohai['network']['interfaces']['lo0']['mtu'].should == "16384"
    end

    it "detects the arp entries" do
      @ohai['network']['interfaces']['en1']['arp']['10.20.10.1'].should == '0:4:ed:de:41:bf'
    end

    it "detects the ethernet counters" do
      @ohai['counters']['network']['interfaces']['en1']['tx']['bytes'].should == "18228234970"
      @ohai['counters']['network']['interfaces']['en1']['tx']['packets'].should == "14314573"
      @ohai['counters']['network']['interfaces']['en1']['tx']['collisions'].should == "0"
      @ohai['counters']['network']['interfaces']['en1']['tx']['errors'].should == "0"
      @ohai['counters']['network']['interfaces']['en1']['tx']['carrier'].should == 0
      @ohai['counters']['network']['interfaces']['en1']['tx']['drop'].should == 0

      @ohai['counters']['network']['interfaces']['en1']['rx']['bytes'].should == "2530556736"
      @ohai['counters']['network']['interfaces']['en1']['rx']['packets'].should == "5921903"
      @ohai['counters']['network']['interfaces']['en1']['rx']['errors'].should == "0"
      @ohai['counters']['network']['interfaces']['en1']['rx']['overrun'].should == 0
      @ohai['counters']['network']['interfaces']['en1']['rx']['drop'].should == 0
    end

    it "detects the loopback counters" do
      @ohai['counters']['network']['interfaces']['lo0']['tx']['bytes'].should == "25774844"
      @ohai['counters']['network']['interfaces']['lo0']['tx']['packets'].should == "174982"
      @ohai['counters']['network']['interfaces']['lo0']['tx']['collisions'].should == "0"
      @ohai['counters']['network']['interfaces']['lo0']['tx']['errors'].should == "0"
      @ohai['counters']['network']['interfaces']['lo0']['tx']['carrier'].should == 0
      @ohai['counters']['network']['interfaces']['lo0']['tx']['drop'].should == 0

      @ohai['counters']['network']['interfaces']['lo0']['rx']['bytes'].should == "25774844"
      @ohai['counters']['network']['interfaces']['lo0']['rx']['packets'].should == "174982"
      @ohai['counters']['network']['interfaces']['lo0']['rx']['errors'].should == "0"
      @ohai['counters']['network']['interfaces']['lo0']['rx']['overrun'].should == 0
      @ohai['counters']['network']['interfaces']['lo0']['rx']['drop'].should == 0
    end

    it "finds the default interface by asking which iface has the default route" do
      @ohai['network'][:default_interface].should == 'en1'
    end

    it "finds the default interface by asking which iface has the default route" do
      @ohai['network'][:default_gateway].should == '10.20.10.1'
    end

    it "should detect network settings" do
      @ohai['network']['settings']['net.local.stream.sendspace'].should == '8192'
      @ohai["network"]["settings"]['net.local.stream.recvspace'].should == '8192'
      @ohai["network"]["settings"]['net.local.stream.tracemdns'].should == '0'
      @ohai["network"]["settings"]['net.local.dgram.maxdgram'].should == '2048'
      @ohai["network"]["settings"]['net.local.dgram.recvspace'].should == '4096'
      @ohai["network"]["settings"]['net.local.inflight'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.portrange.lowfirst'].should == '1023'
      @ohai["network"]["settings"]['net.inet.ip.portrange.lowlast'].should == '600'
      @ohai["network"]["settings"]['net.inet.ip.portrange.first'].should == '49152'
      @ohai["network"]["settings"]['net.inet.ip.portrange.last'].should == '65535'
      @ohai["network"]["settings"]['net.inet.ip.portrange.hifirst'].should == '49152'
      @ohai["network"]["settings"]['net.inet.ip.portrange.hilast'].should == '65535'
      @ohai["network"]["settings"]['net.inet.ip.forwarding'].should == '1'
      @ohai["network"]["settings"]['net.inet.ip.redirect'].should == '1'
      @ohai["network"]["settings"]['net.inet.ip.ttl'].should == '64'
      @ohai["network"]["settings"]['net.inet.ip.rtexpire'].should == '12'
      @ohai["network"]["settings"]['net.inet.ip.rtminexpire'].should == '10'
      @ohai["network"]["settings"]['net.inet.ip.rtmaxcache'].should == '128'
      @ohai["network"]["settings"]['net.inet.ip.sourceroute'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.intr_queue_maxlen'].should == '50'
      @ohai["network"]["settings"]['net.inet.ip.intr_queue_drops'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.accept_sourceroute'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.keepfaith'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.gifttl'].should == '30'
      @ohai["network"]["settings"]['net.inet.ip.subnets_are_local'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.mcast.maxgrpsrc'].should == '512'
      @ohai["network"]["settings"]['net.inet.ip.mcast.maxsocksrc'].should == '128'
      @ohai["network"]["settings"]['net.inet.ip.mcast.loop'].should == '1'
      @ohai["network"]["settings"]['net.inet.ip.check_route_selfref'].should == '1'
      @ohai["network"]["settings"]['net.inet.ip.use_route_genid'].should == '1'
      @ohai["network"]["settings"]['net.inet.ip.dummynet.hash_size'].should == '64'
      @ohai["network"]["settings"]['net.inet.ip.dummynet.curr_time'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.dummynet.ready_heap'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.dummynet.extract_heap'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.dummynet.searches'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.dummynet.search_steps'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.dummynet.expire'].should == '1'
      @ohai["network"]["settings"]['net.inet.ip.dummynet.max_chain_len'].should == '16'
      @ohai["network"]["settings"]['net.inet.ip.dummynet.red_lookup_depth'].should == '256'
      @ohai["network"]["settings"]['net.inet.ip.dummynet.red_avg_pkt_size'].should == '512'
      @ohai["network"]["settings"]['net.inet.ip.dummynet.red_max_pkt_size'].should == '1500'
      @ohai["network"]["settings"]['net.inet.ip.dummynet.debug'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.fw.enable'].should == '1'
      @ohai["network"]["settings"]['net.inet.ip.fw.autoinc_step'].should == '100'
      @ohai["network"]["settings"]['net.inet.ip.fw.one_pass'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.fw.debug'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.fw.verbose'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.fw.verbose_limit'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.fw.dyn_buckets'].should == '256'
      @ohai["network"]["settings"]['net.inet.ip.fw.curr_dyn_buckets'].should == '256'
      @ohai["network"]["settings"]['net.inet.ip.fw.dyn_count'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.fw.dyn_max'].should == '4096'
      @ohai["network"]["settings"]['net.inet.ip.fw.static_count'].should == '2'
      @ohai["network"]["settings"]['net.inet.ip.fw.dyn_ack_lifetime'].should == '300'
      @ohai["network"]["settings"]['net.inet.ip.fw.dyn_syn_lifetime'].should == '20'
      @ohai["network"]["settings"]['net.inet.ip.fw.dyn_fin_lifetime'].should == '1'
      @ohai["network"]["settings"]['net.inet.ip.fw.dyn_rst_lifetime'].should == '1'
      @ohai["network"]["settings"]['net.inet.ip.fw.dyn_udp_lifetime'].should == '10'
      @ohai["network"]["settings"]['net.inet.ip.fw.dyn_short_lifetime'].should == '5'
      @ohai["network"]["settings"]['net.inet.ip.fw.dyn_keepalive'].should == '1'
      @ohai["network"]["settings"]['net.inet.ip.maxfragpackets'].should == '1536'
      @ohai["network"]["settings"]['net.inet.ip.maxfragsperpacket'].should == '128'
      @ohai["network"]["settings"]['net.inet.ip.maxfrags'].should == '3072'
      @ohai["network"]["settings"]['net.inet.ip.scopedroute'].should == '1'
      @ohai["network"]["settings"]['net.inet.ip.check_interface'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.linklocal.in.allowbadttl'].should == '1'
      @ohai["network"]["settings"]['net.inet.ip.random_id'].should == '1'
      @ohai["network"]["settings"]['net.inet.ip.maxchainsent'].should == '0'
      @ohai["network"]["settings"]['net.inet.ip.select_srcif_debug'].should == '0'
      @ohai["network"]["settings"]['net.inet.icmp.maskrepl'].should == '0'
      @ohai["network"]["settings"]['net.inet.icmp.icmplim'].should == '250'
      @ohai["network"]["settings"]['net.inet.icmp.timestamp'].should == '0'
      @ohai["network"]["settings"]['net.inet.icmp.drop_redirect'].should == '0'
      @ohai["network"]["settings"]['net.inet.icmp.log_redirect'].should == '0'
      @ohai["network"]["settings"]['net.inet.icmp.bmcastecho'].should == '1'
      @ohai["network"]["settings"]['net.inet.igmp.recvifkludge'].should == '1'
      @ohai["network"]["settings"]['net.inet.igmp.sendra'].should == '1'
      @ohai["network"]["settings"]['net.inet.igmp.sendlocal'].should == '1'
      @ohai["network"]["settings"]['net.inet.igmp.v1enable'].should == '1'
      @ohai["network"]["settings"]['net.inet.igmp.v2enable'].should == '1'
      @ohai["network"]["settings"]['net.inet.igmp.legacysupp'].should == '0'
      @ohai["network"]["settings"]['net.inet.igmp.default_version'].should == '3'
      @ohai["network"]["settings"]['net.inet.igmp.gsrdelay'].should == '10'
      @ohai["network"]["settings"]['net.inet.igmp.debug'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.rfc1323'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.rfc1644'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.mssdflt'].should == '512'
      @ohai["network"]["settings"]['net.inet.tcp.keepidle'].should == '7200000'
      @ohai["network"]["settings"]['net.inet.tcp.keepintvl'].should == '75000'
      @ohai["network"]["settings"]['net.inet.tcp.sendspace'].should == '65536'
      @ohai["network"]["settings"]['net.inet.tcp.recvspace'].should == '65536'
      @ohai["network"]["settings"]['net.inet.tcp.keepinit'].should == '75000'
      @ohai["network"]["settings"]['net.inet.tcp.v6mssdflt'].should == '1024'
      @ohai["network"]["settings"]['net.inet.tcp.log_in_vain'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.blackhole'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.delayed_ack'].should == '3'
      @ohai["network"]["settings"]['net.inet.tcp.tcp_lq_overflow'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.recvbg'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.drop_synfin'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.reass.maxsegments'].should == '3072'
      @ohai["network"]["settings"]['net.inet.tcp.reass.cursegments'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.reass.overflows'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.slowlink_wsize'].should == '8192'
      @ohai["network"]["settings"]['net.inet.tcp.maxseg_unacked'].should == '8'
      @ohai["network"]["settings"]['net.inet.tcp.rfc3465'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.rfc3465_lim2'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.rtt_samples_per_slot'].should == '20'
      @ohai["network"]["settings"]['net.inet.tcp.recv_allowed_iaj'].should == '5'
      @ohai["network"]["settings"]['net.inet.tcp.acc_iaj_high_thresh'].should == '100'
      @ohai["network"]["settings"]['net.inet.tcp.rexmt_thresh'].should == '2'
      @ohai["network"]["settings"]['net.inet.tcp.path_mtu_discovery'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.slowstart_flightsize'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.local_slowstart_flightsize'].should == '8'
      @ohai["network"]["settings"]['net.inet.tcp.tso'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.ecn_initiate_out'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.ecn_negotiate_in'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.packetchain'].should == '50'
      @ohai["network"]["settings"]['net.inet.tcp.socket_unlocked_on_output'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.rfc3390'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.min_iaj_win'].should == '4'
      @ohai["network"]["settings"]['net.inet.tcp.acc_iaj_react_limit'].should == '200'
      @ohai["network"]["settings"]['net.inet.tcp.sack'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.sack_maxholes'].should == '128'
      @ohai["network"]["settings"]['net.inet.tcp.sack_globalmaxholes'].should == '65536'
      @ohai["network"]["settings"]['net.inet.tcp.sack_globalholes'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.minmss'].should == '216'
      @ohai["network"]["settings"]['net.inet.tcp.minmssoverload'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.do_tcpdrain'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.pcbcount'].should == '86'
      @ohai["network"]["settings"]['net.inet.tcp.icmp_may_rst'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.strict_rfc1948'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.isn_reseed_interval'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.background_io_enabled'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.rtt_min'].should == '100'
      @ohai["network"]["settings"]['net.inet.tcp.rexmt_slop'].should == '200'
      @ohai["network"]["settings"]['net.inet.tcp.randomize_ports'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.newreno_sockets'].should == '81'
      @ohai["network"]["settings"]['net.inet.tcp.background_sockets'].should == '-1'
      @ohai["network"]["settings"]['net.inet.tcp.tcbhashsize'].should == '4096'
      @ohai["network"]["settings"]['net.inet.tcp.background_io_trigger'].should == '5'
      @ohai["network"]["settings"]['net.inet.tcp.msl'].should == '15000'
      @ohai["network"]["settings"]['net.inet.tcp.max_persist_timeout'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.always_keepalive'].should == '0'
      @ohai["network"]["settings"]['net.inet.tcp.timer_fastmode_idlemax'].should == '20'
      @ohai["network"]["settings"]['net.inet.tcp.broken_peer_syn_rxmit_thres'].should == '7'
      @ohai["network"]["settings"]['net.inet.tcp.tcp_timer_advanced'].should == '5'
      @ohai["network"]["settings"]['net.inet.tcp.tcp_resched_timerlist'].should == '12209'
      @ohai["network"]["settings"]['net.inet.tcp.pmtud_blackhole_detection'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.pmtud_blackhole_mss'].should == '1200'
      @ohai["network"]["settings"]['net.inet.tcp.timer_fastquantum'].should == '100'
      @ohai["network"]["settings"]['net.inet.tcp.timer_slowquantum'].should == '500'
      @ohai["network"]["settings"]['net.inet.tcp.win_scale_factor'].should == '3'
      @ohai["network"]["settings"]['net.inet.tcp.sockthreshold'].should == '64'
      @ohai["network"]["settings"]['net.inet.tcp.bg_target_qdelay'].should == '100'
      @ohai["network"]["settings"]['net.inet.tcp.bg_allowed_increase'].should == '2'
      @ohai["network"]["settings"]['net.inet.tcp.bg_tether_shift'].should == '1'
      @ohai["network"]["settings"]['net.inet.tcp.bg_ss_fltsz'].should == '2'
      @ohai["network"]["settings"]['net.inet.udp.checksum'].should == '1'
      @ohai["network"]["settings"]['net.inet.udp.maxdgram'].should == '9216'
      @ohai["network"]["settings"]['net.inet.udp.recvspace'].should == '42080'
      @ohai["network"]["settings"]['net.inet.udp.log_in_vain'].should == '0'
      @ohai["network"]["settings"]['net.inet.udp.blackhole'].should == '0'
      @ohai["network"]["settings"]['net.inet.udp.pcbcount'].should == '72'
      @ohai["network"]["settings"]['net.inet.udp.randomize_ports'].should == '1'
      @ohai["network"]["settings"]['net.inet.ipsec.def_policy'].should == '1'
      @ohai["network"]["settings"]['net.inet.ipsec.esp_trans_deflev'].should == '1'
      @ohai["network"]["settings"]['net.inet.ipsec.esp_net_deflev'].should == '1'
      @ohai["network"]["settings"]['net.inet.ipsec.ah_trans_deflev'].should == '1'
      @ohai["network"]["settings"]['net.inet.ipsec.ah_net_deflev'].should == '1'
      @ohai["network"]["settings"]['net.inet.ipsec.ah_cleartos'].should == '1'
      @ohai["network"]["settings"]['net.inet.ipsec.ah_offsetmask'].should == '0'
      @ohai["network"]["settings"]['net.inet.ipsec.dfbit'].should == '0'
      @ohai["network"]["settings"]['net.inet.ipsec.ecn'].should == '0'
      @ohai["network"]["settings"]['net.inet.ipsec.debug'].should == '0'
      @ohai["network"]["settings"]['net.inet.ipsec.esp_randpad'].should == '-1'
      @ohai["network"]["settings"]['net.inet.ipsec.bypass'].should == '0'
      @ohai["network"]["settings"]['net.inet.ipsec.esp_port'].should == '4500'
      @ohai["network"]["settings"]['net.inet.raw.maxdgram'].should == '8192'
      @ohai["network"]["settings"]['net.inet.raw.recvspace'].should == '8192'
      @ohai["network"]["settings"]['net.link.generic.system.ifcount'].should == '10'
      @ohai["network"]["settings"]['net.link.generic.system.dlil_verbose'].should == '0'
      @ohai["network"]["settings"]['net.link.generic.system.multi_threaded_input'].should == '1'
      @ohai["network"]["settings"]['net.link.generic.system.dlil_input_sanity_check'].should == '0'
      @ohai["network"]["settings"]['net.link.ether.inet.prune_intvl'].should == '300'
      @ohai["network"]["settings"]['net.link.ether.inet.max_age'].should == '1200'
      @ohai["network"]["settings"]['net.link.ether.inet.host_down_time'].should == '20'
      @ohai["network"]["settings"]['net.link.ether.inet.apple_hwcksum_tx'].should == '1'
      @ohai["network"]["settings"]['net.link.ether.inet.apple_hwcksum_rx'].should == '1'
      @ohai["network"]["settings"]['net.link.ether.inet.arp_llreach_base'].should == '30'
      @ohai["network"]["settings"]['net.link.ether.inet.maxtries'].should == '5'
      @ohai["network"]["settings"]['net.link.ether.inet.useloopback'].should == '1'
      @ohai["network"]["settings"]['net.link.ether.inet.proxyall'].should == '0'
      @ohai["network"]["settings"]['net.link.ether.inet.sendllconflict'].should == '0'
      @ohai["network"]["settings"]['net.link.ether.inet.log_arp_warnings'].should == '0'
      @ohai["network"]["settings"]['net.link.ether.inet.keep_announcements'].should == '1'
      @ohai["network"]["settings"]['net.link.ether.inet.send_conflicting_probes'].should == '1'
      @ohai["network"]["settings"]['net.link.bridge.log_stp'].should == '0'
      @ohai["network"]["settings"]['net.link.bridge.debug'].should == '0'
      @ohai["network"]["settings"]['net.key.debug'].should == '0'
      @ohai["network"]["settings"]['net.key.spi_trycnt'].should == '1000'
      @ohai["network"]["settings"]['net.key.spi_minval'].should == '256'
      @ohai["network"]["settings"]['net.key.spi_maxval'].should == '268435455'
      @ohai["network"]["settings"]['net.key.int_random'].should == '60'
      @ohai["network"]["settings"]['net.key.larval_lifetime'].should == '30'
      @ohai["network"]["settings"]['net.key.blockacq_count'].should == '10'
      @ohai["network"]["settings"]['net.key.blockacq_lifetime'].should == '20'
      @ohai["network"]["settings"]['net.key.esp_keymin'].should == '256'
      @ohai["network"]["settings"]['net.key.esp_auth'].should == '0'
      @ohai["network"]["settings"]['net.key.ah_keymin'].should == '128'
      @ohai["network"]["settings"]['net.key.prefered_oldsa'].should == '0'
      @ohai["network"]["settings"]['net.key.natt_keepalive_interval'].should == '20'
      @ohai["network"]["settings"]['net.inet6.ip6.forwarding'].should == '0'
      @ohai["network"]["settings"]['net.inet6.ip6.redirect'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ip6.hlim'].should == '64'
      @ohai["network"]["settings"]['net.inet6.ip6.maxfragpackets'].should == '1536'
      @ohai["network"]["settings"]['net.inet6.ip6.accept_rtadv'].should == '0'
      @ohai["network"]["settings"]['net.inet6.ip6.keepfaith'].should == '0'
      @ohai["network"]["settings"]['net.inet6.ip6.log_interval'].should == '5'
      @ohai["network"]["settings"]['net.inet6.ip6.hdrnestlimit'].should == '15'
      @ohai["network"]["settings"]['net.inet6.ip6.dad_count'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ip6.auto_flowlabel'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ip6.defmcasthlim'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ip6.gifhlim'].should == '0'
      @ohai["network"]["settings"]['net.inet6.ip6.kame_version'].should == '2009/apple-darwin'
      @ohai["network"]["settings"]['net.inet6.ip6.use_deprecated'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ip6.rr_prune'].should == '5'
      @ohai["network"]["settings"]['net.inet6.ip6.v6only'].should == '0'
      @ohai["network"]["settings"]['net.inet6.ip6.rtexpire'].should == '3600'
      @ohai["network"]["settings"]['net.inet6.ip6.rtminexpire'].should == '10'
      @ohai["network"]["settings"]['net.inet6.ip6.rtmaxcache'].should == '128'
      @ohai["network"]["settings"]['net.inet6.ip6.use_tempaddr'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ip6.temppltime'].should == '86400'
      @ohai["network"]["settings"]['net.inet6.ip6.tempvltime'].should == '604800'
      @ohai["network"]["settings"]['net.inet6.ip6.auto_linklocal'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ip6.prefer_tempaddr'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ip6.use_defaultzone'].should == '0'
      @ohai["network"]["settings"]['net.inet6.ip6.maxfrags'].should == '12288'
      @ohai["network"]["settings"]['net.inet6.ip6.mcast_pmtu'].should == '0'
      @ohai["network"]["settings"]['net.inet6.ip6.neighborgcthresh'].should == '1024'
      @ohai["network"]["settings"]['net.inet6.ip6.maxifprefixes'].should == '16'
      @ohai["network"]["settings"]['net.inet6.ip6.maxifdefrouters'].should == '16'
      @ohai["network"]["settings"]['net.inet6.ip6.maxdynroutes'].should == '1024'
      @ohai["network"]["settings"]['net.inet6.ip6.fw.enable'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ip6.fw.debug'].should == '0'
      @ohai["network"]["settings"]['net.inet6.ip6.fw.verbose'].should == '0'
      @ohai["network"]["settings"]['net.inet6.ip6.fw.verbose_limit'].should == '0'
      @ohai["network"]["settings"]['net.inet6.ip6.scopedroute'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ip6.select_srcif_debug'].should == '0'
      @ohai["network"]["settings"]['net.inet6.ip6.mcast.maxgrpsrc'].should == '512'
      @ohai["network"]["settings"]['net.inet6.ip6.mcast.maxsocksrc'].should == '128'
      @ohai["network"]["settings"]['net.inet6.ip6.mcast.loop'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ip6.only_allow_rfc4193_prefixes'].should == '0'
      @ohai["network"]["settings"]['net.inet6.ipsec6.def_policy'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ipsec6.esp_trans_deflev'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ipsec6.esp_net_deflev'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ipsec6.ah_trans_deflev'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ipsec6.ah_net_deflev'].should == '1'
      @ohai["network"]["settings"]['net.inet6.ipsec6.ecn'].should == '0'
      @ohai["network"]["settings"]['net.inet6.ipsec6.debug'].should == '0'
      @ohai["network"]["settings"]['net.inet6.ipsec6.esp_randpad'].should == '-1'
      @ohai["network"]["settings"]['net.inet6.icmp6.rediraccept'].should == '1'
      @ohai["network"]["settings"]['net.inet6.icmp6.redirtimeout'].should == '600'
      @ohai["network"]["settings"]['net.inet6.icmp6.nd6_prune'].should == '1'
      @ohai["network"]["settings"]['net.inet6.icmp6.nd6_delay'].should == '5'
      @ohai["network"]["settings"]['net.inet6.icmp6.nd6_umaxtries'].should == '3'
      @ohai["network"]["settings"]['net.inet6.icmp6.nd6_mmaxtries'].should == '3'
      @ohai["network"]["settings"]['net.inet6.icmp6.nd6_useloopback'].should == '1'
      @ohai["network"]["settings"]['net.inet6.icmp6.nodeinfo'].should == '3'
      @ohai["network"]["settings"]['net.inet6.icmp6.errppslimit'].should == '500'
      @ohai["network"]["settings"]['net.inet6.icmp6.nd6_maxnudhint'].should == '0'
      @ohai["network"]["settings"]['net.inet6.icmp6.nd6_debug'].should == '0'
      @ohai["network"]["settings"]['net.inet6.icmp6.nd6_accept_6to4'].should == '1'
      @ohai["network"]["settings"]['net.inet6.icmp6.nd6_onlink_ns_rfc4861'].should == '0'
      @ohai["network"]["settings"]['net.inet6.icmp6.nd6_llreach_base'].should == '30'
      @ohai["network"]["settings"]['net.inet6.mld.gsrdelay'].should == '10'
      @ohai["network"]["settings"]['net.inet6.mld.v1enable'].should == '1'
      @ohai["network"]["settings"]['net.inet6.mld.use_allow'].should == '1'
      @ohai["network"]["settings"]['net.inet6.mld.debug'].should == '0'
      @ohai["network"]["settings"]['net.idle.route.expire_timeout'].should == '30'
      @ohai["network"]["settings"]['net.idle.route.drain_interval'].should == '10'
      @ohai["network"]["settings"]['net.statistics'].should == '1'
      @ohai["network"]["settings"]['net.alf.loglevel'].should == '55'
      @ohai["network"]["settings"]['net.alf.perm'].should == '0'
      @ohai["network"]["settings"]['net.alf.defaultaction'].should == '1'
      @ohai["network"]["settings"]['net.alf.mqcount'].should == '0'
      @ohai["network"]["settings"]['net.smb.fs.version'].should == '107000'
      @ohai["network"]["settings"]['net.smb.fs.loglevel'].should == '0'
      @ohai["network"]["settings"]['net.smb.fs.kern_ntlmssp'].should == '0'
      @ohai["network"]["settings"]['net.smb.fs.kern_deprecatePreXPServers'].should == '1'
      @ohai["network"]["settings"]['net.smb.fs.kern_deadtimer'].should == '60'
      @ohai["network"]["settings"]['net.smb.fs.kern_hard_deadtimer'].should == '600'
      @ohai["network"]["settings"]['net.smb.fs.kern_soft_deadtimer'].should == '30'
      @ohai["network"]["settings"]['net.smb.fs.tcpsndbuf'].should == '261120'
      @ohai["network"]["settings"]['net.smb.fs.tcprcvbuf'].should == '261120'
    end
  end
end
