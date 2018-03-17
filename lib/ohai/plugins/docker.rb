#
# Copyright:: 2018 Chef Software, Inc.
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

Ohai.plugin(:Docker) do
  require "json"

  provides "docker"
  depends "virtualization"

  def docker_info_json
    so = shell_out("docker info --format '{{json .}}'")
    if so.exitstatus == 0
      return JSON.parse(so.stdout)
    end
  rescue Ohai::Exceptions::Exec
    logger.trace('Plugin Docker: Could not shell_out "docker info --format \'{{json .}}\'". Skipping plugin')
  end

  def docker_ohai_data(shellout_data)
    docker Mash.new
    docker[:version_string] = shellout_data["ServerVersion"]
    docker[:version] = shellout_data["ServerVersion"].split("-")[0] if shellout_data["ServerVersion"] # guard this so missing data doesn't fail the run
    docker[:runtimes] = shellout_data["Runtimes"]
    docker[:root_dir] = shellout_data["DockerRootDir"]
    docker[:containers] = {}
    docker[:containers][:total] = shellout_data["Containers"]
    docker[:containers][:running] = shellout_data["ContainersRunning"]
    docker[:containers][:paused] = shellout_data["ContainersPaused"]
    docker[:containers][:stopped] = shellout_data["ContainersStopped"]
    docker[:plugins] = shellout_data["Plugins"]
    docker[:networking] = {}
    docker[:networking][:ipv4_forwarding] = shellout_data["IPv4Forwarding"]
    docker[:networking][:bridge_nf_iptables] = shellout_data["BridgeNfIptables"]
    docker[:networking][:bridge_nf_ipv6_iptables] = shellout_data["BridgeNfIp6tables"]
    docker[:swarm] = shellout_data["Swarm"]
  end

  collect_data do
    if virtualization[:systems][:docker]
      docker_ohai_data(docker_info_json)
    end
  end
end
