# Author:: "Joshua Colson" <joshua.colson@gmail.com>
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Ohai.plugin(:VboxHost) do
  depends 'virtualization'
  provides 'virtualization/vbox'

  # determine if this host is configured with virtualbox or not
  # the determination is ultimately controlled by the 'virtualization' plugin
  def vbox_host?
    host = false
    if !virtualization.nil? && (virtualization['system'] == 'vbox' || virtualization['systems']['vbox'] == 'host')
      host = true if which('VBoxManage')
    end
    host
  end

  # query virtualbox for each configured vm, as well as
  # each guest's individual configuration settings
  def vboxmanage_list_vms
    vms = Mash.new
    if vbox_host?
      so = shell_out('VBoxManage list --sorted vms')
      # raise an exception if the command fails
      so.error!

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

    if vbox_host?
      so = shell_out("VBoxManage showvminfo #{machine_id} --machinereadable")
      # raise an exception if the command fails
      so.error!

      so.stdout.lines.each do |line|
        line.chomp!
        left, right = line.split('=')

        # remove enclosing quotes, if needed
        key =
          case left
          when /^"(.*)"$/
            Regexp.last_match(1)
          else
            left
          end

        # skip the name attribute since that is the parent key
        next if left == 'name'

        # remove enclosing quotes, if needed
        value =
          case right
          when /^"(.*)"$/
            Regexp.last_match(1)
          else
            right
          end

        vm[key.downcase] = value
      end
    end
    vm
  rescue Ohai::Exceptions::Exec
    logger.trace("Plugin VboxHost: Could not run 'VBoxManage showvminfo #{machine_id} --machinereadable'. Skipping data")
  end

  # query virtualbox for a list of #{query_type} items
  # these queries return a result set that is delimited by
  # multiple successive newlines, with each block containing
  # key/value pairs delimited by a colon (:) and column aligned
  #
  # the keys of each k/v pair are normalized to lowercase
  def vboxmanage_list_blocks(query_type, name_key)
    # ignore unrecognized query type
    supported_queries = %w(
      bridgedifs dhcpservers dvds hdds hostdvds hostfloppies
      hostonlyifs natnets ostypes)
    return nil unless supported_queries.include? query_type
    results = Mash.new

    if vbox_host?
      so = shell_out("VBoxManage list --sorted #{query_type}")
      # raise an exception if the command fails
      so.error!

      # break the result into paragraph blocks, on successive newlines
      so.stdout.each_line('') do |blk|
        # remove the multiple newlines of each record
        blk.chomp!.chomp!
        # initialize a blank record hash
        record = Mash.new
        # parse the record block into key/value pairs
        blk.each_line() do |line|
          # split the line into key/value pair
          key, right = line.split(':')
          # strip the leading/trailing whitespace if the value is not nil
          value = right.nil? ? '' : right.strip
          record[key.downcase] = value
        end

        # compile the block of data into the Mash
        if record.key? name_key.downcase
          name = record.delete(name_key.downcase)
          results[name] = record
        end
      end
    end
    results
  rescue Ohai::Exceptions::Exec
    logger.trace("Plugin VboxHost: Could not run 'VBoxManage list --sorted #{query_type}'. Skipping data")
  end

  # collect the data for a virtualization host running VirtualBox
  collect_data(:default) do
    vbox = 'vbox'
    ostypes = 'ostypes'
    guests = 'guests'
    natnets = 'natnets'
    hostonlyifs = 'hostonlyifs'
    bridgedifs = 'bridgedifs'
    dhcpservers = 'dhcpservers'
    hdds = 'hdds'
    dvds = 'dvds'
    hostdvds = 'hostdvds'
    hostfloppies = 'hostfloppies'

    if vbox_host?
      virtualization[vbox] = Mash.new unless virtualization[vbox]

      # get a list of virtualbox virtual hard disk drives
      virtualization[vbox][ostypes] = vboxmanage_list_blocks(ostypes, 'ID')

      # get a list of virtualbox guest vms
      virtualization[vbox][guests] = vboxmanage_list_vms

      # get a list of virtualbox virtual hard disk drives
      virtualization[vbox][hdds] = vboxmanage_list_blocks(hdds, 'UUID')

      # get a list of virtualbox virtual dvd drives
      virtualization[vbox][dvds] = vboxmanage_list_blocks(dvds, 'UUID')

      # get a list of virtualbox host dvd drives
      virtualization[vbox][hostdvds] = vboxmanage_list_blocks(hostdvds, 'Name')

      # get a list of virtualbox host floppy drives
      virtualization[vbox][hostfloppies] = vboxmanage_list_blocks(hostfloppies, 'Name')

      # get a list of virtualbox hostonly network interfaces
      virtualization[vbox][hostonlyifs] = vboxmanage_list_blocks(hostonlyifs, 'Name')

      # get a list of virtualbox bridged network interfaces
      virtualization[vbox][bridgedifs] = vboxmanage_list_blocks(bridgedifs, 'Name')

      # get a list of virtualbox dhcp servers
      virtualization[vbox][dhcpservers] = vboxmanage_list_blocks(dhcpservers, 'NetworkName')

      # get a list of virtualbox nat networks
      virtualization[vbox][natnets] = vboxmanage_list_blocks(natnets, 'NetworkName')
    end
  rescue Ohai::Exceptions::Exec
    logger.trace('Plugin VboxHost: Could not collect data for VirtualBox host. Skipping data')
  end
end
