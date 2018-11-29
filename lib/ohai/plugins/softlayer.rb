#
# Author:: Alexey Karpik <alexey.karpik@rightscale.com>
# Author:: Peter Schroeter <peter.schroeter@rightscale.com>
# Author:: Stas Turlo <stanislav.turlo@rightscale.com>
# Copyright:: Copyright (c) 2010-2014 RightScale Inc
# Copyright:: Copyright (c) 2018 Chef Software, Inc.
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Ohai.plugin(:Softlayer) do
  require "ohai/mixin/softlayer_metadata"
  include ::Ohai::Mixin::SoftlayerMetadata

  provides "softlayer"
  depends "dmi"

  # Identifies the softlayer cloud
  #
  # @return [Boolean] true if the system appears to be softlayer
  def looks_like_softlayer?
    hint?("softlayer") || softlayer_dmi?
  end

  # Does this system have softlayer dmi?
  #
  # @return [Boolean] true if the system has a Softlayer asset tag in DMI data
  def softlayer_dmi?
    get_attribute(:dmi, :chassis, :asset_tag) =~ /Softlayer/
  end

  collect_data do
    # Adds softlayer Mash
    if looks_like_softlayer?
      logger.trace("Plugin Softlayer: looks_like_softlayer? == true")
      metadata = fetch_metadata
      softlayer Mash.new
      metadata.each { |k, v| softlayer[k] = v } if metadata
    else
      logger.trace("Plugin Softlayer: looks_like_softlayer? == false")
    end
  end
end
