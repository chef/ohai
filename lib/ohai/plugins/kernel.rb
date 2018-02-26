#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Benjamin Black (<nostromo@gmail.com>)
# Author:: Bryan McLellan (<btm@loftninjas.org>)
# Author:: Claire McQuin (<claire@chef.io>)
# Author:: James Gartrell (<jgartrel@gmail.com>)
# Copyright:: Copyright (c) 2008-2018 Chef Software, Inc.
# Copyright:: Copyright (c) 2009 Bryan McLellan
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Ohai.plugin(:Kernel) do
  provides "kernel", "kernel/modules"

  # common initial kernel attribute values
  # @return [Mash] basic kernel properties from uname
  def init_kernel
    kernel Mash.new
    [["uname -s", :name], ["uname -r", :release],
     ["uname -v", :version], ["uname -m", :machine],
     ["uname -p", :processor]].each do |cmd, property|
      so = shell_out(cmd)
      kernel[property] = so.stdout.split($/)[0]
    end
    kernel
  end

  # common *bsd code for collecting modules data
  # @return [Mash]
  def bsd_modules(path)
    modules = Mash.new
    so = shell_out("#{Ohai.abs_path(path)}")
    so.stdout.lines do |line|
      #  1    7 0xc0400000 97f830   kernel
      if line =~ /(\d+)\s+(\d+)\s+([0-9a-fx]+)\s+([0-9a-fx]+)\s+([a-zA-Z0-9\_]+)/
        modules[$5] = { :size => $4, :refcount => $2 }
      end
    end
    modules
  end

  # given the SystemType value from WMI's Win32_ComputerSystem class
  # return the architecture type
  # @param [String] sys_type SystemType value from Win32_ComputerSystem
  # @return [String] x86_64 or i386
  def arch_lookup(sys_type)
    return "x86_64" if sys_type == "x64-based PC"
    return "i386" if sys_type == "X86-based PC"
    sys_type
  end

  # decode the OSType field from WMI Win32_OperatingSystem class
  # https://msdn.microsoft.com/en-us/library/aa394239(v=vs.85).aspx
  # @param [Integer] sys_type the integer value from OSType
  # @return [String] the human consumable OS type value
  def os_type_decode(sys_type)
    case sys_type
    when 18 then "WINNT" # most likely so first
    when 0 then "Unknown"
    when 1 then "Other"
    when 14 then "MSDOS"
    when 15 then "WIN3x"
    when 16 then "WIN95"
    when 17 then "WIN98"
    when 19 then "WINCE"
    else nil
    end
  end

  collect_data(:default) do
    kernel init_kernel
  end

  collect_data(:darwin) do
    kernel init_kernel
    kernel[:os] = kernel[:name]

    so = shell_out("sysctl -n hw.optional.x86_64")
    if so.stdout.split($/)[0].to_i == 1
      kernel[:machine] = "x86_64"
    end

    modules = Mash.new
    so = shell_out("kextstat -k -l")
    so.stdout.lines do |line|
      if line =~ /(\d+)\s+(\d+)\s+0x[0-9a-f]+\s+0x([0-9a-f]+)\s+0x[0-9a-f]+\s+([a-zA-Z0-9\.]+) \(([0-9\.]+)\)/
        modules[$4] = { :version => $5, :size => $3.hex, :index => $1, :refcount => $2 }
      end
    end

    kernel[:modules] = modules
  end

  collect_data(:freebsd, :dragonflybsd) do
    kernel init_kernel
    kernel[:os] = kernel[:name]

    so = shell_out("uname -i")
    kernel[:ident] = so.stdout.split($/)[0]
    so = shell_out("sysctl kern.securelevel")
    kernel[:securelevel] = so.stdout.split($/).select { |e| e =~ /kern.securelevel: (.+)$/ }

    kernel[:modules] = bsd_modules("/sbin/kldstat")
  end

  collect_data(:linux) do
    kernel init_kernel

    so = shell_out("uname -o")
    kernel[:os] = so.stdout.split($/)[0]

    modules = Mash.new
    so = shell_out("env lsmod")
    so.stdout.lines do |line|
      if line =~ /([a-zA-Z0-9\_]+)\s+(\d+)\s+(\d+)/
        modules[$1] = { :size => $2, :refcount => $3 }
        # Making sure to get the module version that has been loaded
        if File.exist?("/sys/module/#{$1}/version")
          version = File.read("/sys/module/#{$1}/version").chomp.strip
          modules[$1]["version"] = version unless version.empty?
        end
      end
    end

    kernel[:modules] = modules
  end

  collect_data(:netbsd, :openbsd) do
    kernel init_kernel
    kernel[:os] = kernel[:name]

    so = shell_out("sysctl kern.securelevel")
    kernel[:securelevel] = so.stdout.split($/).select { |e| e =~ /kern.securelevel:\ (.+)$/ }

    kernel[:modules] = bsd_modules("/usr/bin/modstat")
  end

  collect_data(:solaris2) do
    kernel init_kernel

    so = shell_out("uname -s")
    kernel[:os] = so.stdout.split($/)[0]

    so = File.open("/etc/release") { |file| file.gets }
    md = /(?<update>\d.*\d)/.match(so)
    kernel[:update] = md[:update] if md

    modules = Mash.new

    so = shell_out("modinfo")
    # EXAMPLE:
    # Id Loadaddr   Size Info Rev Module Name
    #  6  1180000   4623   1   1  specfs (filesystem for specfs)
    module_description = /[\s]*([\d]+)[\s]+([a-f\d]+)[\s]+([a-f\d]+)[\s]+(?:[\-\d]+)[\s]+(?:[\d]+)[\s]+([\S]+)[\s]+\((.+)\)$/
    so.stdout.lines do |line|
      if mod = module_description.match(line)
        modules[mod[4]] = { :id => mod[1].to_i, :loadaddr => mod[2], :size => mod[3].to_i(16), :description => mod[5] }
      end
    end

    kernel[:modules] = modules
  end

  collect_data(:windows) do
    require "win32ole"
    require "wmi-lite/wmi"

    WIN32OLE.codepage = WIN32OLE::CP_UTF8

    wmi = WmiLite::Wmi.new

    kernel Mash.new

    host = wmi.first_of("Win32_OperatingSystem")
    kernel[:os_info] = Mash.new
    host.wmi_ole_object.properties_.each do |p|
      kernel[:os_info][p.name.wmi_underscore.to_sym] = host[p.name.downcase]
    end

    kernel[:name] = "#{kernel[:os_info][:caption]}"
    kernel[:release] = "#{kernel[:os_info][:version]}"
    kernel[:version] = "#{kernel[:os_info][:version]} #{kernel[:os_info][:csd_version]} Build #{kernel[:os_info][:build_number]}"
    kernel[:os] = os_type_decode(kernel[:os_info][:os_type]) || languages[:ruby][:host_os]

    kernel[:cs_info] = Mash.new
    host = wmi.first_of("Win32_ComputerSystem")
    host.wmi_ole_object.properties_.each do |p|
      next if p.name.wmi_underscore == "oem_logo_bitmap" # big bitmap doesn't need to be in ohai
      kernel[:cs_info][p.name.wmi_underscore.to_sym] = host[p.name.downcase]
    end

    kernel[:machine] = arch_lookup("#{kernel[:cs_info][:system_type]}")
  end
end
