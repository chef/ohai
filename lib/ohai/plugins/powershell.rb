#
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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
  depends "languages"

  collect_data(:windows) do
    powershell = Mash.new
    so = shell_out("powershell.exe -NoLogo -NonInteractive -NoProfile -command $PSVersionTable")
    # Sample output:
    #
    # Name                           Value
    # ----                           -----
    # PSVersion                      4.0
    # WSManStackVersion              3.0
    # SerializationVersion           1.1.0.1
    # CLRVersion                     4.0.30319.34014
    # BuildVersion                   6.3.9600.16394
    # PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0}
    # PSRemotingProtocolVersion      2.2
    
    if so.exitstatus == 0
      version_info = {}
      so.stdout.strip.each_line do |line|
        kv = line.strip.split(/\s+/, 2)
        version_info[kv[0]] = kv[1] if kv.length == 2
      end
      powershell[:version] = version_info['PSVersion']
      powershell[:ws_man_stack_version] = version_info['WSManStackVersion']
      powershell[:serialization_version] = version_info['SerializationVersion']
      powershell[:clr_version] = version_info['CLRVersion']
      powershell[:build_version] = version_info['BuildVersion']
      powershell[:compatible_versions] = parse_compatible_versions(version_info['PSCompatibleVersions'])
      powershell[:remoting_protocol_version] = version_info['PSRemotingProtocolVersion']
      languages[:powershell] = powershell if powershell[:version]
    end
  end

  def parse_compatible_versions(versions_str)
    if versions_str
      if versions_str.strip.start_with?('{') && versions_str.end_with?('}')
        versions = versions_str.gsub(/[{}\s]+/,'').split(',')
        versions if versions.length
      end
    end
  end
end
