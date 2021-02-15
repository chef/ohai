# frozen_string_literal: true
#
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
#
Ohai.plugin(:Habitat) do
  provides "habitat"

  def fetch_habitat_version
    shell_out(["hab"], ["-V"]).stdout.gsub(/hab\s*/, "").strip
  rescue Ohai::Exceptions::Exec
    logger.trace("Plugin Habitat: No detected version of hab binary found in PATH, skipping collection.")
  end

  def fetch_habitat_packages
    shell_out(["hab", "pkg", "list", "--all"]).stdout.split.sort.select { |pkg| pkg.match?(%r{.*/.*/.*/.*}) }
  rescue Ohai::Exceptions::Exec
    logger.trace("Plugin Habitat: No detected version of hab binary found in PATH, skipping collection.")
  end

  def load_habitat_service_via_cli(status_stdout)
    # package                           type        desired  state  elapsed (s)  pid   group
    # core/httpd/2.4.35/20190307151146  standalone  up       up     158169       1410  httpd.default
    @services = []
    lines = status_stdout.split("\n")
    lines.each do |line|
      @service = {}
      fields = line.split(/\s+/)
      next unless fields[0].match?(%r{.*/.*/.*/.*}) # ignore header line

      @service = {}
      @service[:identity] = fields[0]
      @service[:topology] = fields[1]
      @service[:state_desired] = fields[2]
      @service[:state_actual] = fields[2]
      (@services).push(@service)
    end
    @services
  end

  def fetch_habitat_services
    services_shell_out = shell_out(%w{hab svc status}).stdout
    load_habitat_service_via_cli(services_shell_out) if services_shell_out
  rescue Ohai::Exceptions::Exec
    logger.trace("Plugin Habitat: No detected version of hab binary found in PATH, skipping collection.")
  end

  collect_data(:default) do
    habitat Mash.new
    habitat["version"] = fetch_habitat_version
    habitat["packages"] = fetch_habitat_packages
    habitat["services"] = fetch_habitat_services
  end
end
