#
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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

require_relative "spec_helper"

describe Ohai::System, "Solaris2.X filesystem plugin" do
  let(:plugin) { get_plugin("filesystem") }

  before do
    allow(plugin).to receive(:collect_os).and_return("solaris2")
  end

  describe "filesystem properties" do
    let(:plugin_config) { {} }

    before do
      @original_plugin_config = Ohai.config[:plugin]
      Ohai.config[:plugin] = plugin_config
      allow(plugin).to receive(:shell_out).with("df -Pka").and_return(mock_shell_out(0, "", ""))
      allow(plugin).to receive(:shell_out).with("df -na").and_return(mock_shell_out(0, "", ""))
      allow(plugin).to receive(:shell_out).with("mount").and_return(mock_shell_out(0, "", ""))
      allow(plugin).to receive(:shell_out).with("zfs get -p -H all").and_return(mock_shell_out(0, "", ""))

      @df_pka = <<~DF_PKA
        Filesystem           1024-blocks        Used   Available Capacity  Mounted on
        rpool/ROOT/solaris-0   730451045     2172071   727373448     1%    /
        rpool/ROOT/solaris-0/var 730451045      850302   727373448     1%    /var
        /dev                           0           0           0     0%    /dev
        proc                           0           0           0     0%    /proc
        ctfs                           0           0           0     0%    /system/contract
        mnttab                         0           0           0     0%    /etc/mnttab
        objfs                          0           0           0     0%    /system/object
        swap                    18544280         568    18543712     1%    /system/volatile
        sharefs                        0           0           0     0%    /etc/dfs/sharetab
        fd                             0           0           0     0%    /dev/fd
        swap                    18666120      122408    18543712     1%    /tmp
        rpool/VARSHARE         730451045        1181   727373448     1%    /var/share
        rpool/export           730451045          32   727373448     1%    /export
        rpool/export/home      730451045      182277   727373448     1%    /export/home
        rpool                  730451045          31   727373448     1%    /rpool
        rpool/VARSHARE/pkg     730451045          32   727373448     1%    /var/share/pkg
        rpool/VARSHARE/pkg/repositories 730451045          31   727373448     1%    /var/share/pkg/repositories
        rpool/export/home/shian   730451045          37   727373448     1%    /export/home/shain
        rpool/export/home/phild 730451045          38   727373448     1%    /export/home/phild
        r
        -hosts                         0           0           0     0%    /net
        auto_home                      0           0           0     0%    /home
        -fedfs 0 0 0 0% /nfs4
      DF_PKA

      @mount = <<~MOUNT
        / on rpool/ROOT/solaris-0 read/write/setuid/nodevices/rstchown/nonbmand/exec/xattr/atime/mountpoint=/zones/servername.chef.internal.dns/root//zone=servername.chef.internal.dns/nozonemod/sharezone=151/dev=4bd0b7e on Fri Feb  2 16:27:36 2018
        /var on rpool/ROOT/solaris-0/var read/write/setuid/nodevices/rstchown/nonbmand/exec/xattr/atime/mountpoint=/zones/servername.chef.internal.dns/root/var/zone=servername.chef.internal.dns/nozonemod/sharezone=151/dev=4bd0b7f on Fri Feb  2 16:27:36 2018
        /dev on /dev read/write/setuid/devices/rstchown/zone=servername.chef.internal.dns/nozonemod/sharezone=151/dev=8f8003a on Fri Feb  2 16:27:36 2018
        /proc on proc read/write/setuid/nodevices/rstchown/zone=servername.chef.internal.dns/sharezone=151/dev=8f40096 on Fri Feb  2 16:27:37 2018
        /system/contract on ctfs read/write/setuid/nodevices/rstchown/zone=servername.chef.internal.dns/sharezone=151/dev=8fc0097 on Fri Feb  2 16:27:37 2018
        /etc/mnttab on mnttab read/write/setuid/nodevices/rstchown/zone=servername.chef.internal.dns/sharezone=151/dev=9000097 on Fri Feb  2 16:27:37 2018
        /system/object on objfs read/write/setuid/nodevices/rstchown/zone=servername.chef.internal.dns/sharezone=151/dev=9080097 on Fri Feb  2 16:27:37 2018
        /system/volatile on swap read/write/setuid/nodevices/rstchown/xattr/zone=servername.chef.internal.dns/sharezone=151/dev=90406f0 on Fri Feb  2 16:27:37 2018
        /etc/dfs/sharetab on sharefs read/write/setuid/nodevices/rstchown/zone=servername.chef.internal.dns/sharezone=151/dev=90c004d on Fri Feb  2 16:27:37 2018
        /dev/fd on fd read/write/setuid/nodevices/rstchown/zone=servername.chef.internal.dns/sharezone=151/dev=91c007d on Fri Feb  2 16:27:44 2018
        /tmp on swap read/write/setuid/nodevices/rstchown/xattr/zone=servername.chef.internal.dns/sharezone=151/dev=90406f1 on Fri Feb  2 16:27:45 2018
        /var/share on rpool/VARSHARE read/write/setuid/nodevices/rstchown/nonbmand/exec/xattr/atime/zone=servername.chef.internal.dns/sharezone=151/dev=4bd0b80 on Fri Feb  2 16:27:45 2018
        /export on rpool/export read/write/setuid/nodevices/rstchown/nonbmand/exec/xattr/atime/zone=servername.chef.internal.dns/sharezone=151/dev=4bd0b81 on Fri Feb  2 16:28:11 2018
        /export/home on rpool/export/home read/write/setuid/nodevices/rstchown/nonbmand/exec/xattr/atime/zone=servername.chef.internal.dns/sharezone=151/dev=4bd0b82 on Fri Feb  2 16:28:11 2018
        /rpool on rpool read/write/setuid/nodevices/rstchown/nonbmand/exec/xattr/atime/zone=servername.chef.internal.dns/sharezone=151/dev=4bd0b83 on Fri Feb  2 16:28:11 2018
        /var/share/pkg on rpool/VARSHARE/pkg read/write/setuid/nodevices/rstchown/nonbmand/exec/xattr/atime/zone=servername.chef.internal.dns/sharezone=151/dev=4bd0b84 on Fri Feb  2 16:28:12 2018
        /var/share/pkg/repositories on rpool/VARSHARE/pkg/repositories read/write/setuid/nodevices/rstchown/nonbmand/exec/xattr/atime/zone=servername.chef.internal.dns/sharezone=151/dev=4bd0b85 on Fri Feb  2 16:28:12 2018
        /export/home/<usernameredacted> on rpool/export/home/<usernameredacted> read/write/setuid/nodevices/rstchown/nonbmand/exec/xattr/atime/zone=servername.chef.internal.dns/sharezone=151/dev=4bd0b8a on Fri Feb  2 16:39:15 2018
        /export/home/<usernameredacted> on rpool/export/home/<usernameredacted> read/write/setuid/nodevices/rstchown/nonbmand/exec/xattr/atime/zone=servername.chef.internal.dns/sharezone=151/dev=4bd0b8b on Fri Feb 2 16:39:16 2018
      MOUNT

      @zfs_get = <<~ZFS_GET
        data0   type    filesystem      -
        data0   creation        1331514391      -
        data0   used    7926803118480   -
        data0   available       3666345412208   -
        data0   referenced      60350619952     -
        data0   compressratio   1.04x   -
        data0   mounted yes     -
        data0   quota   0       default
        data0   reservation     0       default
        data0   recordsize      131072  default
        data0   mountpoint      /data0  default
        data0   sharenfs        rw=192.168.130.0/24,rw=[2001:470:1f05:2c9::]/64,rw=[2001:470:8122:dd40::10]     local
        data0   checksum        on      default
        data0   compression     off     local
        data0   atime   off     local
        data0   devices on      default
        data0   exec    on      default
        data0   setuid  on      default
        data0   readonly        off     default
        data0   zoned   off     default
        data0   snapdir hidden  default
        data0   aclinherit      restricted      default
        data0   canmount        on      default
        data0   xattr   on      default
        data0   copies  1       default
        data0   version 5       -
        data0   utf8only        off     -
        data0   normalization   none    -
        data0   casesensitivity sensitive       -
        data0   vscan   off     default
        data0   nbmand  off     default
        data0   sharesmb        off     default
        data0   refquota        0       default
        data0   refreservation  0       default
        data0   primarycache    all     default
        data0   secondarycache  all     default
        data0   usedbysnapshots 157243047152    -
        data0   usedbydataset   60350619952     -
        data0   usedbychildren  7709209451376   -
        data0   usedbyrefreservation    0       -
        data0   logbias latency default
        data0   dedup   off     default
        data0   mlslabel        none    default
        data0   sync    standard        default
        data0   refcompressratio        1.29x   -
        data0   written 4183965296      -
        data0   logicalused     8240006744576   -
        data0   logicalreferenced       75625359872     -
        data0   filesystem_limit        18446744073709551615    default
        data0   snapshot_limit  18446744073709551615    default
        data0   filesystem_count        18446744073709551615    default
        data0   snapshot_count  18446744073709551615    default
        data0   snapdev hidden  default
        data0   acltype off     default
        data0   context none    default
        data0   fscontext       none    default
        data0   defcontext      none    default
        data0   rootcontext     none    default
        data0   relatime        off     default
        data0   redundant_metadata      all     default
        data0   overlay off     default
        data0@20130228  type    snapshot        -
        data0@20130228  creation        1362119670      -
        data0@20130228  used    0       -
        data0@20130228  referenced      57161787648     -
        data0@20130228  compressratio   1.30x   -
        data0@20130228  devices on      default
        data0@20130228  exec    on      default
        data0@20130228  setuid  on      default
        data0@20130228  xattr   on      default
        data0@20130228  version 5       -
        data0@20130228  utf8only        off     -
        data0@20130228  normalization   none    -
        data0@20130228  casesensitivity sensitive       -
        data0@20130228  nbmand  off     default
        data0@20130228  primarycache    all     default
        data0@20130228  secondarycache  all     default
        data0@20130228  defer_destroy   off     -
        data0@20130228  userrefs        0       -
        data0@20130228  mlslabel        none    default
        data0@20130228  refcompressratio        1.30x   -
        data0@20130228  written 57161787648     -
        data0@20130228  clones          -
        data0@20130228  logicalused     0       -
        data0@20130228  logicalreferenced       72138856960     -
        data0@20130228  acltype off     default
        data0@20130228  context none    default
        data0@20130228  fscontext       none    default
        data0@20130228  defcontext      none    default
        data0@20130228  rootcontext     none    default
        data0@20130301  type    snapshot        -
        data0@20130301  creation        1362122621      -
        data0@20130301  used    0       -
        data0@20130301  referenced      57161787648     -
        data0@20130301  compressratio   1.30x   -
        data0@20130301  devices on      default
        data0@20130301  exec    on      default
        data0@20130301  setuid  on      default
        data0@20130301  xattr   on      default
        data0@20130301  version 5       -
        data0@20130301  utf8only        off     -
        data0@20130301  normalization   none    -
        data0@20130301  casesensitivity sensitive       -
        data0@20130301  nbmand  off     default
        data0@20130301  primarycache    all     default
        data0@20130301  secondarycache  all     default
        data0@20130301  defer_destroy   off     -
        data0@20130301  userrefs        0       -
        data0@20130301  mlslabel        none    default
        data0@20130301  refcompressratio        1.30x   -
        data0@20130301  written 0       -
        data0@20130301  clones          -
        data0@20130301  logicalused     0       -
        data0@20130301  logicalreferenced       72138856960     -
        data0@20130301  acltype off     default
        data0@20130301  context none    default
        data0@20130301  fscontext       none    default
        data0@20130301  defcontext      none    default
        data0@20130301  rootcontext     none    default
        data0@20130310  type    snapshot        -
        data0@20130310  creation        1362955150      -
        data0@20130310  used    281392  -
        data0@20130310  referenced      57173475232     -
        data0@20130310  compressratio   1.30x   -
        data0@20130310  devices on      default
        data0@20130310  exec    on      default
        data0@20130310  setuid  on      default
        data0@20130310  xattr   on      default
        data0@20130310  version 5       -
        data0@20130310  utf8only        off     -
        data0@20130310  normalization   none    -
        data0@20130310  casesensitivity sensitive       -
        data0@20130310  nbmand  off     default
        data0@20130310  primarycache    all     default
        data0@20130310  secondarycache  all     default
        data0@20130310  defer_destroy   off     -
        data0@20130310  userrefs        0       -
        data0@20130310  mlslabel        none    default
        data0@20130310  refcompressratio        1.30x   -
        data0@20130310  written 11968976        -
        data0@20130310  clones          -
        data0@20130310  logicalused     0       -
        data0@20130310  logicalreferenced       72164488192     -
        data0@20130310  acltype off     default
        data0@20130310  context none    default
        data0@20130310  fscontext       none    default
        data0@20130310  defcontext      none    default
        data0@20130310  rootcontext     none    default
        data0@20160311  type    snapshot        -
        data0@20160311  creation        1457762233      -
        data0@20160311  used    155723556528    -
        data0@20160311  referenced      211890289712    -
        data0@20160311  compressratio   1.24x   -
        data0@20160311  devices on      default
        data0@20160311  exec    on      default
        data0@20160311  setuid  on      default
        data0@20160311  xattr   on      default
        data0@20160311  version 5       -
        data0@20160311  utf8only        off     -
        data0@20160311  normalization   none    -
        data0@20160311  casesensitivity sensitive       -
        data0@20160311  nbmand  off     default
        data0@20160311  primarycache    all     default
        data0@20160311  secondarycache  all     default
        data0@20160311  defer_destroy   off     -
        data0@20160311  userrefs        0       -
        data0@20160311  mlslabel        none    default
        data0@20160311  refcompressratio        1.24x   -
        data0@20160311  written 156235945184    -
        data0@20160311  clones          -
        data0@20160311  logicalused     0       -
        data0@20160311  logicalreferenced       259598664192    -
        data0@20160311  acltype off     default
        data0@20160311  context none    default
        data0@20160311  fscontext       none    default
        data0@20160311  defcontext      none    default
        data0@20160311  rootcontext     none    default
        data0/Movies    type    filesystem      -
        data0/Movies    creation        1331530217      -
        data0/Movies    used    642640700304    -
        data0/Movies    available       3666345412208   -
        data0/Movies    referenced      586525311344    -
        data0/Movies    compressratio   1.00x   -
        data0/Movies    mounted yes     -
        data0/Movies    quota   0       default
        data0/Movies    reservation     0       default
        data0/Movies    recordsize      131072  default
        data0/Movies    mountpoint      /data0/Movies   default
        data0/Movies    sharenfs        sec=sys,rw=192.168.130.0/24,rw=192.168.135.0/24,rw=[2001:470:1f05:2c9::]/64,rw=[2001:470:8122::]/48,rw=[2001:470:8122:dd40::10]local
        data0/Movies    checksum        on      default
        data0/Movies    compression     off     inherited from data0
        data0/Movies    atime   off     local
        data0/Movies    devices on      default
        data0/Movies    exec    on      default
        data0/Movies    setuid  on      default
        data0/Movies    readonly        off     default
        data0/Movies    zoned   off     default
        data0/Movies    snapdir hidden  default
        data0/Movies    aclinherit      restricted      default
        data0/Movies    canmount        on      default
        data0/Movies    xattr   on      default
        data0/Movies    copies  1       default
        data0/Movies    version 5       -
        data0/Movies    utf8only        off     -
        data0/Movies    normalization   none    -
        data0/Movies    casesensitivity sensitive       -
        data0/Movies    vscan   off     default
        data0/Movies    nbmand  off     default
        data0/Movies    sharesmb        off     local
        data0/Movies    refquota        0       default
        data0/Movies    refreservation  0       default
        data0/Movies    primarycache    all     default
        data0/Movies    secondarycache  all     default
        data0/Movies    usedbysnapshots 56115388960     -
        data0/Movies    usedbydataset   586525311344    -
        data0/Movies    usedbychildren  0       -
        data0/Movies    usedbyrefreservation    0       -
        data0/Movies    logbias latency default
        data0/Movies    dedup   off     default
        data0/Movies    mlslabel        none    default
        data0/Movies    sync    standard        default
        data0/Movies    refcompressratio        1.00x   -
        data0/Movies    written 197038505024    -
        data0/Movies    logicalused     642795343360    -
        data0/Movies    logicalreferenced       586666194432    -
        data0/Movies    filesystem_limit        18446744073709551615    default
        data0/Movies    snapshot_limit  18446744073709551615    default
        data0/Movies    filesystem_count        18446744073709551615    default
        data0/Movies    snapshot_count  18446744073709551615    default
        data0/Movies    snapdev hidden  default
        data0/Movies    acltype off     default
        data0/Movies    context none    default
        data0/Movies    fscontext       none    default
        data0/Movies    defcontext      none    default
        data0/Movies    rootcontext     none    default
        data0/Movies    relatime        off     default
        data0/Movies    redundant_metadata      all     default
        data0/Movies overlay off default:
      ZFS_GET
    end

    after do
      Ohai.config[:plugin] = @original_plugin_config
    end

    context "reports filesystem data" do
      before do
        allow(plugin).to receive(:shell_out)
          .with("mount")
          .and_return(mock_shell_out(0, @mount, nil))
        allow(plugin).to receive(:shell_out)
          .with("df -Pka")
          .and_return(mock_shell_out(0, @df_pka, nil))
        # TODO: get this output
        # allow(plugin).to receive(:shell_out)
        #   .with("df -na")
        #   .and_return(mock_shell_out(0, @df_na, nil))
        plugin.run
      end

      it "returns kb_used" do
        expect(plugin[:filesystem]["rpool/VARSHARE"]["kb_used"]).to eq("1181")
        expect(plugin[:filesystem2]["by_pair"]["rpool/VARSHARE,/var/share"]["kb_used"]).to eq("1181")
      end

      it "returns mount" do
        expect(plugin[:filesystem]["rpool/VARSHARE"]["mount"]).to eq("/var/share")
        expect(plugin[:filesystem2]["by_pair"]["rpool/VARSHARE,/var/share"]["mount"]).to eq("/var/share")
      end

      it "returns mount_opts" do
        opts = %w{
          read
          write
          setuid
          nodevices
          rstchown
          nonbmand
          exec
          xattr
          atime
          zone=servername.chef.internal.dns
          sharezone=151
          dev=4bd0b80
        }
        expect(plugin[:filesystem]["rpool/VARSHARE"]["mount_options"]).to eq(opts)
        expect(plugin[:filesystem2]["by_pair"]["rpool/VARSHARE,/var/share"]["mount_options"]).to eq(opts)
      end
    end

    context "handles zfs properties" do
      before do
        allow(plugin).to receive(:shell_out)
          .with("zfs get -p -H all")
          .and_return(mock_shell_out(0, @zfs_get, nil))
        plugin.run
      end

      it "returns top-level stats" do
        # old API
        expect(plugin[:filesystem]["data0"]["fs_type"]).to eq("zfs")
        expect(plugin[:filesystem]["data0"]["mount"]).to eq("/data0")

        # new API
        expect(plugin[:filesystem2]["by_pair"]["data0,/data0"]["fs_type"]).to eq("zfs")
        expect(plugin[:filesystem2]["by_pair"]["data0,/data0"]["mount"]).to eq("/data0")
      end

      it "returns zfs-specific properties" do
        # old API
        expect(plugin[:filesystem]["data0"]["zfs_values"]["used"]).to eq("7926803118480")
        expect(plugin[:filesystem]["data0"]["zfs_sources"]["used"]).to eq("-")

        # new API
        expect(plugin[:filesystem2]["by_pair"]["data0,/data0"]["zfs_properties"]["used"]["value"]).to eq("7926803118480")
        expect(plugin[:filesystem2]["by_pair"]["data0,/data0"]["zfs_properties"]["used"]["source"]).to eq("-")
      end
    end
  end
end
