#
# Author:: Adam Jacob (<adam@chef.io>)
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

require "spec_helper"

describe Ohai::System, "plugin ruby" do
  let(:plugin) { get_plugin("ruby").tap { |p| p[:languages] = Mash.new } }
  let(:embedded_bindir) { ::RbConfig::CONFIG["bindir"] }

  # recorded from the system Ruby on Ubuntu 24.04 (ruby 3.2.3) with the command this plugin runs
  let(:system_ruby_output) { File.read(File.join(SPEC_PLUGIN_PATH, "ruby-ubuntu-24.04-system.output")) }

  before do
    allow(plugin).to receive(:default_paths).and_return([embedded_bindir, ::Gem.bindir, "/usr/local/bin", "/usr/bin", "/bin"].uniq.join(File::PATH_SEPARATOR))
  end

  it "runs ruby without the Ruby that runs Ohai in PATH" do
    expect(plugin).to receive(:shell_out) do |cmd, **options|
      expect(cmd).to start_with("ruby -e")
      expect(options[:env]["PATH"].split(File::PATH_SEPARATOR)).to eq(["/usr/local/bin", "/usr/bin", "/bin"])
      mock_shell_out(0, system_ruby_output, "")
    end
    plugin.run
  end

  it "reports the system's Ruby" do
    allow(plugin).to receive(:shell_out).and_return(mock_shell_out(0, system_ruby_output, ""))
    plugin.run
    expect(plugin[:languages][:ruby]).to eq(
      "platform" => "aarch64-linux-gnu",
      "version" => "3.2.3",
      "release_date" => "2024-01-18",
      "target" => "aarch64-unknown-linux-gnu",
      "target_cpu" => "aarch64",
      "target_vendor" => "unknown",
      "target_os" => "linux-gnu",
      "host" => "aarch64-unknown-linux-gnu",
      "host_cpu" => "aarch64",
      "host_os" => "linux-gnu",
      "host_vendor" => "unknown",
      "bin_dir" => "/usr/bin",
      "ruby_bin" => "/usr/bin/ruby3.2",
      "gem_bin" => "/usr/bin/gem3.2",
      "gems_dir" => "/var/lib/gems/3.2.0"
    )
  end

  it "does not set languages/ruby when the system has no Ruby" do
    allow(plugin).to receive(:shell_out).and_raise(Ohai::Exceptions::Exec)
    plugin.run
    expect(plugin[:languages]).not_to have_key(:ruby)
  end
end
