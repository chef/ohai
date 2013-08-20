#
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright (c) 2013, Opscode, Inc.
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

provides "cpu"

cpu Mash.new

# IBM is the only maker of CPUs for AIX systems.
cpu[:vendor_id] = "IBM"
# At least one CPU will be available, but we'll wait to increment this later.
cpu[:available] = 0
cpu[:total] = 0

cpudevs = from("lsdev -Cc processor").lines
cpudevs.each do |c|
	cpu[:total] += 1
  name, status, location = c.split
  cpu[name] = Mash.new
  cpu[name][:status] = status
	cpu[name][:location] = location
  if status =~ /Available/
  	cpu[:available] += 1
  	lsattr = from("lsattr -El #{name}").lines
  	lsattr.each do |attribute|
  		attrib, value = attribute.split
  		cpu[name][attrib] = value
  	end
  end
end

# Every AIX system has proc0.
cpu[:model] = cpu[:proc0][:type]
cpu[:mhz] = cpu[:proc0][:frequency].to_i / 1024
