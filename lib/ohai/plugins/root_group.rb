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

  #
  # Performs a WMI query using WIN32OLE from the Ruby Stdlib
  #
  # @return [String]
  #
  def wmi_property_from_query(wmi_property, wmi_query)
    @wmi = ::WIN32OLE.connect('winmgmts://')
    result = @wmi.ExecQuery(wmi_query)
    return nil unless result.each.count > 0
    result.each.next.send(wmi_property)
  end

  # Per http://support.microsoft.com/kb/243330 SID: S-1-5-32-544 is the
  # internal name for the Administrators group, which lets us work
  # properly in environments with a renamed or localized name for the
  # Administrators group.
  # Use LocalAccount=True because otherwise WMI will attempt to include
  # (unneeded) Active Directory groups by querying AD, which is a performance
  # and reliability issue since AD might not be reachable.
  def windows_root_group_name
    wmi_property_from_query(
      :name,
      "select * from Win32_Group where sid like 'S-1-5-32-544' and LocalAccount=True"
    )
  end

  collect_data(:windows) do
    root_group windows_root_group_name
  end

  collect_data(:default) do
    root_group Etc.getgrgid(Etc.getpwnam("root").gid).name
  end
end
