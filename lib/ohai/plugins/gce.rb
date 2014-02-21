#
# Author:: Ranjib Dey (<dey.ranjib@google.com>)
# Author:: Paul Rossman (<paulrossman@google.com>)
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

require 'ohai/mixin/dmi_signature'
require 'ohai/mixin/metadata_server'

extend Ohai::Mixin::DmiSignature
extend Ohai::Mixin::MetadataServer

GCE_METADATA_HOSTNAME = "metadata" unless defined?(GCE_METADATA_HOSTNAME)
GCE_METADATA_ADDR = "169.254.169.254" unless defined?(GCE_METADATA_ADDR)
GCE_METADATA_PORT = 80 unless defined?(GCE_METADATA_PORT)
GCE_METADATA_HEADERS = {'X-Google-Metadata-Request' => 'True'} unless defined?(GCE_METADATA_HEADERS)
GCE_METADATA_URL = "/computeMetadata/v1/?recursive=true" unless defined?(GCE_METADATA_URL)

# Checks for matching gce dmi
# https://developers.google.com/compute/docs/instances#dmi
#
# === Return
# true:: If gce dmi matches
# false:: Otherwise
def has_dmi?
  has_signature?('Google')
end

# Checks for gce metadata server
#
# === Return
# true:: If gce metadata server found
# false:: Otherwise
def has_metadata?
  server_available?(GCE_METADATA_ADDR, GCE_METADATA_PORT, GCE_METADATA_HEADERS)
end

# Identifies gce
# returns true because hint? returns contents if hint file is not empty
#
# === Return
# true:: If gce can be identified
# false:: Otherwise
def looks_like_gce?
  return true if hint?('gce') || has_dmi? || has_metadata?
end

# Adds the gce Mash
if looks_like_gce?
  Ohai::Log.debug("looks_like_gce? == true")
  gce Mash.new
  get_metadata(GCE_METADATA_ADDR, GCE_METADATA_PORT, GCE_METADATA_HEADERS, GCE_METADATA_URL).each {|k, v| gce[k] = v }
else
  Ohai::Log.debug("looks_like_gce? == false")
  false
end
