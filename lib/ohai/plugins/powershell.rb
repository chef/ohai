#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

Ohai.plugin(:Powershell) do
  provides "languages/powershell"
  depends "languages".freeze

  collect_data(:windows) do
    so = shell_out("#{powershell_command} \"#{version_table_command}\"")
    # Sample output, one "name=value" line per $PSVersionTable entry with
    # array values joined by commas:
    #
    # PSVersion=5.1.26100.1
    # PSEdition=Desktop
    # PSCompatibleVersions=1.0,2.0,3.0,4.0,5.0,5.1.26100.1
    # BuildVersion=10.0.26100.1
    # CLRVersion=4.0.30319.42000
    # WSManStackVersion=3.0
    # PSRemotingProtocolVersion=2.3
    # SerializationVersion=1.1.0.1

    if so.exitstatus == 0
      version_info = {}
      so.stdout.each_line do |line|
        key, value = line.strip.split("=", 2)
        version_info[key] = value if key && value
      end

      powershell = Mash.new
      powershell[:version] = version_info["PSVersion"]
      powershell[:ws_man_stack_version] = version_info["WSManStackVersion"]
      powershell[:serialization_version] = version_info["SerializationVersion"]
      powershell[:clr_version] = version_info["CLRVersion"]
      powershell[:build_version] = version_info["BuildVersion"]
      powershell[:compatible_versions] = version_info.fetch("PSCompatibleVersions", "").split(",")
      powershell[:remoting_protocol_version] = version_info["PSRemotingProtocolVersion"]
      languages[:powershell] = powershell if powershell[:version]
    else
      logger.trace("Plugin Powershell: #{powershell_command} exited #{so.exitstatus}. Skipping plugin")
    end
  rescue Ohai::Exceptions::Exec => e
    # A timeout is worth surfacing: PowerShell is installed but too slow to
    # start, and languages/powershell silently goes missing.
    if e.cause.is_a?(Mixlib::ShellOut::CommandTimeout)
      logger.warn("Plugin Powershell: #{powershell_command} timed out. Skipping plugin")
    else
      logger.trace("Plugin Powershell: could not run #{powershell_command}. Skipping plugin")
    end
  end

  # Read every value from one PowerShell process. Starting powershell.exe is
  # the slow part of this plugin, and with separate processes a timeout in any
  # one of them discarded everything the others had already collected.
  def version_table_command
    [
      "$progresspreference = 'silentlycontinue'",
      "$PSVersionTable.GetEnumerator() | ForEach-Object { $_.Key + '=' + (@($_.Value) -join ',') }",
    ].join("; ")
  end

  def powershell_command
    ["powershell.exe",
      "-NoLogo",
      "-NonInteractive",
      "-NoProfile",
      "-Command",
    ].join(" ")
  end
end
