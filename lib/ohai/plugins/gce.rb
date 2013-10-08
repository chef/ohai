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

provides "gce"

require 'ohai/mixin/gce_metadata'

# Checks for matching gce dmi
# https://developers.google.com/compute/docs/instances#dmi
#
# === Return
# true:: If gce dmi matches
# false:: Otherwise
GOOGLE_SYSFS_DMI = '/sys/firmware/dmi/entries/1-0/raw'
def has_google_dmi?
 ::File.read(GOOGLE_SYSFS_DMI).include?('Google')
end

# Checks for gce metadata server
#
# === Return
# true:: If gce metadata server found
# false:: Otherwise
def has_gce_metadata?
  Ohai::Mixin::GCEMetadata.can_metadata_connect?(Ohai::Mixin::GCEMetadata::GCE_METADATA_ADDR,80)
end

# Identifies gce
#
# === Return
# true:: If gce can be identified
# false:: Otherwise
def looks_like_gce?
  hint?('gce') || has_google_dmi? || has_gce_metadata?
end

# Adds the gce Mash
if looks_like_gce?
  Ohai::Log.debug("looks_like_gce? == true")
  gce Mash.new
  Ohai::Mixin::GCEMetadata.fetch_metadata.each {|k, v| gce[k] = v }
else
  Ohai::Log.debug("looks_like_gce? == false")
  false
end
