#
# Author:: James Gartrell (<jgartrel@gmail.com>)
# Copyright:: Copyright (c) 2009-2016 Chef Software, Inc.
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

Ohai.plugin(:Filesystem) do
  provides "filesystem"

  # Volume encryption or decryption status
  #
  # @see https://docs.microsoft.com/en-us/windows/desktop/SecProv/getconversionstatus-win32-encryptablevolume#parameters
  #
  CONVERSION_STATUS ||= %w{FullyDecrypted FullyEncrypted EncryptionInProgress
                         DecryptionInProgress EncryptionPaused DecryptionPaused}.freeze

  # Returns a Mash loaded with logical details
  #
  # Uses Win32_LogicalDisk and logical_properties to return encryption details of volumes.
  #
  # Returns an empty Mash in case of any WMI exception.
  #
  # @see https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-logicaldisk
  #
  # @return [Mash]
  #
  def logical_info
    wmi = WmiLite::Wmi.new("Root\\CIMV2")

    # Note: we should really be parsing Win32_Volume and Win32_Mapped drive.
    disks = wmi.instances_of("Win32_LogicalDisk")
    logical_properties(disks)
  rescue WmiLite::WmiException
    Ohai::Log.debug("Unable to access Win32_LogicalDisk. Skipping logical details")
    Mash.new
  end

  # Returns a Mash loaded with encryption details
  #
  # Uses Win32_EncryptableVolume and encryption_properties to return encryption details of volumes.
  #
  # Returns an empty Mash in case of any WMI exception.
  #
  # @note We are fetching Encryption Status only as of now
  #
  # @see https://msdn.microsoft.com/en-us/library/windows/desktop/aa376483(v=vs.85).aspx
  #
  # @return [Mash]
  #
  def encryptable_info
    wmi = WmiLite::Wmi.new("Root\\CIMV2\\Security\\MicrosoftVolumeEncryption")
    disks = wmi.instances_of("Win32_EncryptableVolume")
    encryption_properties(disks)
  rescue WmiLite::WmiException
    Ohai::Log.debug("Unable to access Win32_EncryptableVolume. Skipping encryptable details")
    Mash.new
  end

  # Refines and calculates logical properties out of given instances
  #
  # @param [WmiLite::Wmi::Instance] disks
  #
  # @return [Mash] Each drive containing following properties:
  #
  #  * :kb_size (Integer)
  #  * :kb_available (Integer)
  #  * :kb_used (Integer)
  #  * :percent_used (Integer)
  #  * :mount (String)
  #  * :fs_type (String)
  #  * :volume_name (String)
  #
  def logical_properties(disks)
    properties = Mash.new
    disks.each do |disk|
      property = Mash.new
      drive = disk["deviceid"]
      property[:kb_size] = disk["size"].to_i / 1000
      property[:kb_available] = disk["freespace"].to_i / 1000
      property[:kb_used] = property[:kb_size] - property[:kb_available]
      property[:percent_used] = (property[:kb_size] == 0 ? 0 : (property[:kb_used] * 100 / property[:kb_size]))
      property[:mount] = disk["name"]
      property[:fs_type] = disk["filesystem"].to_s.downcase
      property[:volume_name] = disk["volumename"].to_s.downcase
      properties[drive] = property
    end
    properties
  end

  # Refines and calculates encryption properties out of given instances
  #
  # @param [WmiLite::Wmi::Instance] disks
  #
  # @return [Mash] Each drive containing following properties:
  #
  #  * :encryption_status (String)
  #
  def encryption_properties(disks)
    properties = Mash.new
    disks.each do |disk|
      drive = disk["driveletter"]
      property = Mash.new
      property[:encryption_status] = disk["conversionstatus"] ? CONVERSION_STATUS[disk["conversionstatus"]] : ""
      properties[drive] = property
    end
    properties
  end

  # Merges all the various properties of filesystems
  #
  # @param [Array<Mash>] disks_info
  #   Array of the Mashes containing disk properties
  #
  # @return [Mash]
  #
  def merge_info(disks_info)
    fs = Mash.new
    disks_info.each do |info|
      info.each do |disk, data|
        if fs[disk]
          fs[disk].merge!(data)
        else
          fs[disk] = data.dup
        end
      end
    end
    fs
  end

  collect_data(:windows) do
    require "wmi-lite/wmi"
    filesystem merge_info([logical_info,
                           encryptable_info])
  end
end
