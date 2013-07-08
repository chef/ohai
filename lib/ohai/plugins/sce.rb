#
# Author:: John E. Vincent (<lusis.org+github.com@gmail.com>)
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

provides 'sce'
require_plugin "hostname"
require_plugin "os"
require_plugin "network"
require_plugin "#{os}::network"

# We're going to key off the "cloud" directory stuff
case os
when "windows"
  cloud_dir = 'c:/cloud'
when "linux"
  cloud_dir = '/etc/cloud'
end

sce_hints = hint?("sce")
if File.directory?(cloud_dir) and File.exist?(cloud_dir+"/parameters.xml")
  require 'ipaddress'
  require 'rexml/document'
  doc = REXML::Document.new(File.open(cloud_dir+"/parameters.xml", "r") {|f| f.read })
  if doc.root.name == 'parameters'
    sce Mash.new
    ip1 = ipaddress
    if IPAddress(ip1).private?
      sce[:private_ipv4] = ip1
    else
      sce[:public_ipv4] = ip1
      if network['interfaces']['eth1']
        ip2 = network['interfaces']['eth1']['addresses'].select {|address, data| data['family'] == 'inet' }.keys.first
        if IPAddress(ip2).private?
          sce[:private_ipv4] = ip2
        end
      end
    end
    if sce_hints
      Ohai::Log.debug("adding in sce hints")
      sce.merge!(sce_hints)
    end
    sce 
  end
end
