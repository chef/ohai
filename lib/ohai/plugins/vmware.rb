# frozen_string_literal: true
#
# Author:: "Dan Robinson" <drobinson@chef.io>
# Author:: "Christopher M. Luciano" <cmlucian@us.ibm.com>
# Copyright:: Copyright (c) Chef Software Inc.
# Copyright (C) 2015 IBM Corp.
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
# Provides a set of attributes for a VMware ESX virtual machine with results
# obtained from vmware-toolbox-cmd.  VMware Tools must be installed
# on the virtual machine.
#
# Modify the path to vmware-toolbox-cmd in the call to get_vm_attributes for
# your particular operating system and configuration
#
# Example:
#
# get_vm_attributes("/usr/bin/vmware-toolbox-cmd")
#

Ohai.plugin(:VMware) do
  provides "vmware"
  depends "virtualization"

  def from_cmd(cmd)
    shell_out(cmd).stdout.strip
  end

  def get_vm_attributes(vmtools_path)
    if !file_exist?(vmtools_path)
      logger.trace("Plugin VMware: #{vmtools_path} not found")
    else
      vmware Mash.new
      vmware[:host] = Mash.new
      vmware[:guest] = Mash.new
      begin
        # vmware-toolbox-cmd stat <param> commands
        # Iterate through each parameter supported by the "vwware-toolbox-cmd stat" command, assign value
        # to attribute "vmware[:<parameter>]"
        %w{hosttime speed sessionid balloon swap memlimit memres cpures cpulimit}.each do |param|
          vmware[param] = from_cmd([vmtools_path, "stat", param])
          if param == "hosttime" && vmtools_path.include?("Program Files")
            # popen and %x return stdout encoded as IBM437 in Windows but in a string marked
            # UTF-8. The string doesn't throw an exception when encoded to "UTF-8" but
            # displays [?] character in Windows without this.
            #
            # .force_encoding(Encoding::ISO_8859_1) causes the character to be dropped
            # and .force_encoding(Encoding::Windows_1252) displays the „ character in place
            # of an ä. .force_encoding(Encoding::IBM437) allows for the correct characters
            # to be displayed.
            #
            # Note:
            # * this is broken for at least Ruby 2.7 through 3.1.3
            # * confirmed that this is broken on Windows Server 2022
            vmware[param] = vmware[param].force_encoding(Encoding::IBM437).encode("UTF-8")
          end
          if vmware[param].include?("UpdateInfo failed")
            vmware[param] = nil
          end
        end
        # vmware-toolbox-cmd <param> status commands
        # Iterate through each parameter supported by the "vmware-toolbox-cmd status" command, assign value
        # to attribute "vmware[:<parameter>]"
        %w{upgrade timesync}.each do |param|
          vmware[param] = from_cmd([vmtools_path, param, "status"])
        end
        # Distinguish hypervisors by presence of raw session data (vSphere only)
        raw_session = from_cmd([vmtools_path, "stat", "raw", "json", "session"])
        if raw_session.empty?
          vmware[:host] = {
            type: "vmware_desktop",
          }
        else
          require "json" unless defined?(JSON)
          session = JSON.parse(raw_session)
          vmware[:host] = {
            type: "vmware_vsphere",
            version: session["version"],
          }
        end
        vmware[:guest][:vmware_tools_version] = from_cmd([vmtools_path, "-v"]).split(" ").first
      rescue
        logger.trace("Plugin VMware: Error while collecting VMware guest attributes")
      end
    end
  end

  collect_data(:linux) do
    get_vm_attributes("/usr/bin/vmware-toolbox-cmd") if virtualization[:systems][:vmware]
  end

  collect_data(:windows) do
    get_vm_attributes("C:/Program Files/VMWare/VMware Tools/VMwareToolboxCmd.exe") if virtualization[:systems][:vmware]
  end
end
