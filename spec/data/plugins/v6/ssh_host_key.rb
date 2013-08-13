#
# Author:: Bryan McLellan <btm@opscode.com>
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

provides "keys/ssh"
require_plugin "keys"

keys[:ssh] = Mash.new

def extract_keytype?(content)
  case content[0]
  when "ssh-dss"
    [ "dsa", nil ]
  when "ssh-rsa"
    [ "rsa", nil ]
  when /^ecdsa/
    [ "ecdsa", content[0] ]
  else
    [ nil, nil ]
  end
end

sshd_config = if File.exists?("/etc/ssh/sshd_config")
                "/etc/ssh/sshd_config"
              elsif File.exists?("/etc/sshd_config")
                # Darwin
                "/etc/sshd_config"
              else
                Ohai::Log.debug("Failed to find sshd configuration file")
                nil
              end

if sshd_config
  File.open(sshd_config) do |conf|
    conf.each_line do |line|
      if line.match(/^hostkey\s/i)
        pub_file = "#{line.split[1]}.pub"
        content = IO.read(pub_file).split
        key_type, key_subtype = extract_keytype?(content)
        keys[:ssh]["host_#{key_type}_public"] = content[1] unless key_type.nil?
        keys[:ssh]["host_#{key_type}_type"] = key_subtype unless key_subtype.nil?
      end
    end
  end
end

if keys[:ssh][:host_dsa_public].nil? && File.exists?("/etc/ssh/ssh_host_dsa_key.pub")
  keys[:ssh][:host_dsa_public] = IO.read("/etc/ssh/ssh_host_dsa_key.pub").split[1]
end

if keys[:ssh][:host_rsa_public].nil? && File.exists?("/etc/ssh/ssh_host_rsa_key.pub")
  keys[:ssh][:host_rsa_public] = IO.read("/etc/ssh/ssh_host_rsa_key.pub").split[1]
end

if keys[:ssh][:host_ecdsa_public].nil? && File.exists?("/etc/ssh/ssh_host_ecdsa_key.pub")
  content = IO.read("/etc/ssh/ssh_host_ecdsa_key.pub")
  keys[:ssh][:host_ecdsa_public] = content.split[1]
  keys[:ssh][:host_ecdsa_type] = content.split[0]
end
