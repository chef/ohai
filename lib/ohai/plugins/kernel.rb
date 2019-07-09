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
    so = shell_out((Ohai.abs_path(path)).to_s)
    so.stdout.lines do |line|
      #  1    7 0xc0400000 97f830   kernel
      if line =~ /(\d+)\s+(\d+)\s+([0-9a-fx]+)\s+([0-9a-fx]+)\s+([a-zA-Z0-9\_]+)/
        modules[$5] = { size: $4, refcount: $2 }
      end
    end
    modules
  end

  # given the OperatingSystemSKU value from WMI's Win32_OperatingSystem class
  # https://msdn.microsoft.com/en-us/library/aa394239(v=vs.85).aspx
  # return if we're on a Server Core installation
  # @param [String] sku OperatingSystemSKU value from Win32_OperatingSystem
  # @return [boolean]
  def server_core?(sku)
    return true if [
      12, # Server Datacenter Core
      39, # Server Datacenter without Hyper-V Core
      14, # Server Enterprise Core
      41, # Server Enterprise without Hyper-V Core
      13, # Server Standard Core
      40, # Server Standard without Hyper-V Core
      63, # Small Business Server Premium Core
      53, # Server Solutions Premium Core
      46, # Storage Server Enterprise Core
      43, # Storage Server Express Core
      44, # Storage Server Standard Core
      45, # Storage Server Workgroup Core
      29, # Web Server Core
    ].include?(sku)

    false
  end

  # given the SystemType value from WMI's Win32_ComputerSystem class
  # https://msdn.microsoft.com/en-us/library/aa394102(v=vs.85).aspx
  # return the architecture type
  # @param [String] sys_type SystemType value from Win32_ComputerSystem
  # @return [String] x86_64 or i386
  def arch_lookup(sys_type)
    return "x86_64" if sys_type == "x64-based PC"
    return "i386" if sys_type == "X86-based PC"

    sys_type
  end

  # given the ProductType value from WMI's Win32_OperatingSystem class
  # https://msdn.microsoft.com/en-us/library/aa394239(v=vs.85).aspx
  # return either workstation or server
  # @param [Integer] type ProductType value from Win32_OperatingSystem
  # @return [String] Workstation or Server
  def product_type_decode(type)
    return "Workstation" if type == 1

    "Server"
  end

  # decode the OSType field from WMI Win32_OperatingSystem class
  # https://msdn.microsoft.com/en-us/library/aa394239(v=vs.85).aspx
  # @param [Integer] sys_type OSType value from Win32_OperatingSystem
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

  # decode the PCSystemType field from WMI Win32_OperatingSystem class
  # https://msdn.microsoft.com/en-us/library/aa394239(v=vs.85).aspx
  # @param [Integer] type the integer value from PCSystemType
  # @return [String] the human consumable OS type value
  def pc_system_type_decode(type)
    case type
    when 4 then "Enterprise Server" # most likely so first
    when 0 then "Unspecified"
    when 1 then "Desktop"
    when 2 then "Mobile"
    when 3 then "Workstation"
    when 5 then "SOHO Server"
    when 6 then "Appliance PC"
    when 7 then "Performance Server"
    when 8 then "Maximum"
    else nil
    end
  end

  # see if a WMI name is blacklisted so we can avoid writing out
  # useless data to ohai
  # @param [String] name the wmi name to check
  # @return [Boolean] is the wmi name blacklisted
  def blacklisted_wmi_name?(name)
    [
     "creation_class_name", # this is just the wmi name
     "cs_creation_class_name", # this is just the wmi name
     "oem_logo_bitmap", # this is the entire OEM bitmap file
     "total_swap_space_size", # already in memory plugin
     "total_virtual_memory_size", # already in memory plugin
     "total_virtual_memory_size", # already in memory plugin
     "free_physical_memory", # already in memory plugin
     "free_space_in_paging_files", # already in memory plugin
     "free_virtual_memory", # already in memory plugin
    ].include?(name)
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
        modules[$4] = { version: $5, size: $3.hex, index: $1, refcount: $2 }
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
        modules[$1] = { size: $2, refcount: $3 }
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

    so = File.open("/etc/release", &:gets)
    md = /(?<update>\d.*\d)/.match(so)
    kernel[:update] = md[:update] if md

    modules = Mash.new

    so = shell_out("modinfo")
    # EXAMPLE:
    # Id Loadaddr   Size Info Rev Module Name
    #  6  1180000   4623   1   1  specfs (filesystem for specfs)
    module_description = /[\s]*([\d]+)[\s]+([a-f\d]+)[\s]+([a-f\d]+)[\s]+(?:[\-\d]+)[\s]+(?:[\d]+)[\s]+([\S]+)[\s]+\((.+)\)$/
    so.stdout.lines do |line|
      if ( mod = module_description.match(line) )
        modules[mod[4]] = { id: mod[1].to_i, loadaddr: mod[2], size: mod[3].to_i(16), description: mod[5] }
      end
    end

    kernel[:modules] = modules
  end

  collect_data(:windows) do
    require "win32ole" unless defined?(WIN32OLE)
    require "wmi-lite/wmi"

    WIN32OLE.codepage = WIN32OLE::CP_UTF8

    wmi = WmiLite::Wmi.new

    kernel Mash.new

    host = wmi.first_of("Win32_OperatingSystem")
    kernel[:os_info] = Mash.new
    host.wmi_ole_object.properties_.each do |p|
      next if blacklisted_wmi_name?(p.name.wmi_underscore)

      kernel[:os_info][p.name.wmi_underscore.to_sym] = host[p.name.downcase]
    end

    kernel[:name] = (kernel[:os_info][:caption]).to_s
    kernel[:release] = (kernel[:os_info][:version]).to_s
    kernel[:version] = "#{kernel[:os_info][:version]} #{kernel[:os_info][:csd_version]} Build #{kernel[:os_info][:build_number]}"
    kernel[:os] = os_type_decode(kernel[:os_info][:os_type]) || languages[:ruby][:host_os]
    kernel[:product_type] = product_type_decode(kernel[:os_info][:product_type])
    kernel[:server_core] = server_core?(kernel[:os_info][:operating_system_sku])

    kernel[:cs_info] = Mash.new
    host = wmi.first_of("Win32_ComputerSystem")
    host.wmi_ole_object.properties_.each do |p|
      next if blacklisted_wmi_name?(p.name.wmi_underscore)

      kernel[:cs_info][p.name.wmi_underscore.to_sym] = host[p.name.downcase]
    end

    kernel[:machine] = arch_lookup((kernel[:cs_info][:system_type]).to_s)
    kernel[:system_type] = pc_system_type_decode(kernel[:cs_info][:pc_system_type])
  end
end
