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

  require "ohai/util/win32/group_helper" if RUBY_PLATFORM =~ /mswin|mingw32|windows/

  collect_data do
    case ::RbConfig::CONFIG["host_os"]
    when /mswin|mingw32|windows/
      group = Ohai::Util::Win32::GroupHelper.windows_root_group_name
      root_group group
    else
      root_group Etc.getgrgid(Etc.getpwnam("root").gid).name
    end
  end
end
