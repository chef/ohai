#
# Author:: Davide Cavalca <dcavalca@fb.com>
# Copyright:: Copyright (c) 2017 Facebook
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS"BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.dirname(__FILE__) + "/../../../spec_helper.rb")

describe Ohai::System, "Linux systemd paths plugin" do
  let(:plugin) { get_plugin("linux/systemd_paths") }

  before do
    allow(plugin).to receive(:collect_os).and_return(:linux)
  end

  it "populates systemd_paths if systemd-path is found" do
    systemd_path_out = <<~SYSTEMD_PATH_OUT
      temporary: /tmp
      temporary-large: /var/tmp
      system-binaries: /usr/bin
      system-include: /usr/include
      system-library-private: /usr/lib
      system-library-arch: /usr/lib/x86_64-linux-gnu
      system-shared: /usr/share
      system-configuration-factory: /usr/share/factory/etc
      system-state-factory: /usr/share/factory/var
      system-configuration: /etc
      system-runtime: /run
      system-runtime-logs: /run/log
      system-state-private: /var/lib
      system-state-logs: /var/log
      system-state-cache: /var/cache
      system-state-spool: /var/spool
      user-binaries: /home/foo/.local/bin
      user-library-private: /home/foo/.local/lib
      user-library-arch: /home/foo/.local/lib/x86_64-linux-gnu
      user-shared: /home/foo/.local/share
      user-configuration: /home/foo/.config
      user-runtime: /run/user/1000
      user-state-cache: /home/foo/.cache
      user: /home/foo
      user-documents: /home/foo/Documents
      user-music: /home/foo/Music
      user-pictures: /home/foo/Pictures
      user-videos: /home/foo/Videos
      user-download: /home/foo/Downloads
      user-public: /home/foo/Public
      user-templates: /home/foo/Templates
      user-desktop: /home/foo/Desktop
      search-binaries: /home/foo/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/opt/facebook/bin:/home/foo/.rvm/bin:/home/foo/.rvm/bin
      search-library-private: /home/foo/.local/lib:/usr/local/lib:/usr/lib:/lib
      search-library-arch: /home/foo/.local/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu
      search-shared: /home/foo/.local/share:/usr/share/gnome:/home/foo/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share
      search-configuration-factory: /usr/local/share/factory/etc:/usr/share/factory/etc
      search-state-factory: /usr/local/share/factory/var:/usr/share/factory/var
      search-configuration: /home/foo/.config:/etc
    SYSTEMD_PATH_OUT

    allow(plugin).to receive(:which).with("systemd-path").and_return("/bin/systemd-path")
    allow(plugin).to receive(:shell_out).with("/bin/systemd-path").and_return(mock_shell_out(0, systemd_path_out, ""))
    plugin.run
    expect(plugin[:systemd_paths].to_hash).to eq({
      "search-binaries" => "/home/foo/bin",
      "search-configuration" => "/home/foo/.config",
      "search-configuration-factory" => "/usr/local/share/factory/etc",
      "search-library-arch" => "/home/foo/.local/lib/x86_64-linux-gnu",
      "search-library-private" => "/home/foo/.local/lib",
      "search-shared" => "/home/foo/.local/share",
      "search-state-factory" => "/usr/local/share/factory/var",
      "system-binaries" => "/usr/bin",
      "system-configuration" => "/etc",
      "system-configuration-factory" => "/usr/share/factory/etc",
      "system-include" => "/usr/include",
      "system-library-arch" => "/usr/lib/x86_64-linux-gnu",
      "system-library-private" => "/usr/lib",
      "system-runtime" => "/run",
      "system-runtime-logs" => "/run/log",
      "system-shared" => "/usr/share",
      "system-state-cache" => "/var/cache",
      "system-state-factory" => "/usr/share/factory/var",
      "system-state-logs" => "/var/log",
      "system-state-private" => "/var/lib",
      "system-state-spool" => "/var/spool",
      "temporary" => "/tmp",
      "temporary-large" => "/var/tmp",
      "user" => "/home/foo",
      "user-binaries" => "/home/foo/.local/bin",
      "user-configuration" => "/home/foo/.config",
      "user-desktop" => "/home/foo/Desktop",
      "user-documents" => "/home/foo/Documents",
      "user-download" => "/home/foo/Downloads",
      "user-library-arch" => "/home/foo/.local/lib/x86_64-linux-gnu",
      "user-library-private" => "/home/foo/.local/lib",
      "user-music" => "/home/foo/Music",
      "user-pictures" => "/home/foo/Pictures",
      "user-public" => "/home/foo/Public",
      "user-runtime" => "/run/user/1000",
      "user-shared" => "/home/foo/.local/share",
      "user-state-cache" => "/home/foo/.cache",
      "user-templates" => "/home/foo/Templates",
      "user-videos" => "/home/foo/Videos",
    })
  end

  it "does not populate systemd paths if systemd-path is not found" do
    allow(plugin).to receive(:which).with("systemd-path").and_return(false)
    plugin.run
    expect(plugin[:systemd_paths]).to be(nil)
  end
end
