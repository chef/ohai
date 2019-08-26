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

require "spec_helper"

docker_output = <<~EOF
  {"ID":"KZET:VDFN:2V2G:JS5Z:HAKO:SOGI:AFSZ:HDMT:GVEM:V2NT:DUSW:J3Z6","Containers":11,"ContainersRunning":0,"ContainersPaused":0,"ContainersStopped":11,"Images":30,"Driver":"overlay2","DriverStatus":[["Backing Filesystem","extfs"],["Supports d_type","true"],["Native Overlay Diff","true"]],"SystemStatus":null,"Plugins":{"Volume":["local"],"Network":["bridge","host","ipvlan","macvlan","null","overlay"],"Authorization":null,"Log":["awslogs","fluentd","gcplogs","gelf","journald","json-file","logentries","splunk","syslog"]},"MemoryLimit":true,"SwapLimit":true,"KernelMemory":true,"CpuCfsPeriod":true,"CpuCfsQuota":true,"CPUShares":true,"CPUSet":true,"IPv4Forwarding":true,"BridgeNfIptables":true,"BridgeNfIp6tables":true,"Debug":true,"NFd":21,"OomKillDisable":true,"NGoroutines":39,"SystemTime":"2018-02-15T19:12:40.214106068Z","LoggingDriver":"json-file","CgroupDriver":"cgroupfs","NEventsListener":2,"KernelVersion":"4.9.60-linuxkit-aufs","OperatingSystem":"Docker for Mac","OSType":"linux","Architecture":"x86_64","IndexServerAddress":"https://index.docker.io/v1/","RegistryConfig":{"AllowNondistributableArtifactsCIDRs":[],"AllowNondistributableArtifactsHostnames":[],"InsecureRegistryCIDRs":["127.0.0.0/8"],"IndexConfigs":{"docker.io":{"Name":"docker.io","Mirrors":[],"Secure":true,"Official":true}},"Mirrors":[]},"NCPU":4,"MemTotal":2095816704,"GenericResources":null,"DockerRootDir":"/var/lib/docker","HttpProxy":"docker.for.mac.http.internal:3128","HttpsProxy":"docker.for.mac.http.internal:3129","NoProxy":"","Name":"linuxkit-025000000001","Labels":[],"ExperimentalBuild":true,"ServerVersion":"17.12.0-ce","ClusterStore":"","ClusterAdvertise":"","Runtimes":{"runc":{"path":"docker-runc"}},"DefaultRuntime":"runc","Swarm":{"NodeID":"","NodeAddr":"","LocalNodeState":"inactive","ControlAvailable":false,"Error":"","RemoteManagers":null},"LiveRestoreEnabled":false,"Isolation":"","InitBinary":"docker-init","ContainerdCommit":{"ID":"89623f28b87a6004d4b785663257362d1658a729","Expected":"89623f28b87a6004d4b785663257362d1658a729"},"RuncCommit":{"ID":"b2567b37d7b75eb4cf325b77297b140ea686ce8f","Expected":"b2567b37d7b75eb4cf325b77297b140ea686ce8f"},"InitCommit":{"ID":"949e6fa","Expected":"949e6fa"},"SecurityOptions":["name=seccomp,profile=default"]}
EOF

expected_output = {
  "version_string" => "17.12.0-ce",
  "version" => "17.12.0",
  "runtimes" => {
    "runc" => {
      "path" => "docker-runc",
    },
  },
  "root_dir" => "/var/lib/docker",
  "containers" => {
    "total" => 11,
    "running" => 0,
    "paused" => 0,
    "stopped" => 11,
  },
  "plugins" => {
    "Volume" => [
      "local",
    ],
    "Network" => %w{
bridge
host
ipvlan
macvlan
null
overlay},
    "Authorization" => nil,
    "Log" => %w{
      awslogs
      fluentd
      gcplogs
      gelf
      journald
      json-file
      logentries
      splunk
      syslog
    },
  },
  "networking" => {
    "ipv4_forwarding" => true,
    "bridge_nf_iptables" => true,
    "bridge_nf_ipv6_iptables" => true,
  },
  "swarm" => {
    "NodeID" => "",
    "NodeAddr" => "",
    "LocalNodeState" => "inactive",
    "ControlAvailable" => false,
    "Error" => "",
    "RemoteManagers" => nil,
  },
}

describe Ohai::System, "plugin docker" do
  let(:plugin) { get_plugin("docker") }

  context "if the machine does not have docker installed" do
    it "does not create a docker attribute" do
      plugin[:virtualization] = Mash.new
      plugin[:virtualization][:systems] = Mash.new
      plugin.run
      expect(plugin).not_to have_key(:docker)
    end
  end

  context "if the machine has docker installed" do
    it "creates a docker attribute with correct data" do
      plugin[:virtualization] = Mash.new
      plugin[:virtualization][:systems] = Mash.new
      plugin[:virtualization][:systems][:docker] = "host"
      allow(plugin).to receive(:shell_out).with("docker info --format '{{json .}}'").and_return(mock_shell_out(0, docker_output, ""))
      plugin.run
      expect(plugin).to have_key(:docker)
      expect(plugin[:docker]).to eq(expected_output)
    end
  end
end
