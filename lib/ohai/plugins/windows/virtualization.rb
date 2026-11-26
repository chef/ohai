# frozen_string_literal: true
#
# Author:: Pavel Yudin (<pyudin@parallels.com>)
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2015 Pavel Yudin
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

  # HypervisorPresent alone is also true on hardware running virtualization
  # based security and on any guest. The Hyper-V Virtual Machine Management
  # service (vmms) only exists once the Hyper-V role is installed, and
  # HypervisorPresent shows that the hypervisor actually started.
  def hyperv_host?(wmi)
    return false unless wmi.first_of("Win32_ComputerSystem")&.[]("hypervisorpresent")

    !wmi.query("SELECT Name FROM Win32_Service WHERE Name = 'vmms'").empty?
  end

  collect_data(:windows) do
    require "wmi-lite/wmi" unless defined?(WmiLite::Wmi)

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
    elsif hyperv_host?(wmi)
      logger.trace("Plugin Virtualization: the vmms service and a running hypervisor indicate a Hyper-V host")
      virtualization[:system] = "hyperv"
      virtualization[:role] = "host"
      virtualization[:systems][:hyperv] = "host"
    end
  end
end
