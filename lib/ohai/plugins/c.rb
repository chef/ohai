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

require 'rbconfig'

Ohai.plugin(:C) do
  provides "languages/c"

  depends "languages"

  collect_data do
    c = Mash.new

    #gcc
    begin
      so = shell_out("gcc -v")
      if so.exitstatus == 0
        description = so.stderr.split($/).last
        output = description.split
        if output.length >= 3
          c[:gcc] = Mash.new
          c[:gcc][:version] = output[2]
          c[:gcc][:description] = description
        end
      end
    rescue Errno::ENOENT
    end

    #glibc
    ["/lib/libc.so.6", "/lib64/libc.so.6"].each do |glibc|
      begin
        so = shell_out( Ohai.abs_path( glibc ))
        if so.exitstatus == 0
          description = so.stdout.split($/).first
          if description =~ /(\d+\.\d+\.?\d*)/
            c[:glibc] = Mash.new
            c[:glibc][:version] = $1
            c[:glibc][:description] = description
          end
          break
        end
      rescue Errno::ENOENT
      end
    end

    #ms cl
    begin
      so = shell_out("cl /?")
      if so.exitstatus == 0
        description = so.stderr.lines.first.chomp
        if description =~ /Compiler Version ([\d\.]+)/
          c[:cl] = Mash.new
          c[:cl][:version] = $1
          c[:cl][:description] = description
        end
      end
    rescue Errno::ENOENT
    end

    #ms vs
    begin
      so = shell_out("devenv.com /?")
      if so.exitstatus == 0
        lines = so.stdout.split($/)
        description = lines[0].length == 0 ? lines[1] : lines[0]
        if description =~ /Visual Studio Version ([\d\.]+)/
          c[:vs] = Mash.new
          c[:vs][:version] = $1.chop
          c[:vs][:description] = description
        end
      end
    rescue Errno::ENOENT
    end

    #ibm xlc
    begin
      so = shell_out("xlc -qversion")
      if so.exitstatus == 0 or (so.exitstatus >> 8) == 249
        description = so.stdout.split($/).first
        if description =~ /V(\d+\.\d+)/
          c[:xlc] = Mash.new
          c[:xlc][:version] = $1
          c[:xlc][:description] = description.strip
        end
      end
    rescue Errno::ENOENT
    end

    #sun pro
    begin
      so = shell_out("cc -V -flags")
      if so.exitstatus == 0
        output = so.stderr.split
        if so.stderr =~ /^cc: Sun C/ && output.size >= 4
          c[:sunpro] = Mash.new
          c[:sunpro][:version] = output[3]
          c[:sunpro][:description] = so.stderr.chomp
        end
      end
    rescue Errno::ENOENT
    end

    #hpux cc
    begin
      so = shell_out("what /opt/ansic/bin/cc")
      if so.exitstatus == 0
        description = so.stdout.split($/).select { |line| line =~ /HP C Compiler/ }.first
        if description
          output = description.split
          c[:hpcc] = Mash.new
          c[:hpcc][:version] = output[1] if output.size >= 1
          c[:hpcc][:description] = description.strip
        end
      end
    rescue Errno::ENOENT
    end

    languages[:c] = c if c.keys.length > 0
  end
end
