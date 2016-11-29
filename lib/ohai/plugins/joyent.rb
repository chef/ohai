#
# Author: sawanoboriyu@higanworks.com
# Copyright (C) 2014 HiganWorks LLC
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

Ohai.plugin(:Joyent) do
  provides "joyent"
  provides "virtualization/guest_id"
  depends "os", "platform", "virtualization"

  def collect_product_file
    data = ::File.read("/etc/product") rescue nil
    if data
      data.strip.split("\n")
    else
      []
    end
  end

  def collect_pkgsrc
    data = ::File.read("/opt/local/etc/pkg_install.conf") rescue nil
    if data
      /PKG_PATH=(.*)/.match(data)[1] rescue nil
    end
  end

  def is_smartos?
    platform == "smartos"
  end

  collect_data do
    if is_smartos?
      joyent Mash.new

      # copy uuid
      joyent[:sm_uuid] = virtualization[:guest_uuid]

      # get zone id unless globalzone
      unless joyent[:sm_uuid] == "global"
        joyent[:sm_id] = virtualization[:guest_id]
      end

      # retrieve image name and pkgsrc
      collect_product_file.each do |line|
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

      ## retrieve pkgsrc
      joyent[:sm_pkgsrc] = collect_pkgsrc
    end
  end
end
