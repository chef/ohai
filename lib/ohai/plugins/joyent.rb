# 
# Author: sawanoboriyu@higanworks.com
# Copyright (C) 2013 HiganWorks LLC
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
#
#

# Reference from: sm-summary command

provides "joyent"
require_plugin "os"
require_plugin "platform"

if platform == "smartos" then
  joyent Mash.new

  # get uuid
  status, stdout, stderr  = run_command(:no_status_check => true, :command => "/usr/bin/zonename")
  joyent[:sm_uuid] = stdout.chomp

  # get zone id unless globalzone
  status, stdout, stderr  = run_command(:no_status_check => true, :command => "/usr/sbin/zoneadm list -p | awk -F: '{ print $1 }'")
  joyent[:sm_id] = stdout.chomp unless joyent[:sm_uuid] == "global"
  
  # retrieve image name and pkgsrc
  if ::File.exists?("/etc/product") then
    ::File.open("/etc/product") do |file|
      while line = file.gets
        case line
        when /^Image/
          sm_image = line.split(" ") 
          joyent[:sm_image_id] = sm_image[1]
          joyent[:sm_image_ver] = sm_image[2]
        when /^Base Image/
          sm_baseimage = line.split(" ")
          joyent[:sm_baseimage_id] = sm_baseimage[2]
          joyent[:sm_baseimage_ver] = sm_baseimage[3]
        end
      end
    end

    ## retrieve pkgsrc
    sm_pkgsrc = ::File.read("/opt/local/etc/pkg_install.conf").split("=")
    joyent[:sm_pkgsrc] = sm_pkgsrc[1].chomp
  end
end
