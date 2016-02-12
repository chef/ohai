#
# Author:: Deepali Jagtap (<deepali.jagtap@clogeny.com>)
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Ohai.plugin(:Filesystem) do
  provides "filesystem"

  def parse_df_or_mount(shell_out)
    oldie = Mash.new

    shell_out.lines.each do |line|
      fields = line.split
      case line
      # headers and horizontal rules to skip
      when /^\s*(node|---|^Filesystem\s+1024-blocks)/
        next
      # strictly a df entry
      when /^(.+?)\s+([0-9-]+)\s+([0-9-]+)\s+([0-9-]+)\s+([0-9-]+\%*)\s+(.+)$/
        if $1 == "Global"
          key = "#{$1}:#{$6}"
        else
          key = $1
        end
        oldie[key] ||= Mash.new
        oldie[key][:kb_size] = $2
        oldie[key][:kb_used] = $3
        oldie[key][:kb_available] = $4
        oldie[key][:percent_used] = $5
        oldie[key][:mount] = $6
      # an entry starting with 'G' or / (E.G. /tmp or /var)
      when /^\s*(G.*?|\/\w)/
        if fields[0] == "Global"
          key = fields[0] + ":" + fields[1]
        else
          key = fields[0]
        end
        oldie[key] ||= Mash.new
        oldie[key][:mount] = fields[1]
        oldie[key][:fs_type] = fields[2]
        oldie[key][:mount_options] = fields[6].split(",")
      # entries occupying the 'Node' column parsed here
      else
        key = fields[0] + ":" + fields[1]
        oldie[key] ||= Mash.new
        oldie[key][:mount] = fields[1]
        oldie[key][:fs_type] = fields[3]
        oldie[key][:mount_options] = fields[7].split(",")
      end
    end
    oldie
  end

  def collect_old_version(shell_outs)
    mount_hash = parse_df_or_mount shell_outs[:mount]
    df_hash    = parse_df_or_mount shell_outs[:df_Pk]

    mount_hash.each do |key, hash|
      df_hash[key].merge!(hash) if df_hash.has_key?(key)
    end

    mount_hash.merge(df_hash)
  end

  collect_data(:aix) do

    # Cache the command output
    shell_outs = Mash.new
    shell_outs[:mount] = shell_out("mount").stdout
    shell_outs[:df_Pk] = shell_out("df -Pk").stdout

    filesystem collect_old_version(shell_outs)
  end
end
