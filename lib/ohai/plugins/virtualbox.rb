#
# Author:: Tim Smith <tsmith@chef.io>
# Author:: Joshua Colson <joshua.colson@gmail.com>
# Copyright:: 2015-2019 Chef Software, Inc.
# Copyright:: 2019 Joshua Colson
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

Ohai.plugin(:Virtualbox) do
  depends "virtualization"
  provides "virtualbox"

  # query virtualbox for each configured vm, as well as
  # each guest's individual configuration settings
  def vboxmanage_list_vms
    vms = Mash.new
    so_cmd = "VBoxManage list --sorted vms"
    logger.trace(so_cmd)
    so = shell_out(so_cmd)

    if so.exitstatus == 0
      # parse the output
      so.stdout.lines.each do |line|
        case line
        when /^"(\S*)" \{(\S*)\}$/
          name = Regexp.last_match(1)
          uuid = Regexp.last_match(2)
          vms[name] = vboxmanage_vminfo(uuid)
        end
      end
    end
    vms
  rescue Ohai::Exceptions::Exec
    logger.trace("Plugin VboxHost: Could not run 'VBoxManage list --sorted vms'. Skipping data")
  end

  # query the vminfo for particular guest instance, normalizing
  # the fields so that they're not enclosed in double-quotes (")
  def vboxmanage_vminfo(machine_id)
    vm = Mash.new

    so_cmd = "VBoxManage showvminfo #{machine_id} --machinereadable"
    logger.trace(so_cmd)
    so = shell_out(so_cmd)

    if so.exitstatus == 0
      so.stdout.lines.each do |line|
        line.chomp!
        left, right = line.split("=")

        # remove enclosing quotes, if needed
        key = left.delete_prefix('"').delete_suffix('"')

        # skip the name attribute since that is the parent key
        next if key == "name"

        vm[key.downcase] = right.delete_prefix('"').delete_suffix('"')
      end
    end
    vm
  rescue Ohai::Exceptions::Exec
    logger.trace("Plugin VboxHost: Could not run '#{so_cmd}'. Skipping data")
  end

  # query virtualbox for a list of #{query_type} items
  # these queries return a result set that is delimited by
  # multiple successive newlines, with each block containing
  # key/value pairs delimited by a colon (:) and column aligned
  #
  # the keys of each k/v pair are normalized to lowercase
  def vboxmanage_list_blocks(query_type, name_key)
    # ignore unrecognized query type
    supported_queries = %w{
      bridgedifs dhcpservers dvds hdds hostdvds
      hostfloppies hostonlyifs natnets
    }
    return nil unless supported_queries.include? query_type

    results = Mash.new

    so_cmd = "VBoxManage list --sorted #{query_type}"
    logger.trace(so_cmd)
    so = shell_out(so_cmd)
      # raise an exception if the command fails
      # so.error!

    if so.exitstatus == 0
      # break the result into paragraph blocks, on successive newlines
      so.stdout.each_line("") do |blk|
        # remove the multiple newlines of each record
        blk.chomp!.chomp!
        # initialize a blank record hash
        record = Mash.new
        # parse the record block into key/value pairs
        blk.each_line do |line|
          next unless line.include? ":"

          # split the line into key/value pair
          key, right = line.split(":", 2)

          # strip the leading/trailing whitespace if the value is not nil
          value = right.nil? ? "" : right.strip
          record[key.downcase] = value
        end

        # insert the record into the list of results
        if record.key? name_key.downcase
          name = record.delete(name_key.downcase)
          results[name] = record
        end
      end
    end
    results
  rescue Ohai::Exceptions::Exec
    logger.trace("Plugin VboxHost: Could not run '#{so_cmd}'. Skipping data")
  end

  collect_data(:default) do
    case virtualization.dig("systems", "vbox")
    when "guest"
      logger.trace("Plugin Virtualbox: Node detected as vbox guest. Collecting guest data.")
      begin
        so = shell_out("VBoxControl guestproperty enumerate")

        if so.exitstatus == 0
          virtualbox Mash.new
          virtualbox[:host] = Mash.new
          virtualbox[:guest] = Mash.new
          so.stdout.lines.each do |line|
            case line
            when /LanguageID, value: (\S*),/
              virtualbox[:host][:language] = Regexp.last_match(1)
            when /VBoxVer, value: (\S*),/
              virtualbox[:host][:version] = Regexp.last_match(1)
            when /VBoxRev, value: (\S*),/
              virtualbox[:host][:revision] = Regexp.last_match(1)
            when %r{GuestAdd/VersionExt, value: (\S*),}
              virtualbox[:guest][:guest_additions_version] = Regexp.last_match(1)
            when %r{GuestAdd/Revision, value: (\S*),}
              virtualbox[:guest][:guest_additions_revision] = Regexp.last_match(1)
            end
          end
        end
      rescue Ohai::Exceptions::Exec
        logger.trace('Plugin Virtualbox: Could not execute "VBoxControl guestproperty enumerate". Skipping data collection.')
      end
    when "host"
      logger.trace("Plugin Virtualbox: Node detected as vbox host. Collecting host data.")
      virtualbox Mash.new
      begin
        # get a list of virtualbox guest vms
        virtualbox["guests"] = vboxmanage_list_vms

        # get a list of virtualbox virtual hard disk drives
        virtualbox["hdds"] = vboxmanage_list_blocks("hdds", "Location")

        # get a list of virtualbox virtual dvd drives
        virtualbox["dvds"] = vboxmanage_list_blocks("dvds", "Location")

        # get a list of virtualbox host dvd drives
        virtualbox["hostdvds"] = vboxmanage_list_blocks("hostdvds", "Name")

        # get a list of virtualbox host floppy drives
        virtualbox["hostfloppies"] = vboxmanage_list_blocks("hostfloppies", "Name")

        # get a list of virtualbox hostonly network interfaces
        virtualbox["hostonlyifs"] = vboxmanage_list_blocks("hostonlyifs", "Name")

        # get a list of virtualbox bridged network interfaces
        virtualbox["bridgedifs"] = vboxmanage_list_blocks("bridgedifs", "Name")

        # get a list of virtualbox dhcp servers
        virtualbox["dhcpservers"] = vboxmanage_list_blocks("dhcpservers", "NetworkName")

        # get a list of virtualbox nat networks
        virtualbox["natnets"] = vboxmanage_list_blocks("natnets", "NetworkName")
      rescue Ohai::Exceptions::Exec
        logger.trace("Plugin VboxHost: Could not collect data for VirtualBox host. Skipping data")
      end
    else
      logger.trace("Plugin Virtualbox: Not on a Virtualbox host or guest. Skipping plugin.")
    end
  end
end
