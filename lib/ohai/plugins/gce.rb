#
# Author:: Ranjib Dey (<dey.ranjib@google.com>)
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

Ohai.plugin(:GCE) do
  require_relative "../mixin/gce_metadata"
  require_relative "../mixin/http_helper"

  include Ohai::Mixin::GCEMetadata
  include Ohai::Mixin::HttpHelper

  provides "gce"

  # look for GCE string in dmi vendor bios data within the sys tree.
  # this works even if the system lacks dmidecode use by the Dmi plugin
  # @return [Boolean] do we have Google Compute Engine DMI data?
  def has_gce_dmi?
    if file_val_if_exists("/sys/class/dmi/id/product_name") =~ /Google Compute Engine/
      logger.trace("Plugin GCE: has_gce_dmi? == true")
      true
    else
      logger.trace("Plugin GCE: has_gce_dmi? == false")
      false
    end
  end

  # return the contents of a file if the file exists
  # @param path[String] abs path to the file
  # @return [String] contents of the file if it exists
  def file_val_if_exists(path)
    if ::File.exist?(path)
      ::File.read(path)
    end
  end

  # looks at the Manufacturer and Model WMI values to see if they starts with Google.
  # @return [Boolean] Are the manufacturer and model Google?
  def has_gce_system_info?
    if RUBY_PLATFORM =~ /mswin|mingw32|windows/
      require "wmi-lite/wmi"
      wmi = WmiLite::Wmi.new
      computer_system = wmi.first_of("Win32_ComputerSystem")
      if computer_system["Manufacturer"] =~ /^Google/ && computer_system["Model"] =~ /^Google/
        logger.trace("Plugin GCE: has_gce_system_info? == true")
        return true
      end
    else
      logger.trace("Plugin GCE: has_gce_system_info? == false")
      false
    end
  end

  # Identifies gce
  #
  # === Return
  # true:: If gce can be identified
  # false:: Otherwise
  def looks_like_gce?
    return true if hint?("gce")

    if has_gce_dmi? || has_gce_system_info?
      return true if can_socket_connect?(Ohai::Mixin::GCEMetadata::GCE_METADATA_ADDR, 80)
    end
  end

  collect_data do
    if looks_like_gce?
      logger.trace("Plugin GCE: looks_like_gce? == true")
      gce Mash.new
      fetch_metadata.each { |k, v| gce[k] = v }
    else
      logger.trace("Plugin GCE: looks_like_gce? == false")
      false
    end
  end
end
