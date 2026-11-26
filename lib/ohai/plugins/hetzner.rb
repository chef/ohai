# frozen_string_literal: true
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# Copyright:: Copyright (c) 2026 Tim Smith
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

# How we detect Hetzner Cloud:
# 1. An Ohai hetzner hint exists.
# 2. The SMBIOS system vendor is "Hetzner" and the metadata service answers.
#    The probe keeps Hetzner hardware outside Hetzner Cloud from matching.

Ohai.plugin(:Hetzner) do
  require_relative "../mixin/hetzner_metadata"
  require_relative "../mixin/http_helper"
  require_relative "../mixin/smbios"

  include Ohai::Mixin::HetznerMetadata
  include Ohai::Mixin::HttpHelper
  include Ohai::Mixin::Smbios

  provides "hetzner"

  # Hetzner Cloud servers report "Hetzner" as the system and BIOS vendor and
  # "vServer" as the product name.
  # @return [Boolean] do we have Hetzner SMBIOS data?
  def has_hetzner_dmi?
    if smbios_value(:sys_vendor) == "Hetzner"
      logger.trace("Plugin Hetzner: has_hetzner_dmi? == true")
      true
    else
      logger.trace("Plugin Hetzner: has_hetzner_dmi? == false")
      false
    end
  end

  # @return [Boolean] Does the system appear to be on Hetzner Cloud?
  def looks_like_hetzner?
    return true if hint?("hetzner")

    has_hetzner_dmi? && can_socket_connect?(Ohai::Mixin::HetznerMetadata::HETZNER_METADATA_ADDR, 80)
  end

  collect_data do
    if looks_like_hetzner?
      logger.trace("Plugin Hetzner: looks_like_hetzner? == true")
      hetzner Mash.new
      begin
        fetch_metadata.each { |k, v| hetzner[k] = v }
      rescue => e
        # the server was identified as Hetzner Cloud above; keep the attribute
        logger.warn("Plugin Hetzner: Unable to fetch Hetzner metadata: #{e.class}: #{e.message}")
      end
    else
      logger.trace("Plugin Hetzner: looks_like_hetzner? == false")
      false
    end
  end
end
