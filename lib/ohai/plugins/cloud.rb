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
      return if ip.nil? # just skip if ip is nil

      ipaddr = validate_ip_addr(ip, :ipv4)

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
      return if ip.nil? # just skip if ip is nil

      ipaddr = validate_ip_addr(ip, :ipv6)

      raise "ERROR: invalid ipv6 address of '#{ip}' detected. " unless ipaddr.ipv6?

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

      @cloud[:public_hostname] = @public_hostname if @public_hostname
      @cloud[:local_hostname] = @local_hostname if @local_hostname

      @cloud[:public_ipv4] = @cloud[:public_ipv4_addrs][0] if @cloud[:public_ipv4_addrs]
      @cloud[:local_ipv4] = @cloud[:local_ipv4_addrs][0] if @cloud[:local_ipv4_addrs]

      @cloud[:public_ipv6] = @cloud[:public_ipv6_addrs][0] if @cloud[:public_ipv6_addrs]
      @cloud[:local_ipv6] = @cloud[:local_ipv6_addrs][0] if @cloud[:local_ipv6_addrs]

      # if empty, return nil
      @cloud.empty? ? nil : @cloud
    end

    private

    def validate_ip_addr(ip, address_family = :ipv4)
      ipaddr = ""
      begin
        ipaddr = IPAddr.new(ip)
        raise ArgumentError, "not valid #{address_family} address" unless address_family == :ipv4 ? ipaddr.ipv4? : ipaddr.ipv6?
      rescue ArgumentError => e
        raise "ERROR: the ohai 'cloud' plugin failed with an IP address of '#{ip}' : #{e.message}"
      end
      ipaddr
    end
  end

  #--------------------------------------
  # Alibaba Cloud
  #--------------------------------------

  def on_alibaba?
    alibaba != nil
  end

  def get_alibaba_values
    @cloud_attr_obj.add_ipv4_addr(alibaba["meta_data"]["eipv4"], :public)
    @cloud_attr_obj.add_ipv4_addr(alibaba["meta_data"]["private_ipv4"], :private)
    @cloud_attr_obj.local_hostname = alibaba["meta_data"]["hostname"]
    @cloud_attr_obj.provider = "alibaba"
  end

  #--------------------------------------
  # Google Compute Engine (gce)
  #--------------------------------------

  def on_gce?
    gce != nil
  end

  def get_gce_values
    public_ips = gce["instance"]["networkInterfaces"].collect do |interface|
      if interface.key?("accessConfigs")
        interface["accessConfigs"].collect { |ac| ac["externalIp"] unless ac["externalIp"] == "" }
      end
    end.flatten.compact

    private_ips = gce["instance"]["networkInterfaces"].filter_map do |interface|
      interface["ip"]
    end

    public_ips.each { |ipaddr| @cloud_attr_obj.add_ipv4_addr(ipaddr, :public) }
    private_ips.each { |ipaddr| @cloud_attr_obj.add_ipv4_addr(ipaddr, :private) }
    @cloud_attr_obj.local_hostname = gce["instance"]["hostname"]
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
    azure["metadata"]["network"]["public_ipv4"].each { |ipaddr| @cloud_attr_obj.add_ipv4_addr(ipaddr, :public) }
    azure["metadata"]["network"]["public_ipv6"].each { |ipaddr| @cloud_attr_obj.add_ipv6_addr(ipaddr, :public) }
    azure["metadata"]["network"]["local_ipv4"].each { |ipaddr| @cloud_attr_obj.add_ipv4_addr(ipaddr, :private) }
    azure["metadata"]["network"]["local_ipv6"].each { |ipaddr| @cloud_attr_obj.add_ipv6_addr(ipaddr, :private) }
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
    oci["metadata"]["network"]["interface"].each { |vnic| @cloud_attr_obj.add_ipv4_addr(vnic["privateIp"], :private) }
    @cloud_attr_obj.local_hostname = oci["metadata"]["compute"]["hostname"]
    @cloud_attr_obj.provider = "oci"
  end

  collect_data do
    require "ipaddr" unless defined?(IPAddr)

    @cloud_attr_obj = CloudAttrs.new

    get_gce_values if on_gce?
    get_ec2_values if on_ec2?
    get_rackspace_values if on_rackspace?
    get_linode_values if on_linode?
    get_eucalyptus_values if on_eucalyptus?
    get_openstack_values if on_openstack?
    get_azure_values if on_azure?
    get_digital_ocean_values if on_digital_ocean?
    get_softlayer_values if on_softlayer?
    get_alibaba_values if on_alibaba?
    oci_values if on_oci?

    cloud @cloud_attr_obj.cloud_mash
  end
end
