#
# Author:: Pavel Yudin (<pyudin@parallels.com>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2015 Pavel Yudin
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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

Ohai.plugin(:Virtualization) do
  provides "virtualization"
  require_relative "../../mixin/dmi_decode"
  include Ohai::Mixin::DmiDecode

  collect_data(:windows) do
    require "wmi-lite/wmi"

    virtualization Mash.new unless virtualization
    virtualization[:systems] ||= Mash.new

    # Grab system DMI data from WMI to determine vendor information
    wmi = WmiLite::Wmi.new
    dmi = wmi.first_of("Win32_ComputerSystemProduct")

    guest = guest_from_dmi_data(dmi["vendor"], dmi["name"], dmi["version"])
    if guest
      logger.trace("Plugin Virtualization: DMI data in Win32_ComputerSystemProduct indicates #{guest} guest")
      virtualization[:system] = guest
      virtualization[:role] = "guest"
      virtualization[:systems][guest.to_sym] = "guest"
    end
  end
end
