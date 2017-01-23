#
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

Ohai.plugin(:C) do
  provides "languages/c"
  depends "languages"

  def collect(cmd, &block)
    so = shell_out(cmd)
    if so.exitstatus == 0
      yield(so)
    else
      Ohai::Log.debug("Plugin C: '#{cmd}' failed. Skipping data.")
    end
  rescue Ohai::Exceptions::Exec
    Ohai::Log.debug("Plugin C: '#{cmd}' binary could not be found. Skipping data.")
  end

  def xcode_installed?
    Ohai::Log.debug("Plugin C: Checking for Xcode Command Line Tools.")
    so = shell_out("/usr/bin/xcode-select -p")
    if so.exitstatus == 0
      Ohai::Log.debug("Plugin C: Xcode Command Line Tools found.")
      return true
    else
      Ohai::Log.debug("Plugin C: Xcode Command Line Tools not found.")
      return false
    end
  rescue Ohai::Exceptions::Exec
    Ohai::Log.debug("Plugin C: xcode-select binary could not be found. Skipping data.")
  end

  def collect_gcc
    # gcc
    # Sample output on os x:
    # Configured with: --prefix=/Applications/Xcode.app/Contents/Developer/usr --with-gxx-include-dir=/usr/include/c++/4.2.1
    # Apple LLVM version 7.3.0 (clang-703.0.29)
    # Target: x86_64-apple-darwin15.4.0
    # Thread model: posix
    # InstalledDir: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
    #
    #
    # Sample output on Linux:
    # Using built-in specs.
    # COLLECT_GCC=gcc
    # COLLECT_LTO_WRAPPER=/usr/lib/gcc/x86_64-linux-gnu/5/lto-wrapper
    # Target: x86_64-linux-gnu
    # Configured with: ../src/configure -v --with-pkgversion='Ubuntu 5.4.0-6ubuntu1~16.04.4' --with-bugurl=file:///usr/share/doc/gcc-5/README.Bugs --enable-languages=c,ada,c++,java,go,d,fortran,objc,obj-c++ --prefix=/usr --program-suffix=-5 --enable-shared --enable-linker-build-id --libexecdir=/usr/lib --without-included-gettext --enable-threads=posix --libdir=/usr/lib --enable-nls --with-sysroot=/ --enable-clocale=gnu --enable-libstdcxx-debug --enable-libstdcxx-time=yes --with-default-libstdcxx-abi=new --enable-gnu-unique-object --disable-vtable-verify --enable-libmpx --enable-plugin --with-system-zlib --disable-browser-plugin --enable-java-awt=gtk --enable-gtk-cairo --with-java-home=/usr/lib/jvm/java-1.5.0-gcj-5-amd64/jre --enable-java-home --with-jvm-root-dir=/usr/lib/jvm/java-1.5.0-gcj-5-amd64 --with-jvm-jar-dir=/usr/lib/jvm-exports/java-1.5.0-gcj-5-amd64 --with-arch-directory=amd64 --with-ecj-jar=/usr/share/java/eclipse-ecj.jar --enable-objc-gc --enable-multiarch --disable-werror --with-arch-32=i686 --with-abi=m64 --with-multilib-list=m32,m64,mx32 --enable-multilib --with-tune=generic --enable-checking=release --build=x86_64-linux-gnu --host=x86_64-linux-gnu --target=x86_64-linux-gnu
    # Thread model: posix
    # gcc version 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.4)
    gcc = Mash.new
    collect("gcc -v") do |so|
      so.stderr.each_line do |line|
        case line
        when /^(.*version\s(\S*).*)/
          gcc[:description] = $1
          gcc[:version] = $2
        when /^Target:\s(.*)/
          gcc[:target] = $1
        when /^Configured with:\s(.*)/
          gcc[:configured_with] = $1
        when /^Thread model:\s(.*)/
          gcc[:thread_model] = $1
        end
      end
    end
    @c[:gcc] = gcc unless gcc.empty?
  end

  def collect_glibc
    # glibc
    ["/lib/libc.so.6", "/lib64/libc.so.6"].each do |glibc|
      collect( Ohai.abs_path( glibc )) do |so|
        description = so.stdout.split($/).first
        if description =~ /(\d+\.\d+\.?\d*)/
          @c[:glibc] = Mash.new
          @c[:glibc][:version] = $1
          @c[:glibc][:description] = description
        end
      end
    end
  end

  def check_for_cl
    # ms cl
    collect("cl /?") do |so|
      description = so.stderr.lines.first.chomp
      if description =~ /Compiler Version ([\d\.]+)/
        @c[:cl] = Mash.new
        @c[:cl][:version] = $1
        @c[:cl][:description] = description
      end
    end
  end

  def check_for_devenv
    # ms vs
    collect("devenv.com /?") do |so|
      lines = so.stdout.split($/)
      description = lines[0].length == 0 ? lines[1] : lines[0]
      if description =~ /Visual Studio Version ([\d\.]+)/
        @c[:vs] = Mash.new
        @c[:vs][:version] = $1.chop
        @c[:vs][:description] = description
      end
    end
  end

  def collect_xlc
    # ibm xlc
    begin
      so = shell_out("xlc -qversion")
      if so.exitstatus == 0 || (so.exitstatus >> 8) == 249
        description = so.stdout.split($/).first
        if description =~ /V(\d+\.\d+)/
          @c[:xlc] = Mash.new
          @c[:xlc][:version] = $1
          @c[:xlc][:description] = description.strip
        end
      end
    rescue Ohai::Exceptions::Exec
    end
  end

  def collect_sunpro
    # sun pro
    collect("cc -V -flags") do |so|
      output = so.stderr.split
      if so.stderr =~ /^cc: Sun C/ && output.size >= 4
        @c[:sunpro] = Mash.new
        @c[:sunpro][:version] = output[3]
        @c[:sunpro][:description] = so.stderr.chomp
      end
    end
  end

  def collect_hpux_cc
    # hpux cc
    collect("what /opt/ansic/bin/cc") do |so|
      description = so.stdout.split($/).select { |line| line =~ /HP C Compiler/ }.first
      if description
        output = description.split
        @c[:hpcc] = Mash.new
        @c[:hpcc][:version] = output[1] if output.size >= 1
        @c[:hpcc][:description] = description.strip
      end
    end
  end

  collect_data(:aix) do
    @c = Mash.new
    collect_xlc
    collect_gcc
    languages[:c] = @c unless @c.empty?
  end

  collect_data(:darwin) do
    @c = Mash.new
    collect_gcc if xcode_installed?
    languages[:c] = @c unless @c.empty?
  end

  collect_data(:windows) do
    @c = Mash.new
    check_for_cl
    check_for_devenv
    languages[:c] = @c unless @c.empty?
  end

  collect_data(:hpux) do
    @c = Mash.new
    collect_gcc
    collect_hpux_cc
    languages[:c] = @c unless @c.empty?
  end

  collect_data(:default) do
    @c = Mash.new
    collect_gcc
    collect_glibc
    collect_sunpro
    languages[:c] = @c unless @c.empty?
  end
end
