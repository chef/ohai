#
# Author:: Cary Penniman (<cary@rightscale.com>)
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

require "ohai/mixin/rackspace_metadata"

Ohai.plugin(:Rackspace) do
  include ::Ohai::Mixin::RackspaceMetadata

  provides "rackspace"

  depends "kernel", "network/interfaces"

  # Checks for matching rackspace kernel name
  #
  # === Return
  # true:: If kernel name matches
  # false:: Otherwise
  def has_rackspace_kernel?
    kernel[:release].split('-').last.eql?("rscloud")
  end

  # Checks for rackspace provider attribute
  #
  # === Return
  # true:: If rackspace provider attribute found
  # false:: Otherwise
  def has_rackspace_metadata?
    status, stdout, stderr = xenstore_command("read", "vm-data/provider_data/provider")
    if status == 0
      stdout.strip.downcase == 'rackspace'
    else
      false
    end
  end

  # Identifies the rackspace cloud
  #
  # === Return
  # true:: If the rackspace cloud can be identified
  # false:: Otherwise
  def looks_like_rackspace?
    hint?('rackspace') || has_rackspace_metadata? || has_rackspace_kernel?
  end

  # Grab a list of rackspace interfaces from the xenstore. The interface definitions
  # are encoded using JSON.
  # Example for a public interface given below
  # {
  #     "broadcast": "162.209.6.255",
  #     "dns": [
  #         "173.203.4.9",
  #         "173.203.4.8"
  #     ],
  #     "gateway": "162.209.6.1",
  #     "gateway_v6": "fe80::def",
  #     "ip6s": [
  #         {
  #             "enabled": "1",
  #             "gateway": "fe80::def",
  #             "ip": "2001:4801:7819:74:be76:4eff:fe11:1553",
  #             "netmask": 64
  #         }
  #     ],
  #     "ips": [
  #         {
  #             "enabled": "1",
  #             "gateway": "162.209.6.1",
  #             "ip": "162.209.6.148",
  #             "netmask": "255.255.255.0"
  #         }
  #     ],
  #     "label": "public",
  #     "mac": "BC:76:4E:11:15:53"
  # }
  # Example for a private interface given below:
  # {
  #     "broadcast": "10.178.127.255",
  #     "dns": [
  #         "173.203.4.9",
  #         "173.203.4.8"
  #     ],
  #     "gateway": null,
  #     "ips": [
  #         {
  #             "enabled": "1",
  #             "gateway": null,
  #             "ip": "10.178.6.80",
  #             "netmask": "255.255.128.0"
  #         }
  #     ],
  #     "label": "private",
  #     "mac": "BC:76:4E:11:17:2E",
  #     "routes": [
  #         {
  #             "gateway": "10.178.0.1",
  #             "netmask": "255.240.0.0",
  #             "route": "10.208.0.0"
  #         },
  #         {
  #             "gateway": "10.178.0.1",
  #             "netmask": "255.240.0.0",
  #             "route": "10.176.0.0"
  #         }
  #     ]
  # }
  def get_rackspace_interfaces
    return @rackspace_interfaces if @rackspace_interfaces
    @rackspace_interfaces = []

    status, stdout, stderr = xenstore_command("ls", "vm-data/networking")
    if status == 0
      stdout.split("\n").each do |line|
        id = line.split.first
        status, stdout, stderr = xenstore_command("read", "vm-data/networking/#{id}")
        if status == 0
          begin
            interface = JSON.parse(stdout)
            @rackspace_interfaces << interface
          rescue Exception => e
            Ohai::Log.debug("Unable to parse Rackspace interface definition for #{id}: #{e.message} on (#{stdout})")
          end
        else
          Ohai::Log.debug("Unable to query xen-store for interface #{id}: #{status} (#{stderr})")
        end
      end
    else
      Ohai::Log.debug("Unable to query xen-store for list of interfaces: #{status} (#{stderr})")
    end
    @rackspace_interfaces
  end

  def cull_ips(ips)
    ips.map { |ip| ip["ip"] }
  end

  # Get the rackspace region
  #
  def get_region()
    status, stdout, stderr = xenstore_command("read", "vm-data/provider_data/region")
    if status == 0
      stdout.strip
    else
      Ohai::Log.debug("could not read region information for Rackspace cloud from xen-store")
      nil
    end
  end

  collect_data do
    # Adds rackspace Mash
    if looks_like_rackspace?
      rackspace Mash.new
      public_interfaces = get_rackspace_interfaces.select { |iface| iface["label"] == "public" }
      private_interfaces = get_rackspace_interfaces.select { |iface| iface["label"] == "private" }
      rackspace[:public_ips] = public_interfaces.map { |iface| cull_ips(iface["ips"]) }.flatten
      rackspace[:private_ips] = private_interfaces.map { |iface| cull_ips(iface["ips"]) }.flatten
      rackspace[:public_ipv6s] = public_interfaces.map { |iface| cull_ips(iface["ip6s"]) }.flatten

      rackspace[:public_ip] = rackspace[:public_ips].first
      rackspace[:private_ip] = rackspace[:private_ips].first
      rackspace[:public_ipv4] = rackspace[:public_ips].first
      rackspace[:public_ipv6] = rackspace[:public_ipv6s].first
      rackspace[:local_ipv4] = rackspace[:private_ips].first

      rackspace[:region] = get_region()

      # public_ip + private_ip are deprecated in favor of public_ipv4 and local_ipv4 to standardize.
      if rackspace[:public_ip]
        rackspace[:public_hostname] = "#{rackspace[:public_ip].gsub('.','-')}.static.cloud-ips.com"
      end
      rackspace[:local_hostname] = hostname
    end
  end
end
