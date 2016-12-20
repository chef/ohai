# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

Ohai.plugin(:Azure) do
  provides "azure"

  collect_data do
    # The azure hints are populated by the knife plugin for Azure.
    # The project is located at https://github.com/chef/knife-azure
    # Please see the lib/chef/knife/azure_server_create.rb file in that
    # project for details
    azure_metadata_from_hints = hint?("azure")
    if azure_metadata_from_hints
      Ohai::Log.debug("Plugin Azure: azure_metadata_from_hints is present.")
      azure Mash.new
      azure_metadata_from_hints.each { |k, v| azure[k] = v }
    elsif has_waagent? || has_dhcp_option_245?
      Ohai::Log.debug("Plugin Azure: No hints present, but system appears to be on azure.")
      azure Mash.new
    else
      Ohai::Log.debug("Plugin Azure: No hints present for azure and doesn't appear to be azure.")
      false
    end
  end

  # check for either the waagent or the unknown-245 DHCP option that Azure uses
  # http://blog.mszcool.com/index.php/2015/04/detecting-if-a-virtual-machine-runs-in-microsoft-azure-linux-windows-to-protect-your-software-when-distributed-via-the-azure-marketplace/
  def has_waagent?
    if File.exist?("/usr/sbin/waagent") || Dir.exist?('C:\WindowsAzure')
      Ohai::Log.debug("Plugin Azure: Found waagent used by MS Azure.")
      return true
    end
  end

  def has_dhcp_option_245?
    has_245 = false
    if File.exist?("/var/lib/dhcp/dhclient.eth0.leases")
      File.open("/var/lib/dhcp/dhclient.eth0.leases").each do |line|
        if line =~ /unknown-245/
          Ohai::Log.debug("Plugin Azure: Found unknown-245 DHCP option used by MS Azure.")
          has_245 = true
          break
        end
      end
    end
    return has_245
  end

end
