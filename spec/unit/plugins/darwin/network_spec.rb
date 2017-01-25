#
#  Author:: Alan Harper <alan@aussiegeek.net>
#  Copyright:: Copyright (c) 2012-2016 Chef Software, Inc.
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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "Darwin Network Plugin" do
  before(:each) do
    @darwin_ifconfig = <<-DARWIN_IFCONFIG
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

    @darwin_arp = <<-DARWIN_ARP
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

    @darwin_route = <<-DARWIN_ROUTE
   route to: default
destination: default
       mask: default
    gateway: 10.20.10.1
  interface: en1
      flags: <UP,GATEWAY,DONE,STATIC,PRCLONING>
 recvpipe  sendpipe  ssthresh  rtt,msec    rttvar  hopcount      mtu     expire
       0         0         0         0         0         0      1500         0
    DARWIN_ROUTE

    @darwin_netstat = <<-DARWIN_NETSTAT
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

    @darwin_sysctl = <<-DARWIN_SYSCTL
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

    @plugin = get_plugin("darwin/network")
    allow(@plugin).to receive(:collect_os).and_return(:darwin)

    # @stdin_ifconfig = StringIO.new
    # @stdin_arp = StringIO.new
    # @stdin_sysctl = StringIO.new
    # @stdin_netstat = StringIO.new

    # @ifconfig_lines = darwin_ifconfig.split("\n")
    # @arp_lines = darwin_arp.split("\n")
    # @netstat_lines = darwin_netstat.split("\n")
    # @sysctl_lines = darwin_sysctl.split("\n")

    allow(@plugin).to receive(:shell_out).with("route -n get default").and_return(mock_shell_out(0, @darwin_route, ""))
    allow(@plugin).to receive(:shell_out).with("netstat -i -d -l -b -n")
  end

  describe "gathering IP layer address info" do
    before(:each) do
      allow(@plugin).to receive(:shell_out).with("arp -an").and_return(mock_shell_out(0, @darwin_arp, ""))
      allow(@plugin).to receive(:shell_out).with("ifconfig -a").and_return(mock_shell_out(0, @darwin_ifconfig, ""))
      allow(@plugin).to receive(:shell_out).with("netstat -i -d -l -b -n").and_return(mock_shell_out(0, @darwin_netstat, ""))
      allow(@plugin).to receive(:shell_out).with("sysctl net").and_return(mock_shell_out(0, @darwin_sysctl, ""))
      @plugin.run
    end

    it "completes the run" do
      expect(@plugin["network"]).not_to be_nil
    end

    it "detects the interfaces" do
      expect(@plugin["network"]["interfaces"].keys.sort).to eq(%w{en0 en1 fw0 gif0 lo0 p2p0 stf0 utun0})
    end

    it "detects the ipv4 addresses of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["en1"]["addresses"].keys).to include("10.20.10.144")
      expect(@plugin["network"]["interfaces"]["en1"]["addresses"]["10.20.10.144"]["netmask"]).to eq("255.255.255.0")
      expect(@plugin["network"]["interfaces"]["en1"]["addresses"]["10.20.10.144"]["broadcast"]).to eq("10.20.10.255")
      expect(@plugin["network"]["interfaces"]["en1"]["addresses"]["10.20.10.144"]["family"]).to eq("inet")
    end

    it "detects the ipv6 addresses of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["en1"]["addresses"].keys).to include("fe80::ba8d:12ff:fe3a:32de")
      expect(@plugin["network"]["interfaces"]["en1"]["addresses"]["fe80::ba8d:12ff:fe3a:32de"]["scope"]).to eq("Link")
      expect(@plugin["network"]["interfaces"]["en1"]["addresses"]["fe80::ba8d:12ff:fe3a:32de"]["prefixlen"]).to eq("64")
      expect(@plugin["network"]["interfaces"]["en1"]["addresses"]["fe80::ba8d:12ff:fe3a:32de"]["family"]).to eq("inet6")

      expect(@plugin["network"]["interfaces"]["en1"]["addresses"].keys).to include("2001:44b8:4186:1100:ba8d:12ff:fe3a:32de")
      expect(@plugin["network"]["interfaces"]["en1"]["addresses"]["2001:44b8:4186:1100:ba8d:12ff:fe3a:32de"]["scope"]).to eq("Global")
      expect(@plugin["network"]["interfaces"]["en1"]["addresses"]["2001:44b8:4186:1100:ba8d:12ff:fe3a:32de"]["prefixlen"]).to eq("64")
      expect(@plugin["network"]["interfaces"]["en1"]["addresses"]["2001:44b8:4186:1100:ba8d:12ff:fe3a:32de"]["family"]).to eq("inet6")
    end

    it "detects the mac addresses of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["en1"]["addresses"].keys).to include("b8:8d:12:3a:32:de")
      expect(@plugin["network"]["interfaces"]["en1"]["addresses"]["b8:8d:12:3a:32:de"]["family"]).to eq("lladdr")
    end

    it "detects the encapsulation type of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["en1"]["encapsulation"]).to eq("Ethernet")
    end

    it "detects the flags of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["en1"]["flags"].sort).to eq(%w{BROADCAST MULTICAST RUNNING SIMPLEX SMART UP})
    end

    it "detects the mtu of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["en1"]["mtu"]).to eq("1500")
    end

    it "detects the ipv4 addresses of the loopback interface" do
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"].keys).to include("127.0.0.1")
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"]["127.0.0.1"]["netmask"]).to eq("255.0.0.0")
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"]["127.0.0.1"]["family"]).to eq("inet")
    end

    it "detects the ipv6 addresses of the loopback interface" do
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"].keys).to include("::1")
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"]["::1"]["scope"]).to eq("Node")
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"]["::1"]["prefixlen"]).to eq("128")
      expect(@plugin["network"]["interfaces"]["lo0"]["addresses"]["::1"]["family"]).to eq("inet6")
    end

    it "detects the encapsulation type of the loopback interface" do
      expect(@plugin["network"]["interfaces"]["lo0"]["encapsulation"]).to eq("Loopback")
    end

    it "detects the flags of the ethernet interface" do
      expect(@plugin["network"]["interfaces"]["lo0"]["flags"].sort).to eq(%w{LOOPBACK MULTICAST RUNNING UP})
    end

    it "detects the mtu of the loopback interface" do
      expect(@plugin["network"]["interfaces"]["lo0"]["mtu"]).to eq("16384")
    end

    it "detects the arp entries" do
      expect(@plugin["network"]["interfaces"]["en1"]["arp"]["10.20.10.1"]).to eq("0:4:ed:de:41:bf")
    end

    it "detects the ethernet counters" do
      expect(@plugin["counters"]["network"]["interfaces"]["en1"]["tx"]["bytes"]).to eq("18228234970")
      expect(@plugin["counters"]["network"]["interfaces"]["en1"]["tx"]["packets"]).to eq("14314573")
      expect(@plugin["counters"]["network"]["interfaces"]["en1"]["tx"]["collisions"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["en1"]["tx"]["errors"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["en1"]["tx"]["carrier"]).to eq(0)
      expect(@plugin["counters"]["network"]["interfaces"]["en1"]["tx"]["drop"]).to eq(0)

      expect(@plugin["counters"]["network"]["interfaces"]["en1"]["rx"]["bytes"]).to eq("2530556736")
      expect(@plugin["counters"]["network"]["interfaces"]["en1"]["rx"]["packets"]).to eq("5921903")
      expect(@plugin["counters"]["network"]["interfaces"]["en1"]["rx"]["errors"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["en1"]["rx"]["overrun"]).to eq(0)
      expect(@plugin["counters"]["network"]["interfaces"]["en1"]["rx"]["drop"]).to eq(0)
    end

    it "detects the loopback counters" do
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["bytes"]).to eq("25774844")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["packets"]).to eq("174982")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["collisions"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["errors"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["carrier"]).to eq(0)
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["tx"]["drop"]).to eq(0)

      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["rx"]["bytes"]).to eq("25774844")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["rx"]["packets"]).to eq("174982")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["rx"]["errors"]).to eq("0")
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["rx"]["overrun"]).to eq(0)
      expect(@plugin["counters"]["network"]["interfaces"]["lo0"]["rx"]["drop"]).to eq(0)
    end

    it "finds the default interface by asking which iface has the default route" do
      expect(@plugin["network"][:default_interface]).to eq("en1")
    end

    it "finds the default interface by asking which iface has the default route" do
      expect(@plugin["network"][:default_gateway]).to eq("10.20.10.1")
    end

    it "should detect network settings" do
      expect(@plugin["network"]["settings"]["net.local.stream.sendspace"]).to eq("8192")
      expect(@plugin["network"]["settings"]["net.local.stream.recvspace"]).to eq("8192")
      expect(@plugin["network"]["settings"]["net.local.stream.tracemdns"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.local.dgram.maxdgram"]).to eq("2048")
      expect(@plugin["network"]["settings"]["net.local.dgram.recvspace"]).to eq("4096")
      expect(@plugin["network"]["settings"]["net.local.inflight"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.portrange.lowfirst"]).to eq("1023")
      expect(@plugin["network"]["settings"]["net.inet.ip.portrange.lowlast"]).to eq("600")
      expect(@plugin["network"]["settings"]["net.inet.ip.portrange.first"]).to eq("49152")
      expect(@plugin["network"]["settings"]["net.inet.ip.portrange.last"]).to eq("65535")
      expect(@plugin["network"]["settings"]["net.inet.ip.portrange.hifirst"]).to eq("49152")
      expect(@plugin["network"]["settings"]["net.inet.ip.portrange.hilast"]).to eq("65535")
      expect(@plugin["network"]["settings"]["net.inet.ip.forwarding"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ip.redirect"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ip.ttl"]).to eq("64")
      expect(@plugin["network"]["settings"]["net.inet.ip.rtexpire"]).to eq("12")
      expect(@plugin["network"]["settings"]["net.inet.ip.rtminexpire"]).to eq("10")
      expect(@plugin["network"]["settings"]["net.inet.ip.rtmaxcache"]).to eq("128")
      expect(@plugin["network"]["settings"]["net.inet.ip.sourceroute"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.intr_queue_maxlen"]).to eq("50")
      expect(@plugin["network"]["settings"]["net.inet.ip.intr_queue_drops"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.accept_sourceroute"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.keepfaith"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.gifttl"]).to eq("30")
      expect(@plugin["network"]["settings"]["net.inet.ip.subnets_are_local"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.mcast.maxgrpsrc"]).to eq("512")
      expect(@plugin["network"]["settings"]["net.inet.ip.mcast.maxsocksrc"]).to eq("128")
      expect(@plugin["network"]["settings"]["net.inet.ip.mcast.loop"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ip.check_route_selfref"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ip.use_route_genid"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ip.dummynet.hash_size"]).to eq("64")
      expect(@plugin["network"]["settings"]["net.inet.ip.dummynet.curr_time"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.dummynet.ready_heap"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.dummynet.extract_heap"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.dummynet.searches"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.dummynet.search_steps"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.dummynet.expire"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ip.dummynet.max_chain_len"]).to eq("16")
      expect(@plugin["network"]["settings"]["net.inet.ip.dummynet.red_lookup_depth"]).to eq("256")
      expect(@plugin["network"]["settings"]["net.inet.ip.dummynet.red_avg_pkt_size"]).to eq("512")
      expect(@plugin["network"]["settings"]["net.inet.ip.dummynet.red_max_pkt_size"]).to eq("1500")
      expect(@plugin["network"]["settings"]["net.inet.ip.dummynet.debug"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.enable"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.autoinc_step"]).to eq("100")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.one_pass"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.debug"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.verbose"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.verbose_limit"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.dyn_buckets"]).to eq("256")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.curr_dyn_buckets"]).to eq("256")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.dyn_count"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.dyn_max"]).to eq("4096")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.static_count"]).to eq("2")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.dyn_ack_lifetime"]).to eq("300")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.dyn_syn_lifetime"]).to eq("20")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.dyn_fin_lifetime"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.dyn_rst_lifetime"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.dyn_udp_lifetime"]).to eq("10")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.dyn_short_lifetime"]).to eq("5")
      expect(@plugin["network"]["settings"]["net.inet.ip.fw.dyn_keepalive"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ip.maxfragpackets"]).to eq("1536")
      expect(@plugin["network"]["settings"]["net.inet.ip.maxfragsperpacket"]).to eq("128")
      expect(@plugin["network"]["settings"]["net.inet.ip.maxfrags"]).to eq("3072")
      expect(@plugin["network"]["settings"]["net.inet.ip.scopedroute"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ip.check_interface"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.linklocal.in.allowbadttl"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ip.random_id"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ip.maxchainsent"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ip.select_srcif_debug"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.icmp.maskrepl"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.icmp.icmplim"]).to eq("250")
      expect(@plugin["network"]["settings"]["net.inet.icmp.timestamp"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.icmp.drop_redirect"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.icmp.log_redirect"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.icmp.bmcastecho"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.igmp.recvifkludge"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.igmp.sendra"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.igmp.sendlocal"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.igmp.v1enable"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.igmp.v2enable"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.igmp.legacysupp"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.igmp.default_version"]).to eq("3")
      expect(@plugin["network"]["settings"]["net.inet.igmp.gsrdelay"]).to eq("10")
      expect(@plugin["network"]["settings"]["net.inet.igmp.debug"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.rfc1323"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.rfc1644"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.mssdflt"]).to eq("512")
      expect(@plugin["network"]["settings"]["net.inet.tcp.keepidle"]).to eq("7200000")
      expect(@plugin["network"]["settings"]["net.inet.tcp.keepintvl"]).to eq("75000")
      expect(@plugin["network"]["settings"]["net.inet.tcp.sendspace"]).to eq("65536")
      expect(@plugin["network"]["settings"]["net.inet.tcp.recvspace"]).to eq("65536")
      expect(@plugin["network"]["settings"]["net.inet.tcp.keepinit"]).to eq("75000")
      expect(@plugin["network"]["settings"]["net.inet.tcp.v6mssdflt"]).to eq("1024")
      expect(@plugin["network"]["settings"]["net.inet.tcp.log_in_vain"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.blackhole"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.delayed_ack"]).to eq("3")
      expect(@plugin["network"]["settings"]["net.inet.tcp.tcp_lq_overflow"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.recvbg"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.drop_synfin"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.reass.maxsegments"]).to eq("3072")
      expect(@plugin["network"]["settings"]["net.inet.tcp.reass.cursegments"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.reass.overflows"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.slowlink_wsize"]).to eq("8192")
      expect(@plugin["network"]["settings"]["net.inet.tcp.maxseg_unacked"]).to eq("8")
      expect(@plugin["network"]["settings"]["net.inet.tcp.rfc3465"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.rfc3465_lim2"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.rtt_samples_per_slot"]).to eq("20")
      expect(@plugin["network"]["settings"]["net.inet.tcp.recv_allowed_iaj"]).to eq("5")
      expect(@plugin["network"]["settings"]["net.inet.tcp.acc_iaj_high_thresh"]).to eq("100")
      expect(@plugin["network"]["settings"]["net.inet.tcp.rexmt_thresh"]).to eq("2")
      expect(@plugin["network"]["settings"]["net.inet.tcp.path_mtu_discovery"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.slowstart_flightsize"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.local_slowstart_flightsize"]).to eq("8")
      expect(@plugin["network"]["settings"]["net.inet.tcp.tso"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.ecn_initiate_out"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.ecn_negotiate_in"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.packetchain"]).to eq("50")
      expect(@plugin["network"]["settings"]["net.inet.tcp.socket_unlocked_on_output"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.rfc3390"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.min_iaj_win"]).to eq("4")
      expect(@plugin["network"]["settings"]["net.inet.tcp.acc_iaj_react_limit"]).to eq("200")
      expect(@plugin["network"]["settings"]["net.inet.tcp.sack"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.sack_maxholes"]).to eq("128")
      expect(@plugin["network"]["settings"]["net.inet.tcp.sack_globalmaxholes"]).to eq("65536")
      expect(@plugin["network"]["settings"]["net.inet.tcp.sack_globalholes"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.minmss"]).to eq("216")
      expect(@plugin["network"]["settings"]["net.inet.tcp.minmssoverload"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.do_tcpdrain"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.pcbcount"]).to eq("86")
      expect(@plugin["network"]["settings"]["net.inet.tcp.icmp_may_rst"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.strict_rfc1948"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.isn_reseed_interval"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.background_io_enabled"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.rtt_min"]).to eq("100")
      expect(@plugin["network"]["settings"]["net.inet.tcp.rexmt_slop"]).to eq("200")
      expect(@plugin["network"]["settings"]["net.inet.tcp.randomize_ports"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.newreno_sockets"]).to eq("81")
      expect(@plugin["network"]["settings"]["net.inet.tcp.background_sockets"]).to eq("-1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.tcbhashsize"]).to eq("4096")
      expect(@plugin["network"]["settings"]["net.inet.tcp.background_io_trigger"]).to eq("5")
      expect(@plugin["network"]["settings"]["net.inet.tcp.msl"]).to eq("15000")
      expect(@plugin["network"]["settings"]["net.inet.tcp.max_persist_timeout"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.always_keepalive"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.tcp.timer_fastmode_idlemax"]).to eq("20")
      expect(@plugin["network"]["settings"]["net.inet.tcp.broken_peer_syn_rxmit_thres"]).to eq("7")
      expect(@plugin["network"]["settings"]["net.inet.tcp.tcp_timer_advanced"]).to eq("5")
      expect(@plugin["network"]["settings"]["net.inet.tcp.tcp_resched_timerlist"]).to eq("12209")
      expect(@plugin["network"]["settings"]["net.inet.tcp.pmtud_blackhole_detection"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.pmtud_blackhole_mss"]).to eq("1200")
      expect(@plugin["network"]["settings"]["net.inet.tcp.timer_fastquantum"]).to eq("100")
      expect(@plugin["network"]["settings"]["net.inet.tcp.timer_slowquantum"]).to eq("500")
      expect(@plugin["network"]["settings"]["net.inet.tcp.win_scale_factor"]).to eq("3")
      expect(@plugin["network"]["settings"]["net.inet.tcp.sockthreshold"]).to eq("64")
      expect(@plugin["network"]["settings"]["net.inet.tcp.bg_target_qdelay"]).to eq("100")
      expect(@plugin["network"]["settings"]["net.inet.tcp.bg_allowed_increase"]).to eq("2")
      expect(@plugin["network"]["settings"]["net.inet.tcp.bg_tether_shift"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.tcp.bg_ss_fltsz"]).to eq("2")
      expect(@plugin["network"]["settings"]["net.inet.udp.checksum"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.udp.maxdgram"]).to eq("9216")
      expect(@plugin["network"]["settings"]["net.inet.udp.recvspace"]).to eq("42080")
      expect(@plugin["network"]["settings"]["net.inet.udp.log_in_vain"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.udp.blackhole"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.udp.pcbcount"]).to eq("72")
      expect(@plugin["network"]["settings"]["net.inet.udp.randomize_ports"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ipsec.def_policy"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ipsec.esp_trans_deflev"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ipsec.esp_net_deflev"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ipsec.ah_trans_deflev"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ipsec.ah_net_deflev"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ipsec.ah_cleartos"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet.ipsec.ah_offsetmask"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ipsec.dfbit"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ipsec.ecn"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ipsec.debug"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ipsec.esp_randpad"]).to eq("-1")
      expect(@plugin["network"]["settings"]["net.inet.ipsec.bypass"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet.ipsec.esp_port"]).to eq("4500")
      expect(@plugin["network"]["settings"]["net.inet.raw.maxdgram"]).to eq("8192")
      expect(@plugin["network"]["settings"]["net.inet.raw.recvspace"]).to eq("8192")
      expect(@plugin["network"]["settings"]["net.link.generic.system.ifcount"]).to eq("10")
      expect(@plugin["network"]["settings"]["net.link.generic.system.dlil_verbose"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.link.generic.system.multi_threaded_input"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.link.generic.system.dlil_input_sanity_check"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.link.ether.inet.prune_intvl"]).to eq("300")
      expect(@plugin["network"]["settings"]["net.link.ether.inet.max_age"]).to eq("1200")
      expect(@plugin["network"]["settings"]["net.link.ether.inet.host_down_time"]).to eq("20")
      expect(@plugin["network"]["settings"]["net.link.ether.inet.apple_hwcksum_tx"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.link.ether.inet.apple_hwcksum_rx"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.link.ether.inet.arp_llreach_base"]).to eq("30")
      expect(@plugin["network"]["settings"]["net.link.ether.inet.maxtries"]).to eq("5")
      expect(@plugin["network"]["settings"]["net.link.ether.inet.useloopback"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.link.ether.inet.proxyall"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.link.ether.inet.sendllconflict"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.link.ether.inet.log_arp_warnings"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.link.ether.inet.keep_announcements"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.link.ether.inet.send_conflicting_probes"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.link.bridge.log_stp"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.link.bridge.debug"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.key.debug"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.key.spi_trycnt"]).to eq("1000")
      expect(@plugin["network"]["settings"]["net.key.spi_minval"]).to eq("256")
      expect(@plugin["network"]["settings"]["net.key.spi_maxval"]).to eq("268435455")
      expect(@plugin["network"]["settings"]["net.key.int_random"]).to eq("60")
      expect(@plugin["network"]["settings"]["net.key.larval_lifetime"]).to eq("30")
      expect(@plugin["network"]["settings"]["net.key.blockacq_count"]).to eq("10")
      expect(@plugin["network"]["settings"]["net.key.blockacq_lifetime"]).to eq("20")
      expect(@plugin["network"]["settings"]["net.key.esp_keymin"]).to eq("256")
      expect(@plugin["network"]["settings"]["net.key.esp_auth"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.key.ah_keymin"]).to eq("128")
      expect(@plugin["network"]["settings"]["net.key.prefered_oldsa"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.key.natt_keepalive_interval"]).to eq("20")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.forwarding"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.redirect"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.hlim"]).to eq("64")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.maxfragpackets"]).to eq("1536")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.accept_rtadv"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.keepfaith"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.log_interval"]).to eq("5")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.hdrnestlimit"]).to eq("15")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.dad_count"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.auto_flowlabel"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.defmcasthlim"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.gifhlim"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.kame_version"]).to eq("2009/apple-darwin")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.use_deprecated"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.rr_prune"]).to eq("5")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.v6only"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.rtexpire"]).to eq("3600")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.rtminexpire"]).to eq("10")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.rtmaxcache"]).to eq("128")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.use_tempaddr"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.temppltime"]).to eq("86400")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.tempvltime"]).to eq("604800")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.auto_linklocal"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.prefer_tempaddr"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.use_defaultzone"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.maxfrags"]).to eq("12288")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.mcast_pmtu"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.neighborgcthresh"]).to eq("1024")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.maxifprefixes"]).to eq("16")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.maxifdefrouters"]).to eq("16")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.maxdynroutes"]).to eq("1024")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.fw.enable"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.fw.debug"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.fw.verbose"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.fw.verbose_limit"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.scopedroute"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.select_srcif_debug"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.mcast.maxgrpsrc"]).to eq("512")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.mcast.maxsocksrc"]).to eq("128")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.mcast.loop"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ip6.only_allow_rfc4193_prefixes"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.ipsec6.def_policy"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ipsec6.esp_trans_deflev"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ipsec6.esp_net_deflev"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ipsec6.ah_trans_deflev"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ipsec6.ah_net_deflev"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.ipsec6.ecn"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.ipsec6.debug"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.ipsec6.esp_randpad"]).to eq("-1")
      expect(@plugin["network"]["settings"]["net.inet6.icmp6.rediraccept"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.icmp6.redirtimeout"]).to eq("600")
      expect(@plugin["network"]["settings"]["net.inet6.icmp6.nd6_prune"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.icmp6.nd6_delay"]).to eq("5")
      expect(@plugin["network"]["settings"]["net.inet6.icmp6.nd6_umaxtries"]).to eq("3")
      expect(@plugin["network"]["settings"]["net.inet6.icmp6.nd6_mmaxtries"]).to eq("3")
      expect(@plugin["network"]["settings"]["net.inet6.icmp6.nd6_useloopback"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.icmp6.nodeinfo"]).to eq("3")
      expect(@plugin["network"]["settings"]["net.inet6.icmp6.errppslimit"]).to eq("500")
      expect(@plugin["network"]["settings"]["net.inet6.icmp6.nd6_maxnudhint"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.icmp6.nd6_debug"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.icmp6.nd6_accept_6to4"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.icmp6.nd6_onlink_ns_rfc4861"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.inet6.icmp6.nd6_llreach_base"]).to eq("30")
      expect(@plugin["network"]["settings"]["net.inet6.mld.gsrdelay"]).to eq("10")
      expect(@plugin["network"]["settings"]["net.inet6.mld.v1enable"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.mld.use_allow"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.inet6.mld.debug"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.idle.route.expire_timeout"]).to eq("30")
      expect(@plugin["network"]["settings"]["net.idle.route.drain_interval"]).to eq("10")
      expect(@plugin["network"]["settings"]["net.statistics"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.alf.loglevel"]).to eq("55")
      expect(@plugin["network"]["settings"]["net.alf.perm"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.alf.defaultaction"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.alf.mqcount"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.smb.fs.version"]).to eq("107000")
      expect(@plugin["network"]["settings"]["net.smb.fs.loglevel"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.smb.fs.kern_ntlmssp"]).to eq("0")
      expect(@plugin["network"]["settings"]["net.smb.fs.kern_deprecatePreXPServers"]).to eq("1")
      expect(@plugin["network"]["settings"]["net.smb.fs.kern_deadtimer"]).to eq("60")
      expect(@plugin["network"]["settings"]["net.smb.fs.kern_hard_deadtimer"]).to eq("600")
      expect(@plugin["network"]["settings"]["net.smb.fs.kern_soft_deadtimer"]).to eq("30")
      expect(@plugin["network"]["settings"]["net.smb.fs.tcpsndbuf"]).to eq("261120")
      expect(@plugin["network"]["settings"]["net.smb.fs.tcprcvbuf"]).to eq("261120")
    end
  end
end
