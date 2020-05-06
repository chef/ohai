#
# Author:: Davide Cavalca <dcavalca@fb.com>
# Copyright:: Copyright (c) 2020 Facebook
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

require "spec_helper"

describe Ohai::System, "Linux selinux plugin" do
  let(:plugin) { get_plugin("linux/selinux") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  it "populates selinux if sestatus is found" do
    sestatus_out = <<-SESTATUS_OUT
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             test
Current mode:                   permissive
Mode from config file:          permissive
Policy MLS status:              disabled
Policy deny_unknown status:     allowed
Max kernel policy version:      31

Policy booleans:
secure_mode_policyload          off

Process contexts:
Current context:                user_u:base_r:admin_t
Init context:                   system_u:system_r:init_t
/usr/sbin/sshd                  system_u:base_r:base_t

File contexts:
Controlling terminal:           system_u:object_r:file_t
/etc/passwd                     user_u:object_r:file_t
/etc/shadow                     user_u:object_r:file_t
/bin/bash                       user_u:object_r:file_t
/bin/login                      user_u:object_r:file_t
/bin/sh                         user_u:object_r:file_t -> user_u:object_r:file_t
/sbin/agetty                    user_u:object_r:file_t
/sbin/init                      user_u:object_r:file_t -> user_u:object_r:init_exec_t
/usr/sbin/sshd                  user_u:object_r:file_t
    SESTATUS_OUT
    allow(plugin).to receive(:which).with("sestatus").and_return("/usr/sbin/sestatus")
    allow(plugin).to receive(:shell_out).with("/usr/sbin/sestatus -v -b").and_return(mock_shell_out(0, sestatus_out, ""))
    plugin.run
    expect(plugin[:selinux].to_hash).to eq({
       "file_contexts" => {
         "/bin/bash" => "user_u:object_r:file_t",
         "/bin/login" => "user_u:object_r:file_t",
         "/bin/sh" => "user_u:object_r:file_t -> user_u:object_r:file_t",
         "/etc/passwd" => "user_u:object_r:file_t",
         "/etc/shadow" => "user_u:object_r:file_t",
         "/sbin/agetty" => "user_u:object_r:file_t",
         "/sbin/init" => "user_u:object_r:file_t -> user_u:object_r:init_exec_t",
         "/usr/sbin/sshd" => "user_u:object_r:file_t",
         "controlling_terminal" => "system_u:object_r:file_t",
       },
       "policy_booleans" => {
         "secure_mode_policyload" => "off",
       },
       "process_contexts" => {
         "/usr/sbin/sshd" => "system_u:base_r:base_t",
         "current_context" => "user_u:base_r:admin_t",
         "init_context" => "system_u:system_r:init_t",
       },
       "status" => {
         "current_mode" => "permissive",
         "loaded_policy_name" => "test",
         "max_kernel_policy_version" => "31",
         "mode_from_config_file" => "permissive",
         "policy_deny_unknown_status" => "allowed",
         "policy_mls_status" => "disabled",
         "selinux_root_directory" => "/etc/selinux",
         "selinux_status" => "enabled",
         "selinuxfs_mount" => "/sys/fs/selinux",
      },
    })
  end

  it "does not populate selinux if sestatus is not found" do
    allow(plugin).to receive(:which).with("sestatus").and_return(false)
    plugin.run
    expect(plugin[:selinux]).to be(nil)
  end
end
