#
# Author:: Pavel Yudin (<pyudin@parallels.com>)
# Copyright:: Copyright (c) 2015 Pavel Yudin
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

require 'ohai/util/file_helper'

include Ohai::Util::FileHelper

Ohai.plugin(:Virtualization) do
  provides "virtualization"

  def powershell_exists?
    which('powershell.exe')
  end

  collect_data(:windows) do
    virtualization Mash.new unless virtualization
    virtualization[:systems] = Mash.new unless virtualization[:systems]

    # Detect Parallels virtual machine from BIOS information
    if powershell_exists?
      so = shell_out('powershell.exe "Get-WmiObject -Class Win32_BIOS"')
      if so.stdout =~ /Parallels Software International Inc./
        virtualization[:system] = 'parallels'
        virtualization[:role] = 'guest'
        virtualization[:systems][:parallels] = 'guest'
      end
    end
  end
end
