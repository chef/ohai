require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "Solaris 2.x zpool plugin" do
  before(:each) do
    @plugin = get_plugin("solaris2/zpools")
    @plugin.stub(:collect_os).and_return(:solaris2)

    @zpool_status_rpool = <<-EOSR
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

    @zpool_status_tank = <<-EOST
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
    @zpool_out = <<-EOZO
rpool   109G    66.2G   42.8G   60%     1.00x   ONLINE  34
tank    130T    4.91M   130T    0%      1.00x   ONLINE  34
EOZO
    @plugin.stub(:shell_out)
      .with("zpool list -H -o name,size,alloc,free,cap,dedup,health,version")
      .and_return(mock_shell_out(0,@zpool_out,""))
    @plugin.stub(:shell_out)
      .with("su adm -c \"zpool status rpool\"")
      .and_return(mock_shell_out(0,@zpool_status_rpool,""))
    @plugin.stub(:shell_out)
      .with("su adm -c \"zpool status tank\"")
      .and_return(mock_shell_out(0,@zpool_status_tank,""))
  end

  describe "On Solaris2 Common" do
    it "Should have entries for both zpools" do
      @plugin.run
      expect(@plugin[:zpools][:rpool]).to be
      expect(@plugin[:zpools][:tank]).to be
    end

    it "Should have the correct pool size" do
      @plugin.run
      expect(@plugin[:zpools][:rpool][:pool_size]).to match("109G")
      expect(@plugin[:zpools][:tank][:pool_size]).to match("130T")
    end

    it "Should have the correct pool allocated size" do
      @plugin.run
      expect(@plugin[:zpools][:rpool][:pool_allocated]).to match("66.2G")
      expect(@plugin[:zpools][:tank][:pool_allocated]).to match("4.91M")
    end

    it "Should have the correct pool free size" do
      @plugin.run
      expect(@plugin[:zpools][:rpool][:pool_free]).to match("42.8G")
      expect(@plugin[:zpools][:tank][:pool_free]).to match("130T")
    end

    it "Should have the correct capacity_used" do
      @plugin.run
      expect(@plugin[:zpools][:rpool][:capacity_used]).to match("60%")
      expect(@plugin[:zpools][:tank][:capacity_used]).to match("0%")
    end

    it "Should have the correct dedup_factor" do
      @plugin.run
      expect(@plugin[:zpools][:rpool][:dedup_factor]).to match("1.00x")
      expect(@plugin[:zpools][:tank][:dedup_factor]).to match("1.00x")
    end

    it "Should have the correct health" do
      @plugin.run
      expect(@plugin[:zpools][:rpool][:health]).to match("ONLINE")
      expect(@plugin[:zpools][:tank][:health]).to match("ONLINE")
    end

    it "Should have the correct number of devices" do
      @plugin.run
      expect(@plugin[:zpools][:rpool][:devices].keys.size).to match(2)
      expect(@plugin[:zpools][:tank][:devices].keys.size).to match(12)
    end
  end

  describe "On OmniOS_151006" do
    before(:each) do
      @zpool_out = <<-EOZO
rpool   109G    66.2G   42.8G   60%     1.00x   ONLINE  -
tank    130T    4.91M   130T    0%      1.00x   ONLINE  -
EOZO
      @plugin.stub(:shell_out)
        .with("zpool list -H -o name,size,alloc,free,cap,dedup,health,version")
        .and_return(mock_shell_out(0,@zpool_out,""))
    end

    it "Won't have a version number" do
      @plugin.run
      expect(@plugin[:zpools][:rpool][:zpool_version]).to match("-")
      expect(@plugin[:zpools][:tank][:zpool_version]).to match("-")
    end

  end

  describe "On Solaris_11.1" do
    before(:each) do
      @zpool_out = <<-EOZO
rpool   109G    66.2G   42.8G   60%     1.00x   ONLINE  34
tank    130T    4.91M   130T    0%      1.00x   ONLINE  34
EOZO
      @plugin.stub(:shell_out)
        .with("zpool list -H -o name,size,alloc,free,cap,dedup,health,version")
        .and_return(mock_shell_out(0,@zpool_out,""))
    end

    it "Should have a version number" do
      @plugin.run
      expect(@plugin[:zpools][:rpool][:zpool_version]).to match("34")
      expect(@plugin[:zpools][:tank][:zpool_version]).to match("34")
    end

  end
end
