#
# Author:: Joseph Anthony Pasquale Holsten (<joseph@josephholsten.com>)
# Copyright:: Copyright (c) 2013 Joseph Anthony Pasquale Holsten
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Ohai.plugin(:RootGroup) do
  provides "root_group"

  collect_data(:windows) do
    require "wmi-lite/wmi"

    wmi = WmiLite::Wmi.new
    # Per http://support.microsoft.com/kb/243330 SID: S-1-5-32-544 is the
    # internal name for the Administrators group, which lets us work
    # properly in environments with a renamed or localized name for the
    # Administrators group.
    # Use LocalAccount=True because otherwise WMI will attempt to include
    # (unneeded) Active Directory groups by querying AD, which is a performance
    # and reliability issue since AD might not be reachable.
    groups = wmi.query("select * from Win32_Group where sid like 'S-1-5-32-544' and LocalAccount=True")
    windows_root_group_name = groups[0]["name"]
    root_group windows_root_group_name
  end

  collect_data(:default) do
    users = file_read('/etc/passwd').lines.map do |line|
      name, has_password, uid, gid, gecos, dir, shell = line.strip.split(':')
      Mash.new(name: name, dir: dir, gid: gid, uid: uid, shell: shell, gecos: gecos)
    end

    root_user = users.find { |u| u[:name] == 'root' }
    
    groups = file_read('/etc/group').lines.map do |line|
      name, has_password, gid, members = line.strip.split(':')
      Mash.new(name: name, gid: gid, members: members.to_s.split(","))
    end
    
    found_root_group = groups.find { |group| group[:gid] == root_user[:gid] }

    if found_root_group
      root_group found_root_group[:name]
    end
  end
end
