#
# Author:: Doug MacEachern <dougm@vmware.com>
# Copyright:: Copyright (c) 2010 VMware, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'ruby-wmi'

provides "cpu"

cpuinfo = Mash.new
cpu_number = 0
index = 0

WMI::Win32_Processor.find(:all).each do |processor|
  #
  # On Windows Server 2003 R2 (i.e. 5.2.*), numberofcores property 
  # doesn't exist on the Win32_Processor class unless the user has
  # patched their system with:
  # http://support.microsoft.com/kb/932370
  # 
  # We're returning nil for cpu["cores"] and cpu["count"]
  # when we don't see numberofcores property
  #

  number_of_cores = nil
  begin
    number_of_cores = processor.numberofcores
    cpu_number += number_of_cores
  rescue NoMethodError => e
    Ohai::Log.info("Can not find numberofcores property on Win32_Processor. Consider applying this patch: http://support.microsoft.com/kb/932370")
  end

  current_cpu = index.to_s
  index += 1
  cpuinfo[current_cpu] = Mash.new
  cpuinfo[current_cpu]["vendor_id"] = processor.manufacturer
  cpuinfo[current_cpu]["family"] = processor.family.to_s
  cpuinfo[current_cpu]["model"] = processor.revision.to_s
  cpuinfo[current_cpu]["stepping"] = processor.stepping
  cpuinfo[current_cpu]["physical_id"] = processor.deviceid
  #cpuinfo[current_cpu]["core_id"] = XXX
  cpuinfo[current_cpu]["cores"] = number_of_cores
  cpuinfo[current_cpu]["model_name"] = processor.description
  cpuinfo[current_cpu]["mhz"] = processor.maxclockspeed.to_s
  cpuinfo[current_cpu]["cache_size"] = "#{processor.l2cachesize} KB"
  #cpuinfo[current_cpu]["flags"] = XXX
end

cpu cpuinfo
cpu[:total] = (cpu_number == 0) ? nil : cpu_number
cpu[:real] = index
