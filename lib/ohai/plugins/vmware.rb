#
# Author:: "Dan Robinson" <drobinson@chef.io>
# Author:: "Christopher M. Luciano" <cmlucian@us.ibm.com>
# Copyright:: Copyright (c) 2014-2016 Chef Software, Inc.
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
    so = shell_out(cmd)
    so.stdout.split($/)[0]
  end

  def get_vm_attributes(vmtools_path)
    if !File.exist?(vmtools_path)
      Ohai::Log.debug("Plugin VMware: #{vmtools_path} not found")
    else
      vmware Mash.new
      begin
        # vmware-toolbox-cmd stat <param> commands
        # Iterate through each parameter supported by the "vwware-toolbox-cmd stat" command, assign value
        # to attribute "vmware[:<parameter>]"
        %w{hosttime speed sessionid balloon swap memlimit memres cpures cpulimit}.each do |param|
          vmware[param] = from_cmd("#{vmtools_path} stat #{param}")
          if vmware[param] =~ /UpdateInfo failed/
            vmware[param] = nil
          end
        end
        # vmware-toolbox-cmd <param> status commands
        # Iterate through each parameter supported by the "vwware-toolbox-cmd status" command, assign value
        # to attribute "vmware[:<parameter>]"
        %w{upgrade timesync}.each do |param|
          vmware[param] = from_cmd("#{vmtools_path} #{param} status")
        end
      rescue
        Ohai::Log.debug("Plugin VMware: Error while collecting VMware guest attributes")
      end
    end
  end

  collect_data(:linux) do
    get_vm_attributes("/usr/bin/vmware-toolbox-cmd") if virtualization[:systems][:vmware]
  end

end
