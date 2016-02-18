#
# Author:: Julian C. Dunn (<jdunn@chef.io>)
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

Ohai.plugin(:Virtualization) do
  provides "virtualization", "virtualization/wpars"

  collect_data(:aix) do
    virtualization Mash.new

    so = shell_out("uname -L")
    lpar_no = so.stdout.split($/)[0].split(/\s/)[0]
    lpar_name = so.stdout.split($/)[0].split(/\s/)[1]

    unless lpar_no.to_i == -1 || (lpar_no.to_i == 1 && lpar_name == "NULL")
      virtualization[:lpar_no] = lpar_no
      virtualization[:lpar_name] = lpar_name
    end

    so = shell_out("uname -W")
    wpar_no = so.stdout.split($/)[0]
    if wpar_no.to_i > 0
      virtualization[:wpar_no] = wpar_no
    else
      # the below parses the output of lswpar in the long format
      so = shell_out("lswpar -L").stdout.scan(/={65}.*?(?:EXPORTED\n\n)+/m)
      wpars = Mash.new
      so.each do |wpar|
        wpar_name = wpar.lines[1].split[0]
        wpars[wpar_name] = Mash.new

        wpar.scan(/^[A-Z]{4,}.*?[A-Z\:0-9]$.*?\n\n/m).each do |section|

          # retrieve title of section
          title = section.lines.first[0..-2].downcase
          wpars[wpar_name][title] = Mash.new

          # discard trailing section newline+title
          # and save as array
          sections = section.lines[1..-2]

          sections.each do |line|
            case title
            when "network"
              next if line =~ /^Interface|^---/
              splat = line.strip.split
              key   = splat[0].downcase
              value = {
                        "address"   => splat[1],
                        "netmask"   => splat[2],
                        "broadcast" => splat[3],
                      }
              wpars[wpar_name][title][key] = value
            when "user-specified routes"
              next if line =~ /^Type|^---/
              splat = line.strip.split
              key   = splat[2].downcase
              value = {
                        "destination" => splat[0],
                        "gateway"     => splat[1],
                      }
              wpars[wpar_name][title][key] = value
            when "file systems"
              next if line =~ /^MountPoint|^---/
              splat = line.strip.split
              key = splat[1].downcase
              value = {
                        "mountpoint" => splat[0],
                        "device"     => splat[1],
                        "vfs" => splat[2],
                        "options" => splat[3].split(","),
                      }
              wpars[wpar_name][title][key] = value
            when "security settings"
              privileges ||= ""
              wpars[wpar_name][title]["Privileges"] ||= []

              if line =~ /^Privileges/
                privileges << line.split(":")[1].strip
              else
                privileges << line.strip
              end

              wpars[wpar_name][title]["Privileges"] += privileges.split(",")
            when "device exports"
              next if line =~ /^Name|^---/
              splat = line.strip.split
              key = splat[0].downcase
              value = {
                        "type" => splat[1],
                        "status" => splat[2],
                      }
              wpars[wpar_name][title][key] = value
            else
              # key-value pairs are handled here
              # such as GENERAL and RESOURCE-
              # CONTROL
              splat = line.strip.split(":")
              key   = splat[0].downcase
              value = splat[1..-1].join(", ").strip
              value = value.empty? ? nil : value
              case value
              when "yes"
                value = true
              when "no"
                value = false
              end
              wpars[wpar_name][title][key] = value
            end
          end
        end
        top_level = [
          "general.directory",
          "general.hostname",
          "general.private /usr",
          "general.type",
          "general.uuid",
          "resource controls.active",
          "network.en0.address",
        ]

        top_level.each do |attribute|
          evalstr = "wpars['#{wpar_name}']"
          breadcrumb = attribute.split(".")
          breadcrumb.each do |node|
            evalstr << "[\'#{node}\']"
          end
          wpars[wpar_name][breadcrumb[-1]] = eval evalstr
        end
      end
      virtualization[:wpars] = wpars unless wpars.empty?
    end
  end
end
