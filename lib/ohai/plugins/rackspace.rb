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

require "resolv"

Ohai.plugin(:Rackspace) do
  provides "rackspace"

  depends "kernel", "network/interfaces"

  # Checks for matching rackspace kernel name
  #
  # === Return
  # true:: If kernel name matches
  # false:: Otherwise
  def has_rackspace_kernel?
    kernel[:release].split("-").last.eql?("rscloud")
  end

  # Checks for rackspace provider attribute
  #
  # === Return
  # true:: If rackspace provider attribute found
  # false:: Otherwise
  def has_rackspace_metadata?
    so = shell_out("xenstore-read vm-data/provider_data/provider")
    if so.exitstatus == 0
      so.stdout.strip.casecmp("rackspace") == 0
    end
  rescue Ohai::Exceptions::Exec
    false
  end

  # Identifies the rackspace cloud
  #
  # === Return
  # true:: If the rackspace cloud can be identified
  # false:: Otherwise
  def looks_like_rackspace?
    hint?("rackspace") || has_rackspace_metadata? || has_rackspace_kernel?
  end

  # Names rackspace ip address
  #
  # === Parameters
  # name<Symbol>:: Use :public_ip or :private_ip
  # eth<Symbol>:: Interface name of public or private ip
  def get_ip_address(name, eth)
    network[:interfaces][eth][:addresses].each do |key, info|
      if info["family"] == "inet"
        rackspace[name] = key
        break # break when we found an address
      end
    end
  end

  # Names rackspace ipv6 address for interface
  #
  # === Parameters
  # name<Symbol>:: Use :public_ip or :private_ip
  # eth<Symbol>:: Interface name of public or private ip
  def get_global_ipv6_address(name, eth)
    network[:interfaces][eth][:addresses].each do |key, info|
      # check if we got an ipv6 address and if its in global scope
      if info["family"] == "inet6" && info["scope"] == "Global"
        rackspace[name] = key
        break # break when we found an address
      end
    end
  end

  # Get the rackspace region
  #
  def get_region
    so = shell_out("xenstore-ls vm-data/provider_data")
    if so.exitstatus == 0
      so.stdout.split("\n").each do |line|
        rackspace[:region] = line.split[2].delete('\"') if line =~ /^region/
      end
    end
  rescue Ohai::Exceptions::Exec
    Ohai::Log.debug("rackspace plugin: Unable to find xenstore-ls, cannot capture region information for Rackspace cloud")
    nil
  end

  # Get the rackspace instance_id
  #
  def get_instance_id
    so = shell_out("xenstore-read name")
    if so.exitstatus == 0
      rackspace[:instance_id] = so.stdout.gsub(/instance-/, "")
    end
  rescue Ohai::Exceptions::Exec
    Ohai::Log.debug("rackspace plugin: Unable to find xenstore-read, cannot capture instance ID information for Rackspace cloud")
    nil
  end

  # Get the rackspace private networks
  #
  def get_private_networks
    so = shell_out("xenstore-ls vm-data/networking")
    if so.exitstatus == 0
      networks = []
      so.stdout.split("\n").map { |l| l.split("=").first.strip }.map do |item|
        so = shell_out("xenstore-read vm-data/networking/#{item}")
        if so.exitstatus == 0
          networks.push(FFI_Yajl::Parser.new.parse(so.stdout))
        else
          Ohai::Log.debug("rackspace plugin: Unable to capture custom private networking information for Rackspace cloud")
          return false
        end
      end
      # these networks are already known to ohai, and are not 'private networks'
      networks.delete_if { |hash| hash["label"] == "private" }
      networks.delete_if { |hash| hash["label"] == "public" }
    end
  rescue Ohai::Exceptions::Exec
    Ohai::Log.debug("rackspace plugin: Unable to capture custom private networking information for Rackspace cloud")
    nil
  end

  collect_data do
    # Adds rackspace Mash
    if looks_like_rackspace?
      rackspace Mash.new
      get_ip_address(:public_ip, :eth0)
      get_ip_address(:private_ip, :eth1)
      get_region()
      get_instance_id()
      # public_ip + private_ip are deprecated in favor of public_ipv4 and local_ipv4 to standardize.
      rackspace[:public_ipv4] = rackspace[:public_ip]
      get_global_ipv6_address(:public_ipv6, :eth0)
      unless rackspace[:public_ip].nil?
        rackspace[:public_hostname] = begin
                                        Resolv.getname(rackspace[:public_ip])
                                      rescue Resolv::ResolvError, Resolv::ResolvTimeout
                                        rackspace[:public_ip]
                                      end
      end
      rackspace[:local_ipv4] = rackspace[:private_ip]
      get_global_ipv6_address(:local_ipv6, :eth1)
      rackspace[:local_hostname] = hostname
      private_networks = get_private_networks
      rackspace[:private_networks] = private_networks if private_networks
    end
  end

end
