#
# Author:: Matt Ray (<matt@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

provides "openstack"

require 'json'

# Adds openstack Mash
if File.exists?("/etc/chef/ohai/hints/openstack.json")
  Ohai::Log.debug("ohai openstack")
  openstack Mash.new
  json = JSON.parse(File.read("/etc/chef/ohai/hints/openstack.json"))
  Ohai::Log.debug("ohai openstack: #{json}")
  if json['addresses']
    if json['addresses']['public']
      openstack[:public_ipv4] = json['addresses']['public'].last['addr']
    elsif json['addresses']['internet']
      openstack[:public_ipv4] = json['addresses']['internet'].last['addr']
    end
    Ohai::Log.debug("ohai openstack[:public_ipv4] #{openstack[:public_ipv4]}")
    if json['addresses']['private']
      openstack[:local_ipv4] = json['addresses']['private'].first['addr']
    elsif json['addresses']['internet']
      openstack[:local_ipv4] = json['addresses']['internet'].first['addr']
    end
    #revisit this for IPV6
    openstack[:public_ip] = openstack[:public_ipv4]
    openstack[:private_ip] = openstack[:local_ipv4]
    Ohai::Log.debug("ohai openstack[:local_ipv4] #{openstack[:local_ipv4]}")
  end
  # TODO: read from the metadata server, all sorts of useful data
  # http://169.254.169.254/latest/meta-data/
  openstack[:local_hostname] = hostname
else
  Ohai::Log.debug("NOT ohai openstack")
end

# rackspace:
#   local_hostname:   slice20897607
#   local_ipv4:       10.179.170.156
#   private_ip:       10.179.170.156
#   public_hostname:  198-101-206-185.static.cloud-ips.com
#   public_ip:        198.101.206.185
#   public_ipv4:      198.101.206.185

# ec2:
#   ami_id:                           ami-b4e545dd
#   ami_launch_index:                 0
#   ami_manifest_path:                ubuntu-us-east-1/images-testing/ubuntu-lucid-daily-i386-server-20120605.manifest.xml
#   block_device_mapping_ami:         sda1
#   block_device_mapping_ephemeral0:  sda2
#   block_device_mapping_root:        /dev/sda1
#   block_device_mapping_swap:        sda3
#   hostname:                         ip-10-88-197-134.ec2.internal
#   instance_id:                      i-b477b9cd
#   instance_type:                    m1.small
#   kernel_id:                        aki-407d9529
#   local_hostname:                   ip-10-88-197-134.ec2.internal
#   local_ipv4:                       10.88.197.134
#   placement_availability_zone:      us-east-1b
#   profile:                          default-paravirtual
#   public_hostname:                  ec2-23-20-197-171.compute-1.amazonaws.com
#   public_ipv4:                      23.20.197.171
#   public_keys_0_openssh_key:        ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCCBjIPCpIOvQYAqWQcYRWRswouvA+I96adoh24bmt/qfFUUl5eZYgyRH29KlDfCXQ3qaBKcnFxqCXdLOr+7kTHRhfeKXg+tBZ0udpIjXln9nEPo6mXI0v9nCrbvrpHk8A8cb9lD59oL8QIOW8zhr8Sx6KljsJBP3q7ZgVbmTjLCdrxt0JmCdzYFAtMVXEIR5cNamriFE3VZlegm6MWnVUZbKEpBS0BDGFKOEYOVfUOD0ZFJhuBLJ0oBc8dqctefiX62AGw5lNW2wq8Z8Houk9yEtfzXrRX5Zorqoknp1LGePuX0Vmc+h//FnMfQ7zAENg0SB5G8h0RjimlNWycPXLD mray
#   reservation_id:                   r-0036d165
#   security_groups:                  ["default"]
#   userdata:

# cloud:
#   local_hostname:   ip-10-88-197-134.ec2.internal
#   local_ipv4:       10.88.197.134
#   private_ips:      ["10.88.197.134"]
#   provider:         ec2
#   public_hostname:  ec2-23-20-197-171.compute-1.amazonaws.com
#   public_ips:       ["23.20.197.171"]
#   public_ipv4:      23.20.197.171
