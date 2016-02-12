#
# Author:: Alexey Karpik <alexey.karpik@rightscale.com>
# Author:: Peter Schroeter <peter.schroeter@rightscale.com>
# Author:: Stas Turlo <stanislav.turlo@rightscale.com>
# Copyright:: Copyright (c) 2010-2014 RightScale Inc
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

require "net/https"
require "uri"

# http://sldn.softlayer.com/reference/services/SoftLayer_Resource_Metadata
module ::Ohai::Mixin::SoftlayerMetadata
  SOFTLAYER_API_QUERY_URL = "https://api.service.softlayer.com/rest/v3.1/SoftLayer_Resource_Metadata" unless defined?(SOFTLAYER_API_QUERY_URL)

  def fetch_metadata
    metadata = {
      "public_fqdn"   => fetch_metadata_item("getFullyQualifiedDomainName.txt"),
      "local_ipv4"    => fetch_metadata_item("getPrimaryBackendIpAddress.txt"),
      "public_ipv4"   => fetch_metadata_item("getPrimaryIpAddress.txt"),
      "region"        => fetch_metadata_item("getDatacenter.txt"),
      "instance_id"   => fetch_metadata_item("getId.txt"),
    }
  end

  # Softlayer's metadata api is only available over HTTPS.
  # Ruby by default does not link to the system's CA bundle
  # however Chef-omnibus should set SSL_CERT_FILE to point to a valid file.
  # Manually supply and specify a suitable CA bundle here or
  # set the SSL_CERT_FILE file environment variable to a valid value otherwise.
  def ca_file_location
    ::Ohai::Config[:ca_file]
  end

  def fetch_metadata_item(item)
    full_url = "#{SOFTLAYER_API_QUERY_URL}/#{item}"
    u = URI(full_url)
    net = ::Net::HTTP.new(u.hostname, u.port)
    net.ssl_version = "TLSv1"
    net.use_ssl = true
    net.ca_file = ca_file_location
    res = net.get(u.request_uri)
    if res.code.to_i.between?(200, 299)
      res.body
    else
      ::Ohai::Log.error("Unable to fetch item #{full_url}: status (#{res.code}) body (#{res.body})")
      nil
    end
  rescue => e
    ::Ohai::Log.error("Unable to fetch softlayer metadata from #{u}: #{e.class}: #{e.message}")
    raise e
  end
end
