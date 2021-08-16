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

require "spec_helper"

C_GCC = <<~EOF.freeze
  Using built-in specs.
  COLLECT_GCC=gcc
  COLLECT_LTO_WRAPPER=/usr/lib/gcc/x86_64-linux-gnu/5/lto-wrapper
  Target: x86_64-linux-gnu
  Configured with: ../src/configure -v --with-pkgversion='Ubuntu 5.4.0-6ubuntu1~16.04.4' --with-bugurl=file:///usr/share/doc/gcc-5/README.Bugs --enable-languages=c,ada,c++,java,go,d,fortran,objc,obj-c++ --prefix=/usr --program-suffix=-5 --enable-shared --enable-linker-build-id --libexecdir=/usr/lib --without-included-gettext --enable-threads=posix --libdir=/usr/lib --enable-nls --with-sysroot=/ --enable-clocale=gnu --enable-libstdcxx-debug --enable-libstdcxx-time=yes --with-default-libstdcxx-abi=new --enable-gnu-unique-object --disable-vtable-verify --enable-libmpx --enable-plugin --with-system-zlib --disable-browser-plugin --enable-java-awt=gtk --enable-gtk-cairo --with-java-home=/usr/lib/jvm/java-1.5.0-gcj-5-amd64/jre --enable-java-home --with-jvm-root-dir=/usr/lib/jvm/java-1.5.0-gcj-5-amd64 --with-jvm-jar-dir=/usr/lib/jvm-exports/java-1.5.0-gcj-5-amd64 --with-arch-directory=amd64 --with-ecj-jar=/usr/share/java/eclipse-ecj.jar --enable-objc-gc --enable-multiarch --disable-werror --with-arch-32=i686 --with-abi=m64 --with-multilib-list=m32,m64,mx32 --enable-multilib --with-tune=generic --enable-checking=release --build=x86_64-linux-gnu --host=x86_64-linux-gnu --target=x86_64-linux-gnu
  Thread model: posix
  gcc version 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.4)
EOF

C_GLIBC = <<~EOF.freeze
  ldd (GNU libc) 2.17
  Copyright (C) 2012 Free Software Foundation, Inc.
  This is free software; see the source for copying conditions.  There is NO
  warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  Written by Roland McGrath and Ulrich Drepper.
EOF

C_CL = <<~EOF.freeze
  Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 14.00.50727.762 for 80x86
  Copyright (C) Microsoft Corporation.  All rights reserved.
EOF

C_VS = <<~EOF.freeze

  Microsoft (R) Visual Studio Version 8.0.50727.762.
  Copyright (C) Microsoft Corp 1984-2005. All rights reserved.
EOF

C_XLC = <<~EOF.freeze
  IBM XL C/C++ Enterprise Edition for AIX, V9.0
  Version: 09.00.0000.0000
EOF

C_XLC_NEWER = <<~EOF.freeze
  IBM XL C/C++ for AIX, V13.1.3 (5725-C72, 5765-J07)
  Version: 13.01.0003.0000
EOF

C_SUN = <<~EOF.freeze
  cc: Sun C 5.8 Patch 121016-06 2007/08/01
EOF

describe Ohai::System, "plugin c" do

  let(:plugin) { get_plugin("c") }

  before do

    plugin[:languages] = Mash.new
    # gcc
    allow(plugin).to receive(:shell_out).with("gcc -v").and_return(mock_shell_out(0, "", C_GCC))
  end

  context "when on AIX" do
    before do
      allow(plugin).to receive(:collect_os).and_return(:aix)
      allow(plugin).to receive(:shell_out).with("xlc -qversion").and_return(mock_shell_out(0, C_XLC, ""))
    end

    # ibm xlc
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

    it "properly parses 3 part version numbers in newer XLC releases" do
      expect(plugin).to receive(:shell_out).with("xlc -qversion").and_return(mock_shell_out(0, C_XLC_NEWER, ""))
      plugin.run
      expect(plugin.languages[:c][:xlc][:version]).to eql("13.1.3")
      expect(plugin.languages[:c][:xlc][:description]).to eql("IBM XL C/C++ for AIX, V13.1.3 (5725-C72, 5765-J07)")
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

  context "when on Darwin" do
    before do
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

  context "when on Windows" do
    before do
      allow(plugin).to receive(:collect_os).and_return(:windows)
      allow(plugin).to receive(:shell_out).with("cl /\?").and_return(mock_shell_out(0, "", C_CL))
      allow(plugin).to receive(:shell_out).with("devenv.com /\?").and_return(mock_shell_out(0, C_VS, ""))
    end

    # ms cl
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

    # ms vs
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

  context "when on Linux" do
    before do
      allow(plugin).to receive(:collect_os).and_return(:linux)
      # glibc
      allow(plugin).to receive(:shell_out).with("ldd --version").and_return(mock_shell_out(0, C_GLIBC, ""))
      # sun pro
      allow(plugin).to receive(:shell_out).with("cc -V -flags").and_return(mock_shell_out(0, "", C_SUN))
    end

    # gcc
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

    # glibc
    it "gets the glibc x.x.x version from running ldd" do
      expect(plugin).to receive(:shell_out).with("ldd --version")
      plugin.run
    end

    it "sets languages[:c][:glibc][:version]", :unix_only do
      plugin.run
      expect(plugin.languages[:c][:glibc][:version]).to eql("2.17")
    end

    it "sets languages[:c][:glibc][:description]" do
      plugin.run
      expect(plugin.languages[:c][:glibc][:description]).to eql("ldd (GNU libc) 2.17")
    end

    it "does not set the languages[:c][:glibc] tree up if glibc exits nonzero" do
      allow(plugin).to receive(:shell_out).with("ldd --version").and_return(mock_shell_out(1, "", ""))
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:glibc)
    end

    it "does not set the languages[:c][:glibc] tree up if glibc fails" do
      allow(plugin).to receive(:shell_out).with("ldd --version").and_raise(Ohai::Exceptions::Exec)
      plugin.run
      expect(plugin[:languages][:c]).not_to have_key(:glibc)
      expect(plugin[:languages][:c]).not_to be_empty # expect other attributes
    end

    it "gets the glibc x.x version from running ldd" do
      allow(plugin).to receive(:shell_out).with("ldd --version").and_return(mock_shell_out(0, C_GLIBC, ""))
      expect(plugin).to receive(:shell_out).with("ldd --version")
      plugin.run
      expect(plugin.languages[:c][:glibc][:version]).to eql("2.17")
    end

    # sun pro
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
  end
end
