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
    shell_out("hab -V").stdout.gsub(/hab\s*/, "").strip || nil
  end

  def fetch_habitat_packages
    if Dir.exist?("C:/hab/pkgs")
      Dir.glob("C:/hab/pkgs/*/*/*/*/").sort.map { |pkg| pkg.gsub("C\:\/hab\/pkgs\/", "").chomp("/") }
    elsif Dir.exist?("/hab/pkgs")
      Dir.glob("/hab/pkgs/*/*/*/*/").sort.map { |pkg| pkg.gsub("\/hab\/pkgs\/", "").chomp("/") }
    end
  end

  def fetch_habitat_services
    if Dir.exist?("C:/hab/svc")
      Dir.glob("C:/hab/svc/*").sort.map { |svc| svc.gsub("C\:\/hab\/svc\/", "").chomp("/") }
    elsif Dir.exist?("/hab/svc")
      Dir.glob("/hab/svc/*").sort.map { |svc| svc.gsub("\/hab\/svc\/", "").chomp("/") }
    end
  end

  collect_data(:default) do
    habitat Mash.new
    habitat["version"] = fetch_habitat_version
    habitat["packages"] = fetch_habitat_packages
    habitat["services"] = fetch_habitat_services
  end
end
