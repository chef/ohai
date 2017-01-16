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

require "rbconfig"

Ohai.plugin(:C) do
  provides "languages/c"

  depends "languages"

  def collect(cmd, &block)
    so = shell_out(cmd)
    if so.exitstatus == 0
      yield(so)
    else
      Ohai::Log.debug("Plugin C '#{cmd}' failed. Skipping data.")
    end
  rescue Ohai::Exceptions::Exec
    Ohai::Log.debug("Plugin C '#{cmd}' binary could not be found. Skipping data.")
  end

  def xcode_installed?
    Ohai::Log.debug("Checking for Xcode Command Line Tools.")
    so = shell_out("/usr/bin/xcode-select -p")
    if so.exitstatus == 0
      return true
      Ohai::Log.debug("Xcode Command Line Tools found.")
    else
      return false
      Ohai::Log.debug("Xcode Command Line Tools not found.")
    end
  rescue Ohai::Exceptions::Exec
    Ohai::Log.debug("xcode-select binary could not be found. Skipping data.")
  end

  collect_data(:darwin) do
    if xcode_installed?
      collect_gcc
      collect_cc
    end
  end

  collect_data(:windows) do
    check_for_cl
    check_for_devenv
  end

  collect_data(:default) do
    collect_gcc
    collect_glibc
    check_for_cl
    check_for_devenv
    collect_xlc
    collect_cc
    collect_hpux_cc
  end

  c = Mash.new

  def collect_gcc
    #gcc
    collect("gcc -v") do |so|
      # Sample output:
      # Configured with: --prefix=/Applications/Xcode.app/Contents/Developer/usr --with-gxx-include-dir=/usr/include/c++/4.2.1
      # Apple LLVM version 7.3.0 (clang-703.0.29)
      # Target: x86_64-apple-darwin15.4.0
      # Thread model: posix
      # InstalledDir: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
      description = so.stderr.split($/).last
      output = description.split
      if output.length >= 3
        c[:gcc] = Mash.new
        c[:gcc][:version] = output[2]
        c[:gcc][:description] = description
      end
    end
  end

  def collect_glibc
    #glibc
    ["/lib/libc.so.6", "/lib64/libc.so.6"].each do |glibc|
      collect( Ohai.abs_path( glibc )) do |so|
        description = so.stdout.split($/).first
        if description =~ /(\d+\.\d+\.?\d*)/
          c[:glibc] = Mash.new
          c[:glibc][:version] = $1
          c[:glibc][:description] = description
        end
      end unless c[:glibc] || ::RbConfig::CONFIG["host_os"] =~ /mswin|mingw32|windows/
    end
  end

  def check_for_cl
    #ms cl
    collect("cl /?") do |so|
      description = so.stderr.lines.first.chomp
      if description =~ /Compiler Version ([\d\.]+)/
        c[:cl] = Mash.new
        c[:cl][:version] = $1
        c[:cl][:description] = description
      end
    end
  end

  def check_for_devenv
    #ms vs
    collect("devenv.com /?") do |so|
      lines = so.stdout.split($/)
      description = lines[0].length == 0 ? lines[1] : lines[0]
      if description =~ /Visual Studio Version ([\d\.]+)/
        c[:vs] = Mash.new
        c[:vs][:version] = $1.chop
        c[:vs][:description] = description
      end
    end
  end

  def collect_xlc
    #ibm xlc
    begin
      so = shell_out("xlc -qversion")
      if so.exitstatus == 0 || (so.exitstatus >> 8) == 249
        description = so.stdout.split($/).first
        if description =~ /V(\d+\.\d+)/
          c[:xlc] = Mash.new
          c[:xlc][:version] = $1
          c[:xlc][:description] = description.strip
        end
      end
    rescue Ohai::Exceptions::Exec
    end
  end

  def collect_cc
    #sun pro
    collect("cc -V -flags") do |so|
      output = so.stderr.split
      if so.stderr =~ /^cc: Sun C/ && output.size >= 4
        c[:sunpro] = Mash.new
        c[:sunpro][:version] = output[3]
        c[:sunpro][:description] = so.stderr.chomp
      end
    end
  end

  def collect_hpux_cc
    #hpux cc
    collect("what /opt/ansic/bin/cc") do |so|
      description = so.stdout.split($/).select { |line| line =~ /HP C Compiler/ }.first
      if description
        output = description.split
        c[:hpcc] = Mash.new
        c[:hpcc][:version] = output[1] if output.size >= 1
        c[:hpcc][:description] = description.strip
      end
    end
  end

  languages[:c] = c unless c.empty?
end
