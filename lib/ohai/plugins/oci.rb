# frozen_string_literal: true

#
# Author:: Renato Covarrubias (<rnt@rnt.cl>)
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

Ohai.plugin(:Oci) do
  require_relative "../mixin/oci_metadata"
  require_relative "../mixin/http_helper"

  include Ohai::Mixin::OCIMetadata
  include Ohai::Mixin::HttpHelper

  provides "oci"

  collect_data do
    oci_metadata_from_hints = hint?("oci")
    if oci_metadata_from_hints
      logger.trace("Plugin OCI: oci hint is present. Parsing any hint data.")
      oci Mash.new
      oci_metadata_from_hints.each { |k, v| oci[k] = v }
      oci["metadata"] = parse_metadata
    elsif oci_chassis_asset_tag?
      logger.trace("Plugin oci: No hints present, but system appears to be on oci.")
      oci Mash.new
      oci["metadata"] = parse_metadata
    else
      logger.trace("Plugin oci: No hints present and doesn't appear to be on oci.")
      false
    end
  end

  def oci_chassis_asset_tag?
    has_oci_chassis_asset_tag = false
    if file_exist?(Ohai::Mixin::OCIMetadata::CHASSIS_ASSET_TAG_FILE)
      file_open(Ohai::Mixin::OCIMetadata::CHASSIS_ASSET_TAG_FILE).each do |line|
        next unless /OracleCloud.com/.match?(line)

        logger.trace("Plugin oci: Found OracleCloud.com chassis_asset_tag used by oci.")
        has_oci_chassis_asset_tag = true
        break
      end
    end
    has_oci_chassis_asset_tag
  end

  def parse_metadata
    return nil unless can_socket_connect?(Ohai::Mixin::OCIMetadata::OCI_METADATA_ADDR, 80)

    instance_data = fetch_metadata("instance")
    return nil if instance_data.nil?

    metadata = Mash.new
    metadata["compute"] = Mash.new

    instance_data.each do |k, v|
      metadata["compute"][k] = v
    end

    vnics_data = fetch_metadata("vnics")

    unless vnics_data.nil?
      metadata["network"] = Mash.new
      metadata["network"]["interface"] = []
      vnics_data.each do |v|
        metadata["network"]["interface"].append(v)
      end
    end

    volume_attachments_data = fetch_metadata("volumeAttachments")

    unless volume_attachments_data.nil?
      metadata["volumes"] = Mash.new
      volume_attachments_data.each do |k, v|
        metadata["volumes"][k] = v
      end
    end

    metadata
  end
end
