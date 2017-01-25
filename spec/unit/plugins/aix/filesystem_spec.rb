#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

require_relative "../../../spec_helper.rb"

describe Ohai::System, "AIX filesystem plugin" do
  before(:each) do
    @df_pk_lpar = <<-DF_PK
Filesystem    1024-blocks      Used Available Capacity Mounted on
/dev/hd4          2097152    219796   1877356      11% /
/dev/hd2          5242880   2416828   2826052      47% /usr
/dev/hd9var       5242880    395540   4847340       8% /var
/dev/hd3          5242880   1539508   3703372      30% /tmp
/dev/hd1         10485760      1972  10483788       1% /home
/dev/hd11admin      131072       380    130692       1% /admin
/proc                   -         -         -       -  /proc
/dev/hd10opt      5242880   1286720   3956160      25% /opt
/dev/livedump      262144       368    261776       1% /var/adm/ras/livedump
/dev/fslv00        524288     45076    479212       9% /wpars/sink-thinker-541ba3
/dev/fslv01       2097152      8956   2088196       1% /wpars/sink-thinker-541ba3/home
/dev/fslv02       5242880   1307352   3935528      25% /wpars/sink-thinker-541ba3/opt
/proc                   -         -         -       -  /wpars/sink-thinker-541ba3/proc
/dev/fslv03       1048576    168840    879736      17% /wpars/sink-thinker-541ba3/tmp
/dev/fslv04       5242880   2725040   2517840      52% /wpars/sink-thinker-541ba3/usr
/dev/fslv05        524288     76000    448288      15% /wpars/sink-thinker-541ba3/var
/dev/fslv07      10485760    130872  10354888       2% /wpars/toolchain-tester-5c969f
/dev/fslv08       5242880     39572   5203308       1% /wpars/toolchain-tester-5c969f/home
/dev/fslv09       5242880   1477164   3765716      29% /wpars/toolchain-tester-5c969f/opt
/proc                   -         -         -       -  /wpars/toolchain-tester-5c969f/proc
/dev/fslv10       5242880     42884   5199996       1% /wpars/toolchain-tester-5c969f/tmp
/dev/fslv11       5242880   2725048   2517832      52% /wpars/toolchain-tester-5c969f/usr
/dev/fslv12      10485760    272376  10213384       3% /wpars/toolchain-tester-5c969f/var
DF_PK

    @df_pk_wpar = <<-DF_PK
Filesystem    1024-blocks      Used Available Capacity Mounted on
Global           10485760    130872  10354888       2% /
Global            5242880     39572   5203308       1% /home
Global            5242880   1477164   3765716      29% /opt
Global                  -         -         -       -  /proc
Global            5242880     42884   5199996       1% /tmp
Global            5242880   2725048   2517832      52% /usr
Global           10485760    272376  10213384       3% /var
DF_PK

    @mount_lpar = <<-MOUNT
  node       mounted        mounted over    vfs       date        options
-------- ---------------  ---------------  ------ ------------ ---------------
         /dev/hd4         /                jfs2   Jul 17 13:22 rw,log=/dev/hd8
         /dev/hd2         /usr             jfs2   Jul 17 13:22 rw,log=/dev/hd8
         /dev/hd9var      /var             jfs2   Jul 17 13:22 rw,log=/dev/hd8
         /dev/hd3         /tmp             jfs2   Jul 17 13:22 rw,log=/dev/hd8
         /dev/hd1         /home            jfs2   Jul 17 13:22 rw,log=/dev/hd8
         /dev/hd11admin   /admin           jfs2   Jul 17 13:22 rw,log=/dev/hd8
         /proc            /proc            procfs Jul 17 13:22 rw
         /dev/hd10opt     /opt             jfs2   Jul 17 13:22 rw,log=/dev/hd8
192.168.1.11 /stage/middleware /stage/middleware nfs3   Jul 17 13:24 ro,bg,hard,intr,sec=sys
MOUNT

    @mount_wpar = <<-MOUNT
  node       mounted        mounted over    vfs       date        options
-------- ---------------  ---------------  ------ ------------ ---------------
         Global           /                jfs2   Nov 23 21:03 rw,log=NULL
         Global           /home            jfs2   Nov 23 21:03 rw,log=NULL
         Global           /opt             jfs2   Nov 23 21:03 rw,log=NULL
         Global           /proc            namefs Nov 23 21:03 rw
         Global           /tmp             jfs2   Nov 23 21:03 rw,log=NULL
         Global           /usr             jfs2   Nov 23 21:03 rw,log=NULL
         Global           /var             jfs2   Nov 23 21:03 rw,log=NULL
192.168.1.11 /stage/middleware /stage/middleware nfs3   Jul 17 13:24 ro,bg,hard,intr,sec=sys
MOUNT

    @plugin = get_plugin("aix/filesystem")
    allow(@plugin).to receive(:collect_os).and_return(:aix)
    @plugin[:filesystem] = Mash.new
  end

  context "when run within an LPAR" do
    before do
      allow(@plugin).to receive(:shell_out).with("df -Pk").and_return(mock_shell_out(0, @df_pk_lpar, nil))
      allow(@plugin).to receive(:shell_out).with("mount").and_return(mock_shell_out(0, @mount_lpar, nil))
      @plugin.run
    end

    describe "df -Pk" do

      it "returns the filesystem block size" do
        expect(@plugin[:filesystem]["/dev/hd4"]["kb_size"]).to eq("2097152")
      end

      it "returns the filesystem used space in kb" do
        expect(@plugin[:filesystem]["/dev/hd4"]["kb_used"]).to eq("219796")
      end

      it "returns the filesystem available space in kb" do
        expect(@plugin[:filesystem]["/dev/hd4"]["kb_available"]).to eq("1877356")
      end

      it "returns the filesystem capacity in percentage" do
        expect(@plugin[:filesystem]["/dev/hd4"]["percent_used"]).to eq("11%")
      end

      it "returns the filesystem mounted location" do
        expect(@plugin[:filesystem]["/dev/hd4"]["mount"]).to eq("/")
      end
    end

    describe "mount" do

      it "returns the filesystem mount location" do
        expect(@plugin[:filesystem]["/dev/hd4"]["mount"]).to eq("/")
      end

      it "returns the filesystem type" do
        expect(@plugin[:filesystem]["/dev/hd4"]["fs_type"]).to eq("jfs2")
      end

      it "returns the filesystem mount options" do
        expect(@plugin[:filesystem]["/dev/hd4"]["mount_options"]).to eq(["rw", "log=/dev/hd8"])
      end

      # For entries like 192.168.1.11 /stage/middleware /stage/middleware nfs3   Jul 17 13:24 ro,bg,hard,intr,sec=sys
      context "having node values" do

        it "returns the filesystem mount location" do
          expect(@plugin[:filesystem]["192.168.1.11:/stage/middleware"]["mount"]).to eq("/stage/middleware")
        end

        it "returns the filesystem type" do
          expect(@plugin[:filesystem]["192.168.1.11:/stage/middleware"]["fs_type"]).to eq("nfs3")
        end

        it "returns the filesystem mount options" do
          expect(@plugin[:filesystem]["192.168.1.11:/stage/middleware"]["mount_options"]).to eq(["ro", "bg", "hard", "intr", "sec=sys"])
        end
      end
    end
  end

  context "when run within a WPAR" do
    before do
      allow(@plugin).to receive(:shell_out).with("df -Pk").and_return(mock_shell_out(0, @df_pk_wpar, nil))
      allow(@plugin).to receive(:shell_out).with("mount").and_return(mock_shell_out(0, @mount_wpar, nil))
      @plugin.run
    end

    describe "df -Pk" do

      it "returns the filesystem block size" do
        expect(@plugin[:filesystem]["Global:/"]["kb_size"]).to eq("10485760")
      end

      it "returns the filesystem used space in kb" do
        expect(@plugin[:filesystem]["Global:/"]["kb_used"]).to eq("130872")
      end

      it "returns the filesystem available space in kb" do
        expect(@plugin[:filesystem]["Global:/"]["kb_available"]).to eq("10354888")
      end

      it "returns the filesystem capacity in percentage" do
        expect(@plugin[:filesystem]["Global:/"]["percent_used"]).to eq("2%")
      end

      it "returns the filesystem mounted location" do
        expect(@plugin[:filesystem]["Global:/"]["mount"]).to eq("/")
      end
    end

    describe "mount" do

      it "returns the filesystem mount location" do
        expect(@plugin[:filesystem]["Global:/"]["mount"]).to eq("/")
      end

      it "returns the filesystem type" do
        expect(@plugin[:filesystem]["Global:/"]["fs_type"]).to eq("jfs2")
      end

      it "returns the filesystem mount options" do
        expect(@plugin[:filesystem]["Global:/"]["mount_options"]).to eq(["rw", "log=NULL"])
      end

      # For entries like 192.168.1.11 /stage/middleware /stage/middleware nfs3   Jul 17 13:24 ro,bg,hard,intr,sec=sys
      context "having node values" do

        it "returns the filesystem mount location" do
          expect(@plugin[:filesystem]["192.168.1.11:/stage/middleware"]["mount"]).to eq("/stage/middleware")
        end

        it "returns the filesystem type" do
          expect(@plugin[:filesystem]["192.168.1.11:/stage/middleware"]["fs_type"]).to eq("nfs3")
        end

        it "returns the filesystem mount options" do
          expect(@plugin[:filesystem]["192.168.1.11:/stage/middleware"]["mount_options"]).to eq(["ro", "bg", "hard", "intr", "sec=sys"])
        end
      end
    end
  end
end
