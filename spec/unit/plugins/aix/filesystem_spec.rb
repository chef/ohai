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

describe Ohai::System, "AIX filesystem plugin" do
  before(:each) do
    @df_P = <<-DF_P
Filesystem    512-blocks      Used Available Capacity Mounted on
/dev/hd4          786432    495632    290800      64% /
/dev/hd2        10485760   8743200   1742560      84% /usr
/dev/hd9var      2621440   1152952   1468488      44% /var
/dev/hd3         2621440    541928   2079512      21% /tmp
/dev/hd1         8650752   6098080   2552672      71% /home
/dev/hd11admin     262144       760    261384       1% /admin
/proc                  -         -         -       -  /proc
/dev/hd10opt     3407872   1744384   1663488      52% /opt
192.168.1.11:/stage/middleware  314572800 177025952 137546848      57% /stage/middleware
DF_P

    @mount = <<-MOUNT
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

    @ohai = Ohai::System.new
    @ohai.stub(:require_plugin).and_return(true)
    @ohai[:filesystem] = Mash.new
    @ohai.stub(:popen4).with("df -P").and_yield(nil, StringIO.new, StringIO.new(@df_P), nil)
    @ohai.stub(:popen4).with("mount").and_yield(nil, StringIO.new, StringIO.new(@mount), nil)
    @ohai._require_plugin("aix::filesystem")
  end

  describe "df -P" do

    it "returns the filesystem block size" do
      @ohai[:filesystem]["/dev/hd4"]['kb_size'].should == "786432"
    end

    it "returns the filesystem used space in kb" do
      @ohai[:filesystem]["/dev/hd4"]['kb_used'].should == "495632"
    end

    it "returns the filesystem available space in kb" do
      @ohai[:filesystem]["/dev/hd4"]['kb_available'].should == "290800"
    end

    it "returns the filesystem capacity in percentage" do
      @ohai[:filesystem]["/dev/hd4"]['percent_used'].should == "64%"
    end

    it "returns the filesystem mounted location" do
      @ohai[:filesystem]["/dev/hd4"]['mount'].should == "/"
    end
  end

  describe "mount" do

    it "returns the filesystem mount location" do
      @ohai[:filesystem]["/dev/hd4"]['mount'].should == "/"
    end

    it "returns the filesystem type" do
      @ohai[:filesystem]["/dev/hd4"]['fs_type'].should == "jfs2"
    end

    it "returns the filesystem mount options" do
      @ohai[:filesystem]["/dev/hd4"]['mount_options'].should == "rw,log=/dev/hd8"
    end

    # For entries like 192.168.1.11 /stage/middleware /stage/middleware nfs3   Jul 17 13:24 ro,bg,hard,intr,sec=sys
    context "having node values" do
      before do
        @ohai.stub(:popen4).with("mount").and_yield(nil, StringIO.new, StringIO.new("192.168.1.11 /stage/middleware /stage/middleware nfs3   Jul 17 13:24 ro,bg,hard,intr,sec=sys"), nil)
      end
      it "returns the filesystem mount location" do
        @ohai[:filesystem]["192.168.1.11:/stage/middleware"]['mount'].should == "/stage/middleware"
      end

      it "returns the filesystem type" do
        @ohai[:filesystem]["192.168.1.11:/stage/middleware"]['fs_type'].should == "nfs3"
      end

      it "returns the filesystem mount options" do
        @ohai[:filesystem]["192.168.1.11:/stage/middleware"]['mount_options'].should == "ro,bg,hard,intr,sec=sys"
      end
    end
  end
end
