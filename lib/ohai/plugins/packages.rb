# Author:: "Christian Höltje" <choltje@us.ibm.com>
# Author:: "Christopher M. Luciano" <cmlucian@us.ibm.com>
# Author:: Shahul Khajamohideen (<skhajamohid1@bloomberg.net>)
# Copyright (C) 2015 IBM Corp.
# Copyright (C) 2015 Bloomberg Finance L.P.
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
#
Ohai.plugin(:Packages) do
  provides "packages"
  depends "platform_family"

  unless defined?(WINDOWS_ATTRIBUTE_ALIASES)
    WINDOWS_ATTRIBUTE_ALIASES = {
      "DisplayVersion" => "version",
      "Publisher" => "publisher",
      "InstallDate" => "installdate",
    }.freeze
  end

  collect_data(:linux) do
    packages Mash.new
    case platform_family
    when "debian"
      format = '${Package}\t${Version}\t${Architecture}\n'
      so = shell_out("dpkg-query -W -f='#{format}'")
      pkgs = so.stdout.lines

      pkgs.each do |pkg|
        name, version, arch = pkg.split
        packages[name] = { "version" => version, "arch" => arch }
      end

    when "rhel", "fedora", "suse", "pld", "amazon"
      format = '%{NAME}\t%|EPOCH?{%{EPOCH}}:{0}|\t%{VERSION}\t%{RELEASE}\t%{INSTALLTIME}\t%{ARCH}\n'
      so = shell_out("rpm -qa --qf '#{format}'")
      pkgs = so.stdout.lines

      pkgs.each do |pkg|
        name, epoch, version, release, installdate, arch = pkg.split
        packages[name] = { "epoch" => epoch, "version" => version, "release" => release, "installdate" => installdate, "arch" => arch }
      end

    when "arch"
      require "date"

      # Set LANG=C to force an easy to parse date format
      so = shell_out("LANG=C pacman -Qi")

      so.stdout.split("\n\n").each do |record|
        pacman_info = {}
        record.lines.each do |line|
          if line =~ /\A(.*?)\s+:\s(.*)\z/m
            key, value = Regexp.last_match[1..2]
            key = key.strip.downcase.gsub(/\s+/, "")
            pacman_info[key] = value.strip
          end
        end

        name = pacman_info["name"]
        installdate = DateTime.strptime(pacman_info["installdate"], "%Ec").strftime("%s")
        packages[name] = {
          "version" => pacman_info["version"],
          "installdate" => installdate,
          "arch" => pacman_info["architecture"],
        }
      end
    end
  end

  def collect_programs_from_registry_key(key_path)
    # @see https://docs.microsoft.com/en-us/dotnet/api/microsoft.win32.registrykey?view=netframework-4.7.2
    # EXAMPLE: Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object { Write-Host "$($_.GetValue('DisplayName')),$($_.GetValue('DisplayVersion')),$($_.GetValue('Publisher')),$($_.GetValue('InstallDate'))" }
    package_properties = %w[ DisplayName DisplayVersion InstallDate Publisher ]
    package_query_partial = package_properties.map { |p| "$($_.GetValue('#{p}'))" }.join(",")
    package_cmd = "Get-ChildItem -Path \"#{key_path}\" | ForEach-Object { Write-Host \"#{package_query_partial}\" } "
    results = shell_out(package_cmd).stdout.strip
    
    results.lines.each do |line|
      display_name, display_version, install_date, publisher = line.strip.split(",",4)
      next if display_name.to_s == ""
      packages[display_name] = Mash.new(version: display_version, publisher: publisher, install_date: install_date.to_i)
    end
  end

  collect_data(:windows) do
    packages Mash.new
    collect_programs_from_registry_key('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall')
    # on 64 bit systems, 32 bit programs are stored here
    collect_programs_from_registry_key('HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall')
  end

  collect_data(:aix) do
    packages Mash.new
    so = shell_out("lslpp -L -q -c")
    pkgs = so.stdout.lines

    # Output format is
    # Package Name:Fileset:Level
    # On aix, filesets are packages and levels are versions
    pkgs.each do |pkg|
      name, fileset, version, _, _, _, pkg_type = pkg.split(":")
      if pkg_type == "R"
        # RPM
        packages[name] = { "version" => version }
      else
        # LPP
        packages[fileset] = { "version" => version }
      end
    end
  end

  collect_data(:freebsd) do
    packages Mash.new
    so = shell_out('pkg query -a "%n %v"')
    # Output format is
    # name version
    so.stdout.lines do |pkg|
      name, version = pkg.split(" ")
      packages[name] = { "version" => version }
    end
  end

  def collect_ips_packages
    so = shell_out("pkg list -H")
    # Output format is
    # NAME (PUBLISHER)    VERSION    IFO
    so.stdout.lines.each do |pkg|
      tokens = pkg.split
      if tokens.length == 3 # No publisher info
        name, version, = tokens
      else
        name, publisher, version, = tokens
        publisher = publisher[1..-2]
      end
      packages[name] = { "version" => version }
      packages[name]["publisher"] = publisher if publisher
    end
  end

  def collect_sysv_packages
    so = shell_out("pkginfo -l")
    # Each package info is separated by a blank line
    chunked_lines = so.stdout.lines.map(&:strip).chunk do |line|
      !line.empty? || nil
    end
    chunked_lines.each do |_, lines| # rubocop: disable Performance/HashEachMethods
      package = {}
      lines.each do |line|
        key, value = line.split(":", 2)
        package[key.strip.downcase] = value.strip unless value.nil?
      end
      # pkginst is the installed package name
      packages[package["pkginst"]] = package.tap do |p|
        p.delete("pkginst")
      end
    end
  end

  collect_data(:solaris2) do
    packages Mash.new
    collect_ips_packages
    collect_sysv_packages
  end
end
