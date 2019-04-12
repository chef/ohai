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
  CONVERSION_STATUS = %w{FullyDecrypted FullyEncrypted EncryptionInProgress
                         DecryptionInProgress EncryptionPaused DecryptionPaused}.freeze

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
    disks = Mash.new
    # @see https://docs.microsoft.com/en-us/windows/desktop/cimwin32prov/win32-logicaldisk
    disk_properties = %w[ DeviceID FileSystem FreeSpace Name Size VolumeName ]

    disks_results = shell_out("Get-WmiObject \"Win32_LogicalDisk\" | ForEach-Object { Write-Host \"#{ disk_properties.map {|p| "$($_.#{p})"}.join(',') }\" }").stdout.strip

    disks_results.lines.each do |line|
      device_id, file_system, free_space, name, size, volume_name = line.strip.split(',')
      disks[device_id] ||= Mash.new
      disk = disks[device_id]
      disk[:fs_type] = file_system.to_s.downcase
      disk[:mount] = name
      disk[:volume_name] = volumne_name.to_s.downcase
      disk[:kb_size] = size.to_i / 1000
      disk[:kb_available] = freespace.to_i / 1000
      disk[:kb_used] = disk[:kb_size] - disk[:kb_available]
      disk[:percent_used] = (disk[:kb_size] == 0 ? 0 : (disk[:kb_used] * 100 / disk[:kb_size]))
    end

    # @see https://docs.microsoft.com/en-us/windows/desktop/secprov/win32-encryptablevolume
    encrypted_properties = %w[ DeviceID DriveLetter ProtectionStatus GetConversionStatus() ]
    
    encrypted_results = shell_out("Get-WmiObject -Namespace \"Root\\CIMV2\\Security\\MicrosoftVolumeEncryption\" -ClassName \"Win32_Encryptablevolume\" | ForEach-Object { Write-Host \"#{ encrypted_properties.map {|p| "$($_.#{p}"}.join(',') }\" } }").stdout.strip

    encrypted_results.lines.each do |line|
      device_id, drive_letter, protection_status, conversion_status = line.strip.split(',')
      disks[device_id] ||= Mash.new
      disk = disks[device_id]
      disk[:encryption_status] = conversion_status ? CONVERSION_STATUS[conversion_status] : ""
    end

    filesystem disks
  end
end
