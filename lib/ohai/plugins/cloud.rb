# frozen_string_literal: true
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

Ohai.plugin(:Cloud) do
  provides "cloud"

  depends "alibaba"
  depends "ec2"
  depends "gce"
  depends "rackspace"
  depends "eucalyptus"
  depends "linode"
  depends "openstack"
  depends "azure"
  depends "digital_ocean"
  depends "softlayer"
  depends "oci"
  depends "scaleway"

  # Class to help enforce the interface exposed to node[:cloud] (OHAI-542)
  #
  # cloud[:provider] - (String) the cloud provider the VM is running on.
  #
  # cloud[:public_hostname] - (String) a fully qualified hostname
  # cloud[:local_hostname] - (String) a hostname resolvable on the internal (private) network
  #
  # cloud[:public_ipv4_addrs] - (Array) a list of all publicly accessible IPv4 addresses
  # cloud[:local_ipv4_addrs] - (Array) a list of all private IPv4 addresses
  # cloud[:public_ipv4] - (String) the first public IPv4 address detected
  # cloud[:local_ipv4] - (String) the first private IPv4 address detected
  #
  # cloud[:public_ipv6_addrs] - (Array) a list of all publicly accessible IPv6 addresses
  # cloud[:local_ipv6_addrs] - (Array) a list of all private IPv6 addresses
  # cloud[:public_ipv6] - (String) the first public IPv6 address detected
  # cloud[:local_ipv6] - (String) the first private IPv6 address detected
  #
  class CloudAttrs
    attr_writer :provider, :public_hostname, :local_hostname

    def initialize
      @cloud = Mash.new
    end

    def add_ipv4_addr(ip, accessibility)
      ipaddr = validate_ip_addr(ip, :ipv4)
      return if ipaddr.nil?

      case accessibility
      when :public
        @cloud[:public_ipv4_addrs] ||= []
        @cloud[:public_ipv4_addrs] << ipaddr.to_s
      when :private
        @cloud[:local_ipv4_addrs] ||= []
        @cloud[:local_ipv4_addrs] << ipaddr.to_s
      else
        raise "ERROR: invalid accessibility param of '#{accessibility}'. must be :public or :private."
      end
    end

    def add_ipv6_addr(ip, accessibility)
      ipaddr = validate_ip_addr(ip, :ipv6)
      return if ipaddr.nil?

      case accessibility
      when :public
        @cloud[:public_ipv6_addrs] ||= []
        @cloud[:public_ipv6_addrs] << ipaddr.to_s
      when :private
        @cloud[:local_ipv6_addrs] ||= []
        @cloud[:local_ipv6_addrs] << ipaddr.to_s
      else
        raise "ERROR: invalid accessibility param of '#{accessibility}'. must be :public or :private."
      end
    end

    def cloud_mash
      @cloud[:provider] = @provider if @provider

      # metadata services return an empty string for a hostname that isn't
      # assigned (EC2 without DNS hostnames in the VPC, for example)
      @cloud[:public_hostname] = @public_hostname unless @public_hostname.to_s.strip.empty?
      @cloud[:local_hostname] = @local_hostname unless @local_hostname.to_s.strip.empty?

      @cloud[:public_ipv4] = @cloud[:public_ipv4_addrs][0] if @cloud[:public_ipv4_addrs]
      @cloud[:local_ipv4] = @cloud[:local_ipv4_addrs][0] if @cloud[:local_ipv4_addrs]

      @cloud[:public_ipv6] = @cloud[:public_ipv6_addrs][0] if @cloud[:public_ipv6_addrs]
      @cloud[:local_ipv6] = @cloud[:local_ipv6_addrs][0] if @cloud[:local_ipv6_addrs]

      # if empty, return nil
      @cloud.empty? ? nil : @cloud
    end

    private

    # Returns the parsed address, or nil for a blank or invalid one. Metadata
    # services return empty strings for addresses that aren't assigned, and one
    # bad value shouldn't cost the node its whole cloud attribute.
    def validate_ip_addr(ip, address_family = :ipv4)
      return nil if ip.nil? || ip.to_s.strip.empty?

      ipaddr = IPAddr.new(ip.to_s.strip)
      raise ArgumentError, "not a valid #{address_family} address" unless address_family == :ipv4 ? ipaddr.ipv4? : ipaddr.ipv6?

      ipaddr
    rescue ArgumentError => e
      Ohai::Log.warn("Plugin Cloud: Ignoring IP address '#{ip}': #{e.message}")
      nil
    end
  end

  #--------------------------------------
  # Alibaba Cloud
  #--------------------------------------

  def on_alibaba?
    alibaba != nil
  end

  def get_alibaba_values
    meta_data = alibaba["meta_data"] || {}
    # eipv4 is only set when an Elastic IP is bound; otherwise the instance's
    # own public address is in public_ipv4
    @cloud_attr_obj.add_ipv4_addr(meta_data["eipv4"] || meta_data["public_ipv4"], :public)
    @cloud_attr_obj.add_ipv4_addr(meta_data["private_ipv4"], :private)
    @cloud_attr_obj.local_hostname = meta_data["hostname"]
    @cloud_attr_obj.provider = "alibaba"
  end

  #--------------------------------------
  # Google Compute Engine (gce)
  #--------------------------------------

  def on_gce?
    gce != nil
  end

  def get_gce_values
    instance = gce["instance"] || {}
    interfaces = Array(instance["networkInterfaces"])

    interfaces.each do |interface|
      Array(interface["accessConfigs"]).each { |ac| @cloud_attr_obj.add_ipv4_addr(ac["externalIp"], :public) }
    end
    interfaces.each { |interface| @cloud_attr_obj.add_ipv4_addr(interface["ip"], :private) }
    @cloud_attr_obj.local_hostname = instance["hostname"]
    @cloud_attr_obj.provider = "gce"
  end

  # ----------------------------------------
  # ec2
  # ----------------------------------------

  # Is current cloud ec2?
  #
  # === Return
  # true:: If ec2 Hash is defined
  # false:: Otherwise
  def on_ec2?
    ec2 != nil
  end

  # Fill cloud hash with ec2 values
  def get_ec2_values
    @cloud_attr_obj.add_ipv4_addr(ec2["public_ipv4"], :public)
    @cloud_attr_obj.add_ipv4_addr(ec2["local_ipv4"], :private)
    @cloud_attr_obj.public_hostname = ec2["public_hostname"]
    @cloud_attr_obj.local_hostname = ec2["local_hostname"]
    @cloud_attr_obj.provider = "ec2"
  end

  # ----------------------------------------
  # rackspace
  # ----------------------------------------

  # Is current cloud rackspace?
  #
  # === Return
  # true:: If rackspace Hash is defined
  # false:: Otherwise
  def on_rackspace?
    rackspace != nil
  end

  # Fill cloud hash with rackspace values
  def get_rackspace_values
    @cloud_attr_obj.add_ipv4_addr(rackspace["public_ipv4"], :public)
    @cloud_attr_obj.add_ipv4_addr(rackspace["local_ipv4"], :private)
    @cloud_attr_obj.add_ipv6_addr(rackspace["public_ipv6"], :public)
    @cloud_attr_obj.add_ipv6_addr(rackspace["local_ipv6"], :private)
    @cloud_attr_obj.public_hostname = rackspace["public_hostname"]
    @cloud_attr_obj.local_hostname = rackspace["local_hostname"]
    @cloud_attr_obj.provider = "rackspace"
  end

  # ----------------------------------------
  # linode
  # ----------------------------------------

  # Is current cloud linode?
  #
  # === Return
  # true:: If linode Hash is defined
  # false:: Otherwise
  def on_linode?
    linode != nil
  end

  # Fill cloud hash with linode values
  def get_linode_values
    @cloud_attr_obj.add_ipv4_addr(linode["public_ip"], :public)
    @cloud_attr_obj.add_ipv4_addr(linode["private_ip"], :private)
    @cloud_attr_obj.public_hostname = linode["public_hostname"]
    @cloud_attr_obj.local_hostname = linode["local_hostname"]
    @cloud_attr_obj.provider = "linode"
  end

  # ----------------------------------------
  # eucalyptus
  # ----------------------------------------

  # Is current cloud eucalyptus?
  #
  # === Return
  # true:: If eucalyptus Hash is defined
  # false:: Otherwise
  def on_eucalyptus?
    eucalyptus != nil
  end

  def get_eucalyptus_values
    @cloud_attr_obj.add_ipv4_addr(eucalyptus["public_ipv4"], :public)
    @cloud_attr_obj.add_ipv4_addr(eucalyptus["local_ipv4"], :private)
    @cloud_attr_obj.public_hostname = eucalyptus["public_hostname"]
    @cloud_attr_obj.local_hostname = eucalyptus["local_hostname"]
    @cloud_attr_obj.provider = "eucalyptus"
  end

  # ----------------------------------------
  # openstack
  # ----------------------------------------

  # Is current cloud openstack-based?
  #
  # === Return
  # true:: If openstack Hash is defined
  # false:: Otherwise
  def on_openstack?
    openstack != nil
  end

  # Fill cloud hash with openstack values
  def get_openstack_values
    @cloud_attr_obj.add_ipv4_addr(openstack["public_ipv4"], :public)
    @cloud_attr_obj.add_ipv4_addr(openstack["local_ipv4"], :private)
    @cloud_attr_obj.public_hostname = openstack["public_hostname"]
    @cloud_attr_obj.local_hostname = openstack["local_hostname"]
    @cloud_attr_obj.provider = openstack["provider"]
  end

  # ----------------------------------------
  # azure
  # ----------------------------------------

  # Is current cloud azure?
  #
  # === Return
  # true:: If azure Hash is defined
  # false:: Otherwise
  def on_azure?
    azure != nil
  end

  # Fill cloud hash with azure values
  def get_azure_values
    # metadata is nil when the metadata endpoint was unreachable, and network
    # is absent when the endpoint didn't return it
    network = azure.dig("metadata", "network") || {}
    Array(network["public_ipv4"]).each { |ipaddr| @cloud_attr_obj.add_ipv4_addr(ipaddr, :public) }
    Array(network["public_ipv6"]).each { |ipaddr| @cloud_attr_obj.add_ipv6_addr(ipaddr, :public) }
    Array(network["local_ipv4"]).each { |ipaddr| @cloud_attr_obj.add_ipv4_addr(ipaddr, :private) }
    Array(network["local_ipv6"]).each { |ipaddr| @cloud_attr_obj.add_ipv6_addr(ipaddr, :private) }
    @cloud_attr_obj.public_hostname = azure["public_fqdn"]
    @cloud_attr_obj.provider = "azure"
  end

  # ----------------------------------------
  # digital_ocean
  # ----------------------------------------

  # Is current cloud digital_ocean?
  #
  # === Return
  # true:: If digital_ocean Mash is defined
  # false:: Otherwise
  def on_digital_ocean?
    digital_ocean != nil
  end

  # Fill cloud hash with digital_ocean values
  def get_digital_ocean_values
    @cloud_attr_obj.add_ipv4_addr(digital_ocean["interfaces"]["public"][0]["ipv4"]["ip_address"], :public) rescue NoMethodError
    @cloud_attr_obj.add_ipv4_addr(digital_ocean["interfaces"]["private"][0]["ipv4"]["ip_address"], :private) rescue NoMethodError
    @cloud_attr_obj.add_ipv6_addr(digital_ocean["interfaces"]["public"][0]["ipv6"]["ip_address"], :public) rescue NoMethodError
    @cloud_attr_obj.add_ipv6_addr(digital_ocean["interfaces"]["private"][0]["ipv6"]["ip_address"], :private) rescue NoMethodError
    @cloud_attr_obj.local_hostname = digital_ocean["hostname"]
    @cloud_attr_obj.provider = "digital_ocean"
  end

  # ----------------------------------------
  # softlayer
  # ----------------------------------------

  # Is current cloud softlayer?
  #
  # === Return
  # true:: If softlayer Hash is defined
  # false:: Otherwise
  def on_softlayer?
    softlayer != nil
  end

  # Fill cloud hash with softlayer values
  def get_softlayer_values
    @cloud_attr_obj.add_ipv4_addr(softlayer["public_ipv4"], :public)
    @cloud_attr_obj.add_ipv4_addr(softlayer["local_ipv4"], :private)
    @cloud_attr_obj.public_hostname = softlayer["public_fqdn"]
    @cloud_attr_obj.provider = "softlayer"
  end

  # ----------------------------------------
  # OCI
  # ----------------------------------------

  # Is current Oracle Cloud Infrastructure?
  #
  # === Return
  # true:: If oci Hash is defined
  # false:: Otherwise
  def on_oci?
    oci != nil
  end

  # Fill cloud hash with OCI values
  def oci_values
    Array(oci.dig("metadata", "network", "interface")).each { |vnic| @cloud_attr_obj.add_ipv4_addr(vnic["privateIp"], :private) }
    @cloud_attr_obj.local_hostname = oci.dig("metadata", "compute", "hostname")
    @cloud_attr_obj.provider = "oci"
  end

  # ----------------------------------------
  # scaleway
  # ----------------------------------------

  # Is current cloud scaleway?
  #
  # === Return
  # true:: If scaleway Hash is defined
  # false:: Otherwise
  def on_scaleway?
    scaleway != nil
  end

  # Fill cloud hash with scaleway values
  def get_scaleway_values
    @cloud_attr_obj.add_ipv4_addr(scaleway.dig("public_ip", "address"), :public)
    @cloud_attr_obj.add_ipv4_addr(scaleway["private_ip"], :private)
    @cloud_attr_obj.add_ipv6_addr(scaleway.dig("ipv6", "address"), :public)
    @cloud_attr_obj.local_hostname = scaleway["hostname"]
    @cloud_attr_obj.provider = "scaleway"
  end

  # Runs one provider's getter. Provider data comes from metadata services
  # that can return partial or unexpected data, and an exception here would
  # otherwise drop the whole cloud attribute, including other providers' data.
  def collect_provider_values(provider)
    yield
  rescue => e
    logger.warn("Plugin Cloud: Unable to collect #{provider} values: #{e.class}: #{e.message}")
  end

  collect_data do
    require "ipaddr" unless defined?(IPAddr)

    @cloud_attr_obj = CloudAttrs.new

    collect_provider_values("gce") { get_gce_values } if on_gce?
    collect_provider_values("ec2") { get_ec2_values } if on_ec2?
    collect_provider_values("rackspace") { get_rackspace_values } if on_rackspace?
    collect_provider_values("linode") { get_linode_values } if on_linode?
    collect_provider_values("eucalyptus") { get_eucalyptus_values } if on_eucalyptus?
    collect_provider_values("openstack") { get_openstack_values } if on_openstack?
    collect_provider_values("azure") { get_azure_values } if on_azure?
    collect_provider_values("digital_ocean") { get_digital_ocean_values } if on_digital_ocean?
    collect_provider_values("softlayer") { get_softlayer_values } if on_softlayer?
    collect_provider_values("alibaba") { get_alibaba_values } if on_alibaba?
    collect_provider_values("oci") { oci_values } if on_oci?
    collect_provider_values("scaleway") { get_scaleway_values } if on_scaleway?

    cloud @cloud_attr_obj.cloud_mash
  end
end
