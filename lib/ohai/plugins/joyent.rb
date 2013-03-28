#  Copyright (C) 2013 HiganWorks LLC                                                       
# 
#  Licensed under MIT https://github.com/higanworks/LICENSES
#  Author: sawanoboriyu@higanworks.com
#  Reference from: sm-summary command
#


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
