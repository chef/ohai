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

require "spec_helper"

describe Ohai::System, "zpools plugin" do
  let(:plugin) { get_plugin("zpools") }

  context "on Linux" do
    let(:zpool_status_tank) do
      <<-EOST
  pool: tank
  state: ONLINE
  scan: scrub repaired 0 in 0h0m with 0 errors on Fri Jun  6 14:43:40 2014
  config:

    NAME                       STATE     READ WRITE CKSUM
    tank                       ONLINE       0     0     0
      raidz2-0                 ONLINE       0     0     0
        sdc                    ONLINE       0     0     0
        sdd                    ONLINE       0     0     0
        sde                    ONLINE       0     0     0
        sdf                    ONLINE       0     0     0
        sdg                    ONLINE       0     0     0
        sdh                    ONLINE       0     0     0
      raidz2-1                 ONLINE       0     0     0
        sdi                    ONLINE       0     0     0
        sdj                    ONLINE       0     0     0
        sdk                    ONLINE       0     0     0
        sdl                    ONLINE       0     0     0
        sdm                    ONLINE       0     0     0
        sdn                    ONLINE       0     0     0
      EOST
    end
    let(:zpool_out) do
      <<~EOZO
        rpool	109G	66.2G	42.8G	60%	1.00x	ONLINE	-
        tank	130T	4.91M	130T	0%	1.00x	ONLINE	-
      EOZO
    end
    let(:zpool_status_rpool) do
      <<-EOSR
  pool: rpool
  state: ONLINE
  scan: none requested
  config:

    NAME          STATE     READ WRITE CKSUM
    rpool         ONLINE       0     0     0
      mirror-0    ONLINE       0     0     0
        sda       ONLINE       0     0     0
        sdb       ONLINE       0     0     0

  errors: No known data errors
      EOSR
    end

    before do
      allow(plugin).to receive(:platform_family).and_return("rhel")
      allow(plugin).to receive(:collect_os).and_return(:linux)
      allow(plugin).to receive(:shell_out).with("zpool list -H -o name,size,alloc,free,cap,dedup,health,version").and_return(mock_shell_out(0, zpool_out, ""))
      allow(plugin).to receive(:shell_out).with("zpool status rpool").and_return(mock_shell_out(0, zpool_status_rpool, ""))
      allow(plugin).to receive(:shell_out).with("zpool status tank").and_return(mock_shell_out(0, zpool_status_tank, ""))
    end

    it "Has entries for both zpools" do
      plugin.run
      expect(plugin[:zpools][:rpool]).to be
      expect(plugin[:zpools][:tank]).to be
    end

    it "Has the correct pool size" do
      plugin.run
      expect(plugin[:zpools][:rpool][:pool_size]).to match("109G")
      expect(plugin[:zpools][:tank][:pool_size]).to match("130T")
    end

    it "Has the correct pool allocated size" do
      plugin.run
      expect(plugin[:zpools][:rpool][:pool_allocated]).to match("66.2G")
      expect(plugin[:zpools][:tank][:pool_allocated]).to match("4.91M")
    end

    it "Has the correct pool free size" do
      plugin.run
      expect(plugin[:zpools][:rpool][:pool_free]).to match("42.8G")
      expect(plugin[:zpools][:tank][:pool_free]).to match("130T")
    end

    it "Has the correct capacity_used" do
      plugin.run
      expect(plugin[:zpools][:rpool][:capacity_used]).to match("60%")
      expect(plugin[:zpools][:tank][:capacity_used]).to match("0%")
    end

    it "Has the correct dedup_factor" do
      plugin.run
      expect(plugin[:zpools][:rpool][:dedup_factor]).to match("1.00x")
      expect(plugin[:zpools][:tank][:dedup_factor]).to match("1.00x")
    end

    it "Has the correct health" do
      plugin.run
      expect(plugin[:zpools][:rpool][:health]).to match("ONLINE")
      expect(plugin[:zpools][:tank][:health]).to match("ONLINE")
    end

    it "Has the correct number of devices" do
      plugin.run
      expect(plugin[:zpools][:rpool][:devices].keys.size).to match(2)
      expect(plugin[:zpools][:tank][:devices].keys.size).to match(12)
    end

    it "Won't have a version number" do
      plugin.run
      expect(plugin[:zpools][:rpool][:zpool_version]).to be_nil
      expect(plugin[:zpools][:tank][:zpool_version]).to be_nil
    end
  end

  context "on Solaris2" do
    let(:zpool_status_tank) do
      <<~EOST
        pool: tank
        state: ONLINE
        scan: scrub repaired 0 in 0h0m with 0 errors on Fri Jun  6 14:43:40 2014
        config:

              NAME                       STATE     READ WRITE CKSUM
              tank                       ONLINE       0     0     0
                raidz2-0                 ONLINE       0     0     0
                  c1t50014EE209D1DBA9d0  ONLINE       0     0     0
                  c1t50014EE20A0ECED2d0  ONLINE       0     0     0
                  c1t50014EE20A106BFFd0  ONLINE       0     0     0
                  c1t50014EE20A1423E8d0  ONLINE       0     0     0
                  c1t50014EE20A145447d0  ONLINE       0     0     0
                  c1t50014EE20A29EE56d0  ONLINE       0     0     0
                raidz2-1                 ONLINE       0     0     0
                  c1t50014EE20A2B984Cd0  ONLINE       0     0     0
                  c1t50014EE20A2BBC78d0  ONLINE       0     0     0
                  c1t50014EE20A2BDCA9d0  ONLINE       0     0     0
                  c1t50014EE25F697DC4d0  ONLINE       0     0     0
                  c1t50014EE25F698BECd0  ONLINE       0     0     0
                  c1t50014EE25F6998DAd0  ONLINE       0     0     0
      EOST
    end
    let(:zpool_out) do
      <<~EOZO
        rpool   109G    66.2G   42.8G   60%     1.00x   ONLINE  34
        tank    130T    4.91M   130T    0%      1.00x   ONLINE  34
      EOZO
    end
    let(:zpool_status_rpool) do
      <<~EOSR
        pool: rpool
        state: ONLINE
        scan: resilvered 65.6G in 0h8m with 0 errors on Fri Jun  6 14:22:40 2014
        config:

              NAME          STATE     READ WRITE CKSUM
              rpool         ONLINE       0     0     0
                mirror-0    ONLINE       0     0     0
                  c3t5d0s0  ONLINE       0     0     0
                  c3t4d0s0  ONLINE       0     0     0

        errors: No known data errors
      EOSR
    end

    before do
      allow(plugin).to receive(:platform_family).and_return("solaris2")
      allow(plugin).to receive(:collect_os).and_return(:solaris2)
      allow(plugin).to receive(:shell_out).with("zpool list -H -o name,size,alloc,free,cap,dedup,health,version").and_return(mock_shell_out(0, zpool_out, ""))
      allow(plugin).to receive(:shell_out).with("su adm -c \"zpool status rpool\"").and_return(mock_shell_out(0, zpool_status_rpool, ""))
      allow(plugin).to receive(:shell_out).with("su adm -c \"zpool status tank\"").and_return(mock_shell_out(0, zpool_status_tank, ""))
    end

    it "Has entries for both zpools" do
      plugin.run
      expect(plugin[:zpools][:rpool]).to be
      expect(plugin[:zpools][:tank]).to be
    end

    it "Has the correct pool size" do
      plugin.run
      expect(plugin[:zpools][:rpool][:pool_size]).to match("109G")
      expect(plugin[:zpools][:tank][:pool_size]).to match("130T")
    end

    it "Has the correct pool allocated size" do
      plugin.run
      expect(plugin[:zpools][:rpool][:pool_allocated]).to match("66.2G")
      expect(plugin[:zpools][:tank][:pool_allocated]).to match("4.91M")
    end

    it "Has the correct pool free size" do
      plugin.run
      expect(plugin[:zpools][:rpool][:pool_free]).to match("42.8G")
      expect(plugin[:zpools][:tank][:pool_free]).to match("130T")
    end

    it "Has the correct capacity_used" do
      plugin.run
      expect(plugin[:zpools][:rpool][:capacity_used]).to match("60%")
      expect(plugin[:zpools][:tank][:capacity_used]).to match("0%")
    end

    it "Has the correct dedup_factor" do
      plugin.run
      expect(plugin[:zpools][:rpool][:dedup_factor]).to match("1.00x")
      expect(plugin[:zpools][:tank][:dedup_factor]).to match("1.00x")
    end

    it "Has the correct health" do
      plugin.run
      expect(plugin[:zpools][:rpool][:health]).to match("ONLINE")
      expect(plugin[:zpools][:tank][:health]).to match("ONLINE")
    end

    it "Has the correct number of devices" do
      plugin.run
      expect(plugin[:zpools][:rpool][:devices].keys.size).to match(2)
      expect(plugin[:zpools][:tank][:devices].keys.size).to match(12)
    end

    it "Has a version number" do
      plugin.run
      expect(plugin[:zpools][:rpool][:zpool_version]).to match("34")
      expect(plugin[:zpools][:tank][:zpool_version]).to match("34")
    end
  end
end
