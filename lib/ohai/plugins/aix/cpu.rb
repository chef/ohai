#
# Author:: Joshua Timberman <joshua@chef.io>
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Author:: Isa Farnik (<isa@chef.io>)
# Copyright:: Copyright (c) 2013-2016 Chef Software, Inc.
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

  collect_data(:aix) do
    cpu Mash.new

    cpu[:total] = shell_out("pmcycles -m").stdout.lines.length

    # The below is only relevent on an LPAR
    if shell_out("uname -W").stdout.strip == "0"

      # At least one CPU will be available, but we'll wait to increment this later.
      cpu[:available] = 0

      cpudevs = shell_out("lsdev -Cc processor").stdout.lines
      #from http://www-01.ibm.com/software/passportadvantage/pvu_terminology_for_customers.html
      #on AIX number of cores and processors are considered same
      cpu[:real] = cpu[:cores] = cpudevs.length
      cpudevs.each.with_index do |c, i|
        name, status, location = c.split
        index = i.to_s
        cpu[index] = Mash.new
        cpu[index][:status] = status
        cpu[index][:location] = location
        if status =~ /Available/
          cpu[:available] += 1
          lsattr = shell_out("lsattr -El #{name}").stdout.lines
          lsattr.each do |attribute|
            attrib, value = attribute.split
            if attrib == "type"
              cpu[index][:model_name] = value
            elsif attrib == "frequency"
              cpu[index][:mhz] = value.to_i / (1000 * 1000) #convert from hz to MHz
            else
              cpu[index][attrib] = value
            end
          end
          # IBM is the only maker of CPUs for AIX systems.
          cpu[index][:vendor_id] = "IBM"
        end
      end
    end
  end
end
