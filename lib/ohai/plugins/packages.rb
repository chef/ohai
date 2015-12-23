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
  provides 'packages'
  depends 'platform_family'

  collect_data(:linux) do
    packages Mash.new

    if %w(debian).include? platform_family
      so = shell_out('dpkg-query -W')
      pkgs = so.stdout.split("\n")

      pkgs.each do |pkg|
        name, version = pkg.split("\t")
        packages[name] = { 'version' => version }
      end

    elsif %w(rhel fedora suse).include? platform_family
      require 'shellwords'
      format = Shellwords.escape '%{NAME}\t%{VERSION}\t%{RELEASE}\n'
      so = shell_out("rpm -qa --queryformat #{format}")
      pkgs = so.stdout.split("\n")

      pkgs.each do |pkg|
        name, version, release = pkg.split("\t")
        packages[name] = { 'version' => version, 'release' => release }
      end
    end
  end

  collect_data(:windows) do
    packages Mash.new

    require 'wmi-lite'

    wmi = WmiLite::Wmi.new
    w32_product = wmi.instances_of('Win32_Product')

    w32_product.find_all.each do |product|
      name = product['name']
      package = packages[name] = Mash.new
      %w(version vendor installdate).each do |attr|
        package[attr] = product[attr]
      end
    end
  end
end
