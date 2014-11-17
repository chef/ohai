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

    @plugin = get_plugin("aix/filesystem")
    allow(@plugin).to receive(:collect_os).and_return(:aix)
    @plugin[:filesystem] = Mash.new
    allow(@plugin).to receive(:shell_out).with("df -P").and_return(mock_shell_out(0, @df_P, nil))
    allow(@plugin).to receive(:shell_out).with("mount").and_return(mock_shell_out(0, @mount, nil))

    @plugin.run
  end

  describe "df -P" do

    it "returns the filesystem block size" do
      expect(@plugin[:filesystem]["/dev/hd4"]['kb_size']).to eq("786432")
    end

    it "returns the filesystem used space in kb" do
      expect(@plugin[:filesystem]["/dev/hd4"]['kb_used']).to eq("495632")
    end

    it "returns the filesystem available space in kb" do
      expect(@plugin[:filesystem]["/dev/hd4"]['kb_available']).to eq("290800")
    end

    it "returns the filesystem capacity in percentage" do
      expect(@plugin[:filesystem]["/dev/hd4"]['percent_used']).to eq("64%")
    end

    it "returns the filesystem mounted location" do
      expect(@plugin[:filesystem]["/dev/hd4"]['mount']).to eq("/")
    end
  end

  describe "mount" do

    it "returns the filesystem mount location" do
      expect(@plugin[:filesystem]["/dev/hd4"]['mount']).to eq("/")
    end

    it "returns the filesystem type" do
      expect(@plugin[:filesystem]["/dev/hd4"]['fs_type']).to eq("jfs2")
    end

    it "returns the filesystem mount options" do
      expect(@plugin[:filesystem]["/dev/hd4"]['mount_options']).to eq("rw,log=/dev/hd8")
    end

    # For entries like 192.168.1.11 /stage/middleware /stage/middleware nfs3   Jul 17 13:24 ro,bg,hard,intr,sec=sys
    context "having node values" do
      before do
        allow(@plugin).to receive(:shell_out).with("df -P").and_return(mock_shell_out(0, "192.168.1.11 /stage/middleware /stage/middleware nfs3   Jul 17 13:24 ro,bg,hard,intr,sec=sys", nil))
      end

      it "returns the filesystem mount location" do
        expect(@plugin[:filesystem]["192.168.1.11:/stage/middleware"]['mount']).to eq("/stage/middleware")
      end

      it "returns the filesystem type" do
        expect(@plugin[:filesystem]["192.168.1.11:/stage/middleware"]['fs_type']).to eq("nfs3")
      end

      it "returns the filesystem mount options" do
        expect(@plugin[:filesystem]["192.168.1.11:/stage/middleware"]['mount_options']).to eq("ro,bg,hard,intr,sec=sys")
      end
    end
  end
end
