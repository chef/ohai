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

provides "cloud"

require_plugin "ec2"
require_plugin "gce"
require_plugin "rackspace"
require_plugin "eucalyptus"
require_plugin "linode"
require_plugin "openstack"
require_plugin "azure"

# Make top-level cloud hashes
#
def create_objects
  cloud Mash.new
  cloud[:public_ips] = Array.new
  cloud[:private_ips] = Array.new
end
#---------------------------------------
# Google Compute Engine (gce)
#--------------------------------------

def on_gce?
  gce != nil
end
def get_gce_values
  cloud[:public_ipv4] = []
  cloud[:local_ipv4] = []

  public_ips = gce['network']["networkInterface"].collect do |interface|
    if interface.has_key?('accessConfiguration')
      interface['accessConfiguration'].collect{|ac| ac['externalIp']}
    end
  end.flatten.compact

  private_ips = gce['network']["networkInterface"].collect do |interface|
    interface['ip']
  end.compact
  
  cloud[:public_ips] += public_ips
  cloud[:private_ips] += private_ips
  cloud[:public_ipv4] +=  public_ips
  cloud[:public_hostname] = nil
  cloud[:local_ipv4] += private_ips
  cloud[:local_hostname] = gce['hostname']
  cloud[:provider] = "gce"
end

# setup gce cloud
if on_gce?
  create_objects
  get_gce_values
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
  cloud[:public_ips] << ec2['public_ipv4']
  cloud[:private_ips] << ec2['local_ipv4']
  cloud[:public_ipv4] = ec2['public_ipv4']
  cloud[:public_hostname] = ec2['public_hostname']
  cloud[:local_ipv4] = ec2['local_ipv4']
  cloud[:local_hostname] = ec2['local_hostname']
  cloud[:provider] = "ec2"
end

# setup ec2 cloud
if on_ec2?
  create_objects
  get_ec2_values
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
  cloud[:public_ips] << rackspace['public_ipv4'] if rackspace['public_ipv4']
  cloud[:private_ips] << rackspace['local_ipv4'] if rackspace['local_ipv4']
  cloud[:public_ipv4] = rackspace['public_ipv4']
  cloud[:public_ipv6] = rackspace['public_ipv6']
  cloud[:public_hostname] = rackspace['public_hostname']
  cloud[:local_ipv4] = rackspace['local_ipv4']
  cloud[:local_ipv6] = rackspace['local_ipv6']
  cloud[:local_hostname] = rackspace['local_hostname']
  cloud[:provider] = "rackspace"
end

# setup rackspace cloud
if on_rackspace?
  create_objects
  get_rackspace_values
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
  cloud[:public_ips] << linode['public_ip']
  cloud[:private_ips] << linode['private_ip']
  cloud[:public_ipv4] = linode['public_ipv4']
  cloud[:public_hostname] = linode['public_hostname']
  cloud[:local_ipv4] = linode['local_ipv4']
  cloud[:local_hostname] = linode['local_hostname']
  cloud[:provider] = "linode"
end

# setup linode cloud data
if on_linode?
  create_objects
  get_linode_values
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
  cloud[:public_ips] << eucalyptus['public_ipv4']
  cloud[:private_ips] << eucalyptus['local_ipv4']
  cloud[:public_ipv4] = eucalyptus['public_ipv4']
  cloud[:public_hostname] = eucalyptus['public_hostname']
  cloud[:local_ipv4] = eucalyptus['local_ipv4']
  cloud[:local_hostname] = eucalyptus['local_hostname']
  cloud[:provider] = "eucalyptus"
end

if on_eucalyptus?
  create_objects
  get_eucalyptus_values
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
  cloud[:public_ips] << openstack['public_ipv4']
  cloud[:private_ips] << openstack['local_ipv4']
  cloud[:public_ipv4] = openstack['public_ipv4']
  cloud[:public_hostname] = openstack['public_hostname']
  cloud[:local_ipv4] = openstack['local_ipv4']
  cloud[:local_hostname] = openstack['local_hostname']
  cloud[:provider] = openstack['provider']
end

# setup openstack cloud
if on_openstack?
  create_objects
  get_openstack_values
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
  cloud[:vm_name] = azure["vm_name"]
  cloud[:public_ips] << azure['public_ip']
  cloud[:public_fqdn] = azure['public_fqdn']
  cloud[:public_ssh_port] = azure['public_ssh_port'] if azure['public_ssh_port']
  cloud[:public_winrm_port] = azure['public_winrm_port'] if azure['public_winrm_port']
  cloud[:provider] = "azure"
end

# setup azure cloud data
if on_azure?
  create_objects
  get_azure_values
end