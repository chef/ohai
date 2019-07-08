#
# Author:: Jonathan Amiez (<jonathan.amiez@gmail.com>)
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

Ohai.plugin(:Scaleway) do
  require_relative "../mixin/scaleway_metadata"
  require_relative "../mixin/http_helper"

  include Ohai::Mixin::ScalewayMetadata
  include Ohai::Mixin::HttpHelper

  provides "scaleway"

  # looks for `scaleway` keyword in kernel command line
  # @return [Boolean] do we have the keyword or not?
  def has_scaleway_cmdline?
    if ::File.read("/proc/cmdline") =~ /scaleway/
      logger.trace("Plugin Scaleway: has_scaleway_cmdline? == true")
      return true
    end
    logger.trace("Plugin Scaleway: has_scaleway_cmdline? == false")
    false
  end

  # a single check that combines all the various detection methods for Scaleway
  # @return [Boolean] Does the system appear to be on Scaleway
  def looks_like_scaleway?
    return true if hint?("scaleway")
    return true if has_scaleway_cmdline? && can_socket_connect?(Ohai::Mixin::ScalewayMetadata::SCALEWAY_METADATA_ADDR, 80)

    false
  end

  collect_data do
    if looks_like_scaleway?
      logger.trace("Plugin Scaleway: looks_like_scaleway? == true")
      scaleway Mash.new
      fetch_metadata.each do |k, v|
        scaleway[k] = v
      end
    else
      logger.trace("Plugin Scaleway: No hints present for and doesn't look like scaleway")
    end
  end
end
