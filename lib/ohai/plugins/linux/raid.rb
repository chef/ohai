# Author:: Nicolas Szalay <https://github.com/rottenbytes>
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
provides 'raid/devices'

raid Mash.new

# Sample data
# 05:00.0 "RAID bus controller" "Hewlett-Packard Company" "Smart Array G6 controllers" -r01 "Hewlett-Packard Company" "Smart Array P410i"
# 11:00.0 "RAID bus controller" "Areca Technology Corp." "Device 1880" -r05 "Areca Technology Corp." "Device 1880"
# 01:00.0 "RAID bus controller" "LSI Logic / Symbios Logic" "MegaRAID SAS 1078" -r04 "Dell" "PERC 6/i Integrated RAID Controller"


# PCI ID / TYPE / VENDOR / DEVICE NAME / -rREVISION / SUBVENDOR / SUBSYSTEM NAME
re=Regexp.new("(.*) \"(.*)\" \"(.*)\" \"(.*)\" -r(.*) \"(.*)\" \"(.*)\"")

devices=Array.new

`/usr/bin/lspci -m | /bin/grep -i raid`.each_line do |l|
  m=re.match(l)
  if m then
    data=Hash.new
    data[:pciid] = m[1]
    data[:vendor] = m[3]
    data[:susbsystem] = m[7]
    data[:devicename]=m[4]
    data[:revision]=m[5]
    data[:subvendor]=m[6]
    devices.push(data)
  end
end

raid[:devices]=devices
