#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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

Ohai.plugin(:CPU) do
  provides "cpu"

  collect_data(:linux) do
    cpuinfo = Mash.new
    real_cpu = Mash.new
    cpu_number = 0
    current_cpu = nil

    File.open("/proc/cpuinfo").each do |line|
      case line
      when /processor\s+:\s(.+)/
        cpuinfo[$1] = Mash.new
        current_cpu = $1
        cpu_number += 1
      when /vendor_id\s+:\s(.+)/
        vendor_id = $1
        if vendor_id =~ (/IBM\/S390/)
          cpuinfo["vendor_id"] = vendor_id
        else
          cpuinfo[current_cpu]["vendor_id"] = vendor_id
        end
      when /cpu family\s+:\s(.+)/
        cpuinfo[current_cpu]["family"] = $1
      when /model\s+:\s(.+)/
        cpuinfo[current_cpu]["model"] = $1
      when /stepping\s+:\s(.+)/
        cpuinfo[current_cpu]["stepping"] = $1
      when /physical id\s+:\s(.+)/
        cpuinfo[current_cpu]["physical_id"] = $1
        real_cpu[$1] = true
      when /core id\s+:\s(.+)/
        cpuinfo[current_cpu]["core_id"] = $1
      when /cpu cores\s+:\s(.+)/
        cpuinfo[current_cpu]["cores"] = $1
      when /model name\s+:\s(.+)/
        cpuinfo[current_cpu]["model_name"] = $1
      when /cpu MHz\s+:\s(.+)/
        cpuinfo[current_cpu]["mhz"] = $1
      when /cache size\s+:\s(.+)/
        cpuinfo[current_cpu]["cache_size"] = $1
      when /flags\s+:\s(.+)/
        cpuinfo[current_cpu]["flags"] = $1.split(" ")
      when /bogomips per cpu:\s(.+)/
        cpuinfo["bogomips_per_cpu"] = $1
      when /features\s+:\s(.+)/
        cpuinfo["features"] = $1.split(" ")
      when /processor\s(\d):\s(.+)/
        current_cpu = $1
        cpu_number += 1
        cpuinfo[current_cpu] = Mash.new
        current_cpu_info = $2.split(",")
        current_cpu_info.each do |i|
          name_value = i.split("=")
          name = name_value[0].strip
          value = name_value[1].strip
          cpuinfo[current_cpu][name] = value
        end
      end
    end

    cpu cpuinfo
    cpu[:total] = cpu_number
    cpu[:real] = real_cpu.keys.length
    cpu[:cores] = real_cpu.keys.length * cpu["0"]["cores"].to_i
  end
end
