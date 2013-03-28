require 'spec_helper'


describe Ohai::System, "plugin joyent" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai.stub!(:require_plugin).and_return(true)
    #@ohai[:platform] = "smartos"
  end

  describe "without joyent" do
    before(:each) do
      @ohai[:platform] = "otheros"
    end

    it "should NOT create joyent" do
      @ohai._require_plugin("joyent")
      @ohai[:joyent].should be_nil
    end
  end

  describe "with joyent" do
    before(:each) do
      @ohai[:platform] = "smartos"
    end

    it "should create joyent" do
      @ohai._require_plugin("joyent")
      @ohai[:joyent].should_not be_nil
    end

    describe "under global zone" do
      before(:each) do
        @status = 0
        @stdout = "global\n"
        @stderr = ""
        @ohai.stub!(:run_command).with(:no_status_check => true, :command => "/usr/bin/zonename").and_return([@status, @stdout, @stderr])
        @ohai._require_plugin("joyent")
      end

      it "should ditect global zone" do
        @ohai[:joyent][:sm_uuid].should == "global"
      end

      it "should NOT create sm_id" do
        @ohai[:joyent][:sm_id].should be_nil
      end
    end

    describe "under smartmachine" do
      before(:each) do
        # stub zonename
        status = 0
        stdout = "xxxxx-xxxxx-xxxxx\n"
        stderr = ""
        @ohai.stub!(:run_command).with(:no_status_check => true, :command => "/usr/bin/zonename").and_return([status, stdout, stderr])

        #stub zoneadm
        status = 0
        stdout = "99\n"
        stderr = ""
        @ohai.stub!(:run_command).with(:no_status_check => true, :command => "/usr/sbin/zoneadm list -p | awk -F: '{ print $1 }'").and_return([status, stdout, stderr])
      end

      it "should retrive zone uuid" do
        @ohai._require_plugin("joyent")
        @ohai[:joyent][:sm_uuid].should == "xxxxx-xxxxx-xxxxx"
      end

      it "should create sm_id" do
        @ohai._require_plugin("joyent")
        @ohai[:joyent][:sm_id].should == "99"
      end

#       it "should retrive pkgsrc" do
#         # file stub /opt/local/etc/pkg_install.conf
#         file = mock
#         ::File.stub!(:read).with("/opt/local/etc/pkg_install.conf").and_return("PKG_PATH=http://pkgsrc.joyent.com/packages/SmartOS/2012Q4/x86_64/All\n")
# 
#         @ohai._require_plugin("joyent")
#         @ohai[:joyent][:sm_pkgsrc].should == "http://pkgsrc.joyent.com/packages/SmartOS/2012Q4/x86_64/All"
#       end
    end
  end
end

