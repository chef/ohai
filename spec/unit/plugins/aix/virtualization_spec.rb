#
# Author:: Julian C. Dunn (<jdunn@chef.iom>)
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

describe Ohai::System, "AIX virtualization plugin" do

  context "inside an LPAR" do

    let(:plugin) do
      p = get_plugin("aix/virtualization")
      allow(p).to receive(:collect_os).and_return(:aix)
      allow(p).to receive(:shell_out).with("uname -L").and_return(mock_shell_out(0, "29 l273pp027", nil))
      allow(p).to receive(:shell_out).with("uname -W").and_return(mock_shell_out(0, "0", nil))
      allow(p).to receive(:shell_out).with("lswpar -L").and_return(mock_shell_out(0, @lswpar_l, nil))
      p
    end

    before(:each) do
      @lswpar_l = <<-LSWPAR_L
=================================================================
applejack-541ba3 - Active
=================================================================
GENERAL
Type:                    S
RootVG WPAR:             no
Owner:                   root
Hostname:                applejack-pony-541ba3.ponyville.com
WPAR-Specific Routing:   yes
Virtual IP WPAR:
Directory:               /wpars/applejack-541ba3
Start/Stop Script:
Auto:                    no
Private /usr:            yes
Checkpointable:          no
Application:
UUID:                    541ba314-c7ca-4f67-bc6e-a10d5eaa8541

NETWORK
Interface     Address(6)        Mask/Prefix       Broadcast
-----------------------------------------------------------------
en0           192.168.0.231     255.255.252.0     192.168.0.255
lo0           127.0.0.1         255.0.0.0         127.255.255.255

USER-SPECIFIED ROUTES
Type    Destination          Gateway           Interface
-----------------------------------------------------------------
        default              192.168.0.1        en0

FILE SYSTEMS
MountPoint               Device           Vfs     Nodename   Options
-----------------------------------------------------------------
/wpars/sink-thinker-5... /dev/fslv00      jfs2               log=NULL
/wpars/sink-thinker-5... /dev/fslv01      jfs2               log=NULL
/wpars/sink-thinker-5... /dev/fslv02      jfs2               log=NULL
/wpars/sink-thinker-5... /proc            namefs             rw
/wpars/sink-thinker-5... /dev/fslv03      jfs2               log=NULL
/wpars/sink-thinker-5... /dev/fslv04      jfs2               log=NULL
/wpars/sink-thinker-5... /dev/fslv05      jfs2               log=NULL

RESOURCE CONTROLS
Active:                             yes
Resource Set:
CPU Shares:                         unlimited
CPU Limits:                         0%-100%,100%
Memory Shares:                      unlimited
Memory Limits:                      0%-100%,100%
Per-Process Virtual Memory Limit:   unlimited
Total Virtual Memory Limit:         unlimited
Total Processes:                    unlimited
Total Threads:                      unlimited
Total PTYs:                         unlimited
Total Large Pages:                  unlimited
Max Message Queue IDs:              100%
Max Semaphore IDs:                  100%
Max Shared Memory IDs:              100%
Max Pinned Memory:                  100%

OPERATION
Operation:    none
Process ID:
Start Time:

SECURITY SETTINGS
Privileges:   PV_AU_,PV_AU_ADD,PV_AU_ADMIN,PV_AU_PROC,PV_AU_READ,
              PV_AU_WRITE,PV_AZ_ADMIN,PV_AZ_CHECK,PV_AZ_READ,PV_AZ_ROOT,
              PV_DAC_,PV_DAC_GID,PV_DAC_O,PV_DAC_R,PV_DAC_RID,PV_DAC_UID,
              PV_DAC_W,PV_DAC_X,PV_DEV_CONFIG,PV_DEV_QUERY,PV_FS_CHOWN,
              PV_FS_CHROOT,PV_FS_CNTL,PV_FS_LINKDIR,PV_FS_MKNOD,
              PV_FS_MOUNT,PV_FS_PDMODE,PV_FS_QUOTA,PV_KER_ACCT,
              PV_KER_CONF,PV_KER_DR,PV_KER_EWLM,PV_KER_EXTCONF,
              PV_KER_IPC,PV_KER_IPC_O,PV_KER_IPC_R,PV_KER_IPC_W,
              PV_KER_NFS,PV_KER_RAC,PV_KER_RAS_ERR,PV_KER_REBOOT,
              PV_NET_PORT,PV_PROC_CKPT,PV_PROC_CORE,PV_PROC_CRED,
              PV_PROC_ENV,PV_PROC_PRIO,PV_PROC_PDMODE,PV_PROC_RAC,
              PV_PROC_RTCLK,PV_PROC_SIG,PV_PROC_TIMER,PV_PROC_VARS,
              PV_PROC_PRIV,PV_SU_UID,PV_TCB,PV_TP,PV_TP_SET,PV_MIC,
              PV_MIC_CL,PV_LAB_,PV_LAB_CL,PV_LAB_CLTL,PV_LAB_LEF,
              PV_LAB_SLDG,PV_LAB_SLDG_STR,PV_LAB_SL_FILE,PV_LAB_SL_PROC,
              PV_LAB_SL_SELF,PV_LAB_SLUG,PV_LAB_SLUG_STR,PV_LAB_TL,
              PV_MAC_,PV_MAC_CL,PV_MAC_R,PV_MAC_R_CL,PV_MAC_R_STR,
              PV_MAC_R_PROC,PV_MAC_W,PV_MAC_W_CL,PV_MAC_W_DN,PV_MAC_W_UP,
              PV_MAC_W_PROC,PV_MAC_OVRRD,PV_KER_SECCONFIG,
              PV_PROBEVUE_TRC_USER,PV_PROBEVUE_TRC_USER_SELF,PV_KER_LVM

DEVICE EXPORTS
Name               Type     Virtual Device     RootVG   Status
-----------------------------------------------------------------
/dev/null          pseudo                               EXPORTED
/dev/tty           pseudo                               EXPORTED
/dev/console       pseudo                               EXPORTED
/dev/zero          pseudo                               EXPORTED
/dev/clone         pseudo                               EXPORTED
/dev/sad           clone                                EXPORTED
/dev/xti/tcp       clone                                EXPORTED
/dev/xti/tcp6      clone                                EXPORTED
/dev/xti/udp       clone                                EXPORTED
/dev/xti/udp6      clone                                EXPORTED
/dev/xti/unixdg    clone                                EXPORTED
/dev/xti/unixst    clone                                EXPORTED
/dev/error         pseudo                               EXPORTED
/dev/errorctl      pseudo                               EXPORTED
/dev/audit         pseudo                               EXPORTED
/dev/nvram         pseudo                               EXPORTED

=================================================================
fluttershy-5c969f - Active
=================================================================
GENERAL
Type:                    S
RootVG WPAR:             no
Owner:                   root
Hostname:                fluttershy-pony-5c969f.ponyville.com
WPAR-Specific Routing:   yes
Virtual IP WPAR:
Directory:               /wpars/fluttershy-5c969f
Start/Stop Script:
Auto:                    no
Private /usr:            yes
Checkpointable:          no
Application:
UUID:                    6f1fd4be-8be5-4627-8ec0-3a8739cbd9e2

NETWORK
Interface     Address(6)        Mask/Prefix       Broadcast
-----------------------------------------------------------------
en0           192.168.0.18      255.255.252.0     192.168.0.255
lo0           127.0.0.1         255.0.0.0         127.255.255.255

USER-SPECIFIED ROUTES
Type    Destination          Gateway           Interface
-----------------------------------------------------------------
        default              192.168.0.1        en0

FILE SYSTEMS
MountPoint               Device           Vfs     Nodename   Options
-----------------------------------------------------------------
/wpars/toolchain-test... /dev/fslv07      jfs2               log=NULL
/wpars/toolchain-test... /dev/fslv08      jfs2               log=NULL
/wpars/toolchain-test... /dev/fslv09      jfs2               log=NULL
/wpars/toolchain-test... /proc            namefs             rw
/wpars/toolchain-test... /dev/fslv10      jfs2               log=NULL
/wpars/toolchain-test... /dev/fslv11      jfs2               log=NULL
/wpars/toolchain-test... /dev/fslv12      jfs2               log=NULL

RESOURCE CONTROLS
Active:                             yes
Resource Set:
CPU Shares:                         unlimited
CPU Limits:                         0%-100%,100%
Memory Shares:                      unlimited
Memory Limits:                      0%-100%,100%
Per-Process Virtual Memory Limit:   unlimited
Total Virtual Memory Limit:         unlimited
Total Processes:                    unlimited
Total Threads:                      unlimited
Total PTYs:                         unlimited
Total Large Pages:                  unlimited
Max Message Queue IDs:              100%
Max Semaphore IDs:                  100%
Max Shared Memory IDs:              100%
Max Pinned Memory:                  100%

OPERATION
Operation:    none
Process ID:
Start Time:

SECURITY SETTINGS
Privileges:   PV_AU_,PV_AU_ADD,PV_AU_ADMIN,PV_AU_PROC,PV_AU_READ,
              PV_AU_WRITE,PV_AZ_ADMIN,PV_AZ_CHECK,PV_AZ_READ,PV_AZ_ROOT,
              PV_DAC_,PV_DAC_GID,PV_DAC_O,PV_DAC_R,PV_DAC_RID,PV_DAC_UID,
              PV_DAC_W,PV_DAC_X,PV_DEV_CONFIG,PV_DEV_QUERY,PV_FS_CHOWN,
              PV_FS_CHROOT,PV_FS_CNTL,PV_FS_LINKDIR,PV_FS_MKNOD,
              PV_FS_MOUNT,PV_FS_PDMODE,PV_FS_QUOTA,PV_KER_ACCT,
              PV_KER_CONF,PV_KER_DR,PV_KER_EWLM,PV_KER_EXTCONF,
              PV_KER_IPC,PV_KER_IPC_O,PV_KER_IPC_R,PV_KER_IPC_W,
              PV_KER_NFS,PV_KER_RAC,PV_KER_RAS_ERR,PV_KER_REBOOT,
              PV_NET_PORT,PV_PROC_CKPT,PV_PROC_CORE,PV_PROC_CRED,
              PV_PROC_ENV,PV_PROC_PRIO,PV_PROC_PDMODE,PV_PROC_RAC,
              PV_PROC_RTCLK,PV_PROC_SIG,PV_PROC_TIMER,PV_PROC_VARS,
              PV_PROC_PRIV,PV_SU_UID,PV_TCB,PV_TP,PV_TP_SET,PV_MIC,
              PV_MIC_CL,PV_LAB_,PV_LAB_CL,PV_LAB_CLTL,PV_LAB_LEF,
              PV_LAB_SLDG,PV_LAB_SLDG_STR,PV_LAB_SL_FILE,PV_LAB_SL_PROC,
              PV_LAB_SL_SELF,PV_LAB_SLUG,PV_LAB_SLUG_STR,PV_LAB_TL,
              PV_MAC_,PV_MAC_CL,PV_MAC_R,PV_MAC_R_CL,PV_MAC_R_STR,
              PV_MAC_R_PROC,PV_MAC_W,PV_MAC_W_CL,PV_MAC_W_DN,PV_MAC_W_UP,
              PV_MAC_W_PROC,PV_MAC_OVRRD,PV_KER_SECCONFIG,
              PV_PROBEVUE_TRC_USER,PV_PROBEVUE_TRC_USER_SELF,PV_KER_LVM

DEVICE EXPORTS
Name               Type     Virtual Device     RootVG   Status
-----------------------------------------------------------------
/dev/null          pseudo                               EXPORTED
/dev/tty           pseudo                               EXPORTED
/dev/console       pseudo                               EXPORTED
/dev/zero          pseudo                               EXPORTED
/dev/clone         pseudo                               EXPORTED
/dev/sad           clone                                EXPORTED
/dev/xti/tcp       clone                                EXPORTED
/dev/xti/tcp6      clone                                EXPORTED
/dev/xti/udp       clone                                EXPORTED
/dev/xti/udp6      clone                                EXPORTED
/dev/xti/unixdg    clone                                EXPORTED
/dev/xti/unixst    clone                                EXPORTED
/dev/error         pseudo                               EXPORTED
/dev/errorctl      pseudo                               EXPORTED
/dev/audit         pseudo                               EXPORTED
/dev/nvram         pseudo                               EXPORTED


LSWPAR_L

    end

    it "uname -L detects the LPAR number and name" do
      plugin.run
      expect(plugin[:virtualization][:lpar_no]).to eq("29")
      expect(plugin[:virtualization][:lpar_name]).to eq("l273pp027")
    end

    context "when WPARs exist on the LPAR" do
      before do
        plugin.run
      end

      let(:wpar1) do
        plugin[:virtualization][:wpars]["applejack-541ba3"]
      end

      let(:wpar2) do
        plugin[:virtualization][:wpars]["fluttershy-5c969f"]
      end

      it "detects all WPARs present (2)" do
        expect(plugin[:virtualization][:wpars].length).to eq(2)
      end

      context "when collecting WPAR info" do
        it 'finds the WPAR\'s hostname correctly' do
          expect(wpar1[:hostname]).to eq("applejack-pony-541ba3.ponyville.com")
          expect(wpar2[:hostname]).to eq("fluttershy-pony-5c969f.ponyville.com")
        end

        it 'finds the WPAR\'s IP correctly' do
          expect(wpar1[:address]).to eq("192.168.0.231")
          expect(wpar2[:address]).to eq("192.168.0.18")
        end

        it "parses device exports properly" do
          expect(wpar1["device exports"]["/dev/nvram"]["type"]).to eq("pseudo")
          expect(wpar1["device exports"]["/dev/nvram"]["status"]).to eq("EXPORTED")
        end
      end
    end

    context 'when WPARs don\'t exist on the LPAR' do
      before do
        allow(plugin).to receive(:shell_out).with("lswpar -L").and_return(mock_shell_out(0, "", nil))
        plugin.run
      end

      it "detects all WPARs present (0)" do
        expect(plugin[:virtualization][:wpars]).to be_nil
      end
    end
  end

  context "inside a WPAR" do
    let(:plugin) do
      p = get_plugin("aix/virtualization")
      allow(p).to receive(:collect_os).and_return(:aix)
      allow(p).to receive(:shell_out).with("uname -L").and_return(mock_shell_out(0, "43 l33t", nil))
      allow(p).to receive(:shell_out).with("uname -W").and_return(mock_shell_out(0, "42", nil))
      p.run
      p
    end

    it "uname -W detects the WPAR number" do
      expect(plugin[:virtualization][:wpar_no]).to eq("42")
    end
  end

end
