#
# Author:: Dylan Page (<dpage@digitalocean.com>)
# Author:: Stafford Brunk (<stafford.brunk@gmail.com>)
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

Ohai.plugin(:DigitalOcean) do
  require_relative "../mixin/do_metadata"
  require_relative "../mixin/http_helper"

  include Ohai::Mixin::DOMetadata
  include Ohai::Mixin::HttpHelper

  provides "digital_ocean"

  depends "dmi"

  # look for digitalocean string in dmi bios data
  def has_do_dmi?
    begin
      # detect a vendor of "DigitalOcean"
      if dmi[:bios][:all_records][0][:Vendor] == "DigitalOcean"
        logger.trace("Plugin DigitalOcean: has_do_dmi? == true")
        return true
      end
    rescue NoMethodError
      # dmi[:bios][:all_records][0][:Vendor] may not exist
    end
    logger.trace("Plugin DigitalOcean: has_do_dmi? == false")
    false
  end

  def looks_like_digital_ocean?
    return true if hint?("digital_ocean")
    return true if has_do_dmi? && can_socket_connect?(Ohai::Mixin::DOMetadata::DO_METADATA_ADDR, 80)

    false
  end

  collect_data do
    if looks_like_digital_ocean?
      logger.trace("Plugin Digitalocean: looks_like_digital_ocean? == true")
      digital_ocean Mash.new
      fetch_metadata.each do |k, v|
        next if k == "vendor_data" # this may have sensitive data we shouldn't store

        digital_ocean[k] = v
      end
    else
      logger.trace("Plugin Digitalocean: No hints present for and doesn't look like digitalocean")
      false
    end
  end
end
