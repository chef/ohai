
# Author:: Doug MacEachern <dougm@vmware.com>
# Copyright:: Copyright (c) 2010 VMware, Inc.
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

require_relative "../../spec_helper.rb"

C_GCC = <<EOF
Using built-in specs.
COLLECT_GCC=gcc
COLLECT_LTO_WRAPPER=/usr/lib/gcc/x86_64-linux-gnu/5/lto-wrapper
Target: x86_64-linux-gnu
Configured with: ../src/configure -v --with-pkgversion='Ubuntu 5.4.0-6ubuntu1~16.04.4' --with-bugurl=file:///usr/share/doc/gcc-5/README.Bugs --enable-languages=c,ada,c++,java,go,d,fortran,objc,obj-c++ --prefix=/usr --program-suffix=-5 --enable-shared --enable-linker-build-id --libexecdir=/usr/lib --without-included-gettext --enable-threads=posix --libdir=/usr/lib --enable-nls --with-sysroot=/ --enable-clocale=gnu --enable-libstdcxx-debug --enable-libstdcxx-time=yes --with-default-libstdcxx-abi=new --enable-gnu-unique-object --disable-vtable-verify --enable-libmpx --enable-plugin --with-system-zlib --disable-browser-plugin --enable-java-awt=gtk --enable-gtk-cairo --with-java-home=/usr/lib/jvm/java-1.5.0-gcj-5-amd64/jre --enable-java-home --with-jvm-root-dir=/usr/lib/jvm/java-1.5.0-gcj-5-amd64 --with-jvm-jar-dir=/usr/lib/jvm-exports/java-1.5.0-gcj-5-amd64 --with-arch-directory=amd64 --with-ecj-jar=/usr/share/java/eclipse-ecj.jar --enable-objc-gc --enable-multiarch --disable-werror --with-arch-32=i686 --with-abi=m64 --with-multilib-list=m32,m64,mx32 --enable-multilib --with-tune=generic --enable-checking=release --build=x86_64-linux-gnu --host=x86_64-linux-gnu --target=x86_64-linux-gnu
Thread model: posix
gcc version 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.4)
EOF

C_GLIBC = <<EOF
GNU C Library stable release version 2.5, by Roland McGrath et al.
Copyright (C) 2006 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.
Compiled by GNU CC version 4.1.2 20080704 (Red Hat 4.1.2-44).
Compiled on a Linux 2.6.9 system on 2009-09-02.
Available extensions:
  The C stubs add-on version 2.1.2.
  crypt add-on version 2.1 by Michael Glad and others
  GNU Libidn by Simon Josefsson
  GNU libio by Per Bothner
  NIS(YP)/NIS+ NSS modules 0.19 by Thorsten Kukuk
  Native POSIX Threads Library by Ulrich Drepper et al
  BIND-8.2.3-T5B
  RT using linux kernel aio
Thread-local storage support included.
For bug reporting instructions, please see:
<http://www.gnu.org/software/libc/bugs.html>.
EOF

C_CL = <<EOF
Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 14.00.50727.762 for 80x86
Copyright (C) Microsoft Corporation.  All rights reserved.
EOF

C_VS = <<EOF

Microsoft (R) Visual Studio Version 8.0.50727.762.
Copyright (C) Microsoft Corp 1984-2005. All rights reserved.
EOF

C_XLC = <<EOF
IBM XL C/C++ Enterprise Edition for AIX, V9.0
Version: 09.00.0000.0000
EOF

C_SUN = <<EOF
cc: Sun C 5.8 Patch 121016-06 2007/08/01
EOF

C_HPUX = <<EOF
/opt/ansic/bin/cc:
        $Revision: 92453-07 linker linker crt0.o B.11.47 051104 $
        LINT B.11.11.16 CXREF B.11.11.16
        HP92453-01 B.11.11.16 HP C Compiler
         $ PATCH/11.00:PHCO_27774  Oct  3 2002 09:45:59 $
EOF

describe Ohai::System, "plugin c" do

  let(:plugin) { get_plugin("c") }

  before(:each) do

    plugin[:languages] = Mash.new
    #gcc
    allow(plugin).to receive(:shell_out).with("gcc -v").and_return(mock_shell_out(0, "", C_GCC))
  end

  context "on AIX" do
    before(:each) do
      allow(plugin).to receive(:collect_os).and_return(:aix)
      allow(plugin).to receive(:shell_out).with("xlc -qversion").and_return(mock_shell_out(0, C_XLC, ""))
    end

    #ibm xlc
    it "gets the xlc version from running xlc -qversion" do
      expect(plugin).to receive(:shell_out).with("xlc -qversion").and_return(mock_shell_out(0, C_XLC, ""))
      plugin.run
    end

    it "sets languages[:c][:xlc][:version]" do
      plugin.run
      expect(plugin.languages[:c][:xlc][:version]).to eql("9.0")
    end

    it "sets languages[:c][:xlc][:description]" do
      plugin.run
      expect(plugin.languages[:c][:xlc][:description]).to eql("IBM XL C/C++ Enterprise Edition for AIX, V9.0")
    end

    it "does not set the languages[:c][:xlc] tree up if xlc command exits nonzero" do
      allow(plugin).to receive(:shell_out).with("xlc -qversion").and_return(mock_shell_out(1, "", ""))
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:xlc)
    end

    it "does not set the languages[:c][:xlc] tree up if xlc command fails" do
      allow(plugin).to receive(:shell_out).with("xlc -qversion").and_raise(Ohai::Exceptions::Exec)
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:xlc)
      expect(plugin[:languages][:c]).not_to be_empty # expect other attributes
    end

    it "sets the languages[:c][:xlc] tree up if xlc exit status is 249" do
      allow(plugin).to receive(:shell_out).with("xlc -qversion").and_return(mock_shell_out(63744, "", ""))
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:xlc)
    end

  end

  context "on HPUX" do
    before(:each) do
      allow(plugin).to receive(:collect_os).and_return(:hpux)
      allow(plugin).to receive(:shell_out).with("what /opt/ansic/bin/cc").and_return(mock_shell_out(0, C_HPUX, ""))
    end

    #hpux cc
    it "gets the cc version from running what cc" do
      expect(plugin).to receive(:shell_out).with("what /opt/ansic/bin/cc").and_return(mock_shell_out(0, C_HPUX, ""))
      plugin.run
    end

    it "sets languages[:c][:hpcc][:version]" do
      plugin.run
      expect(plugin.languages[:c][:hpcc][:version]).to eql("B.11.11.16")
    end

    it "sets languages[:c][:hpcc][:description]" do
      plugin.run
      expect(plugin.languages[:c][:hpcc][:description]).to eql("HP92453-01 B.11.11.16 HP C Compiler")
    end

    it "does not set the languages[:c][:hpcc] tree up if cc command exits nonzero" do
      allow(plugin).to receive(:shell_out).with("what /opt/ansic/bin/cc").and_return(mock_shell_out(1, "", ""))
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:hpcc)
    end

    it "does not set the languages[:c][:hpcc] tree up if cc command fails" do
      allow(plugin).to receive(:shell_out).with("what /opt/ansic/bin/cc").and_raise(Ohai::Exceptions::Exec)
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:hpcc)
      expect(plugin[:languages][:c]).not_to be_empty # expect other attributes
    end
  end

  context "on Darwin" do
    before(:each) do
      allow(plugin).to receive(:shell_out).with("/usr/bin/xcode-select -p").and_return(mock_shell_out(0, "", ""))
      allow(plugin).to receive(:collect_os).and_return(:darwin)
    end

    it "shells out to see if xcode is installed" do
      expect(plugin).to receive(:shell_out).with("/usr/bin/xcode-select -p")
      plugin.run
    end

    it "doesnt shellout to gcc if xcode isn't installed" do
      allow(plugin).to receive(:shell_out).with("/usr/bin/xcode-select -p").and_return(mock_shell_out(1, "", ""))
      expect(plugin).not_to receive(:shell_out).with("gcc -v")
      plugin.run
    end

  end

  context "on Windows" do
    before(:each) do
      allow(plugin).to receive(:collect_os).and_return(:windows)
      allow(plugin).to receive(:shell_out).with("cl /\?").and_return(mock_shell_out(0, "", C_CL))
      allow(plugin).to receive(:shell_out).with("devenv.com /\?").and_return(mock_shell_out(0, C_VS, ""))
    end

    #ms cl
    it "gets the cl version from running cl /?" do
      expect(plugin).to receive(:shell_out).with("cl /\?")
      plugin.run
    end

    it "sets languages[:c][:cl][:version]" do
      plugin.run
      expect(plugin.languages[:c][:cl][:version]).to eql("14.00.50727.762")
    end

    it "sets languages[:c][:cl][:description]" do
      plugin.run
      expect(plugin.languages[:c][:cl][:description]).to eql("Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 14.00.50727.762 for 80x86")
    end

    it "does not set the languages[:c][:cl] tree up if cl command exits nonzero" do
      allow(plugin).to receive(:shell_out).with("cl /\?").and_return(mock_shell_out(1, "", ""))
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:cl)
    end

    it "does not set the languages[:c][:cl] tree up if cl command fails" do
      allow(plugin).to receive(:shell_out).with("cl /\?").and_raise(Ohai::Exceptions::Exec)
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:cl)
      expect(plugin[:languages][:c]).not_to be_empty # expect other attributes
    end

    #ms vs
    it "gets the vs version from running devenv.com /?" do
      expect(plugin).to receive(:shell_out).with("devenv.com /\?").and_return(mock_shell_out(0, C_VS, ""))
      plugin.run
    end

    it "sets languages[:c][:vs][:version]" do
      plugin.run
      expect(plugin.languages[:c][:vs][:version]).to eql("8.0.50727.762")
    end

    it "sets languages[:c][:vs][:description]" do
      plugin.run
      expect(plugin.languages[:c][:vs][:description]).to eql("Microsoft (R) Visual Studio Version 8.0.50727.762.")
    end

    it "does not set the languages[:c][:vs] tree up if devenv command exits nonzero" do
      allow(plugin).to receive(:shell_out).with("devenv.com /\?").and_return(mock_shell_out(1, "", ""))
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:vs)
    end

    it "does not set the languages[:c][:vs] tree up if devenv command fails" do
      allow(plugin).to receive(:shell_out).with("devenv.com /\?").and_raise(Ohai::Exceptions::Exec)
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:vs)
      expect(plugin[:languages][:c]).not_to be_empty # expect other attributes
    end
  end

  context "on Linux" do
    before(:each) do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      # glibc
      allow(plugin).to receive(:shell_out).with("/lib/libc.so.6").and_return(mock_shell_out(0, C_GLIBC, ""))
      allow(plugin).to receive(:shell_out).with("/lib64/libc.so.6").and_return(mock_shell_out(0, C_GLIBC, ""))
      #sun pro
      allow(plugin).to receive(:shell_out).with("cc -V -flags").and_return(mock_shell_out(0, "", C_SUN))
    end

    #gcc
    it "gets the gcc version from running gcc -v" do
      expect(plugin).to receive(:shell_out).with("gcc -v")
      plugin.run
    end

    it "sets languages[:c][:gcc][:version]" do
      plugin.run
      expect(plugin.languages[:c][:gcc][:version]).to eql("5.4.0")
    end

    it "sets languages[:c][:gcc][:description]" do
      plugin.run
      expect(plugin.languages[:c][:gcc][:description]).to eql("gcc version 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.4)")
    end

    it "sets languages[:c][:gcc][:configured_with]" do
      plugin.run
      expect(plugin.languages[:c][:gcc][:configured_with]).to eql("../src/configure -v --with-pkgversion='Ubuntu 5.4.0-6ubuntu1~16.04.4' --with-bugurl=file:///usr/share/doc/gcc-5/README.Bugs --enable-languages=c,ada,c++,java,go,d,fortran,objc,obj-c++ --prefix=/usr --program-suffix=-5 --enable-shared --enable-linker-build-id --libexecdir=/usr/lib --without-included-gettext --enable-threads=posix --libdir=/usr/lib --enable-nls --with-sysroot=/ --enable-clocale=gnu --enable-libstdcxx-debug --enable-libstdcxx-time=yes --with-default-libstdcxx-abi=new --enable-gnu-unique-object --disable-vtable-verify --enable-libmpx --enable-plugin --with-system-zlib --disable-browser-plugin --enable-java-awt=gtk --enable-gtk-cairo --with-java-home=/usr/lib/jvm/java-1.5.0-gcj-5-amd64/jre --enable-java-home --with-jvm-root-dir=/usr/lib/jvm/java-1.5.0-gcj-5-amd64 --with-jvm-jar-dir=/usr/lib/jvm-exports/java-1.5.0-gcj-5-amd64 --with-arch-directory=amd64 --with-ecj-jar=/usr/share/java/eclipse-ecj.jar --enable-objc-gc --enable-multiarch --disable-werror --with-arch-32=i686 --with-abi=m64 --with-multilib-list=m32,m64,mx32 --enable-multilib --with-tune=generic --enable-checking=release --build=x86_64-linux-gnu --host=x86_64-linux-gnu --target=x86_64-linux-gnu")
    end

    it "sets languages[:c][:gcc][:target]" do
      plugin.run
      expect(plugin.languages[:c][:gcc][:target]).to eql("x86_64-linux-gnu")
    end

    it "sets languages[:c][:gcc][:thread_model]" do
      plugin.run
      expect(plugin.languages[:c][:gcc][:thread_model]).to eql("posix")
    end

    it "does not set the languages[:c][:gcc] tree up if gcc command exits nonzero" do
      allow(plugin).to receive(:shell_out).with("gcc -v").and_return(mock_shell_out(1, "", ""))
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:gcc)
    end

    it "does not set the languages[:c][:gcc] tree up if gcc command fails" do
      allow(plugin).to receive(:shell_out).with("gcc -v").and_raise(Ohai::Exceptions::Exec)
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:gcc)
      expect(plugin[:languages][:c]).not_to be_empty # expect other attributes
    end

    #glibc
    it "gets the glibc x.x.x version from running /lib/libc.so.6" do
      expect(plugin).to receive(:shell_out).with("/lib/libc.so.6")
      plugin.run
    end

    it "sets languages[:c][:glibc][:version]", :unix_only do
      plugin.run
      expect(plugin.languages[:c][:glibc][:version]).to eql("2.5")
    end

    it "sets languages[:c][:glibc][:description]" do
      plugin.run
      expect(plugin.languages[:c][:glibc][:description]).to eql("GNU C Library stable release version 2.5, by Roland McGrath et al.")
    end

    it "does not set the languages[:c][:glibc] tree up if glibc exits nonzero" do
      allow(plugin).to receive(:shell_out).with("/lib/libc.so.6").and_return(mock_shell_out(1, "", ""))
      allow(plugin).to receive(:shell_out).with("/lib64/libc.so.6").and_return(mock_shell_out(1, "", ""))
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:glibc)
    end

    it "does not set the languages[:c][:glibc] tree up if glibc fails" do
      allow(plugin).to receive(:shell_out).with("/lib/libc.so.6").and_raise(Ohai::Exceptions::Exec)
      allow(plugin).to receive(:shell_out).with("/lib64/libc.so.6").and_raise(Ohai::Exceptions::Exec)
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:glibc)
      expect(plugin[:languages][:c]).not_to be_empty # expect other attributes
    end

    it "gets the glibc x.x version from running /lib/libc.so.6" do
      allow(plugin).to receive(:shell_out).with("/lib/libc.so.6").and_return(mock_shell_out(0, C_GLIBC, ""))
      expect(plugin).to receive(:shell_out).with("/lib/libc.so.6")
      plugin.run
      expect(plugin.languages[:c][:glibc][:version]).to eql("2.5")
    end

    #sun pro
    it "gets the cc version from running cc -V -flags" do
      expect(plugin).to receive(:shell_out).with("cc -V -flags").and_return(mock_shell_out(0, "", C_SUN))
      plugin.run
    end

    it "sets languages[:c][:sunpro][:version]" do
      plugin.run
      expect(plugin.languages[:c][:sunpro][:version]).to eql("5.8")
    end

    it "sets languages[:c][:sunpro][:description]" do
      plugin.run
      expect(plugin.languages[:c][:sunpro][:description]).to eql("cc: Sun C 5.8 Patch 121016-06 2007/08/01")
    end

    it "does not set the languages[:c][:sunpro] tree up if cc command exits nonzero" do
      allow(plugin).to receive(:shell_out).with("cc -V -flags").and_return(mock_shell_out(1, "", ""))
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:sunpro)
    end

    it "does not set the languages[:c][:sunpro] tree up if cc command fails" do
      allow(plugin).to receive(:shell_out).with("cc -V -flags").and_raise(Ohai::Exceptions::Exec)
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:sunpro)
      expect(plugin[:languages][:c]).not_to be_empty # expect other attributes
    end

    it "does not set the languages[:c][:sunpro] tree if the corresponding cc command fails on linux" do
      fedora_error_message = "cc: error trying to exec 'i686-redhat-linux-gcc--flags': execvp: No such file or directory"

      allow(plugin).to receive(:shell_out).with("cc -V -flags").and_return(mock_shell_out(0, "", fedora_error_message))
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:sunpro)
    end

    it "does not set the languages[:c][:sunpro] tree if the corresponding cc command fails on hpux" do
      hpux_error_message = "cc: warning 901: unknown option: `-flags': use +help for online documentation.\ncc: HP C/aC++ B3910B A.06.25 [Nov 30 2009]"
      allow(plugin).to receive(:shell_out).with("cc -V -flags").and_return(mock_shell_out(0, "", hpux_error_message))
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:sunpro)
    end
  end
end
