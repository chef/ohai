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

provides 'root_group'

case ::RbConfig::CONFIG['host_os']
when /mswin|mingw32|windows/
  # Per http://support.microsoft.com/kb/243330 SID: S-1-5-32-544 is the
  # internal name for the Administrators group, which lets us work
  # properly in environments with a renamed or localized name for the
  # Administrators group
  group = WMI::Win32_Group.find(:first, :conditions => {:SID => 'S-1-5-32-544'})
  root_group group['Name']
else
  root_group Etc.getgrgid(Etc.getpwnam('root').gid).name
end
