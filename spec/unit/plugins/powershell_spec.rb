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

require "spec_helper"

describe Ohai::System, "plugin powershell" do
  let(:plugin) { get_plugin("powershell") }

  before do
    stub_const("::RbConfig::CONFIG", { "host_os" => "windows" })
  end

  before do
    plugin[:languages] = Mash.new
  end

  it "sets languages[:powershell] from a single powershell.exe run" do
    v51_output = <<~END
      PSVersion=5.1.26100.1
      PSEdition=Desktop
      PSCompatibleVersions=1.0,2.0,3.0,4.0,5.0,5.1.26100.1
      BuildVersion=10.0.26100.1
      CLRVersion=4.0.30319.42000
      WSManStackVersion=3.0
      PSRemotingProtocolVersion=2.3
      SerializationVersion=1.1.0.1
    END

    expect(plugin).to receive(:shell_out).once.with(/\Apowershell\.exe .*\$PSVersionTable\.GetEnumerator\(\)/).and_return(mock_shell_out(0, v51_output, ""))
    plugin.run
    expect(plugin.languages[:powershell][:version]).to eql("5.1.26100.1")
    expect(plugin.languages[:powershell][:edition]).to eql("Desktop")
    expect(plugin.languages[:powershell][:ws_man_stack_version]).to eql("3.0")
    expect(plugin.languages[:powershell][:serialization_version]).to eql("1.1.0.1")
    expect(plugin.languages[:powershell][:clr_version]).to eql("4.0.30319.42000")
    expect(plugin.languages[:powershell][:build_version]).to eql("10.0.26100.1")
    expect(plugin.languages[:powershell][:compatible_versions]).to eql(["1.0", "2.0", "3.0", "4.0", "5.0", "5.1.26100.1"])
    expect(plugin.languages[:powershell][:remoting_protocol_version]).to eql("2.3")
  end

  it "handles Windows line endings and missing values" do
    output = "PSVersion=4.0\r\nCLRVersion=\r\nPSCompatibleVersions=1.0,2.0,3.0,4.0\r\n"

    allow(plugin).to receive(:shell_out).and_return(mock_shell_out(0, output, ""))
    plugin.run
    expect(plugin.languages[:powershell][:version]).to eql("4.0")
    expect(plugin.languages[:powershell][:clr_version]).to eql("")
    expect(plugin.languages[:powershell][:build_version]).to be_nil
    expect(plugin.languages[:powershell][:compatible_versions]).to eql(["1.0", "2.0", "3.0", "4.0"])
  end

  it "does not set the languages[:powershell] tree up if powershell command fails" do
    error_output = <<~END
      'powershell.exe' is not recognized as an internal or external command,
      operable program or batch file.
    END

    allow(plugin).to receive(:shell_out).with(anything).and_return(mock_shell_out(1, error_output, ""))
    plugin.run
    expect(plugin.languages).not_to have_key(:powershell)
  end

  it "does not set the languages[:powershell] tree up if the output has no PSVersion" do
    allow(plugin).to receive(:shell_out).and_return(mock_shell_out(0, "", ""))
    plugin.run
    expect(plugin.languages).not_to have_key(:powershell)
  end

  context "when powershell.exe times out" do
    before do
      allow(plugin).to receive(:shell_out).and_wrap_original do
        raise Mixlib::ShellOut::CommandTimeout, "timed out"
      rescue Mixlib::ShellOut::CommandTimeout => e
        raise Ohai::Exceptions::Exec, e
      end
    end

    it "logs a warning and does not set languages[:powershell]" do
      expect(plugin.logger).to receive(:warn).with(/timed out/)
      plugin.run
      expect(plugin.languages).not_to have_key(:powershell)
    end
  end

  context "when powershell.exe is not installed" do
    before do
      allow(plugin).to receive(:shell_out).and_wrap_original do
        raise Errno::ENOENT, "powershell.exe"
      rescue Errno::ENOENT => e
        raise Ohai::Exceptions::Exec, e
      end
    end

    it "does not warn and does not set languages[:powershell]" do
      expect(plugin.logger).not_to receive(:warn)
      plugin.run
      expect(plugin.languages).not_to have_key(:powershell)
    end
  end

  %w{darwin linux}.each do |os|
    context "on #{os} with PowerShell 7" do
      # $PSVersionTable from pwsh 7.7.0 on macOS 27.2
      let(:pwsh_output) do
        <<~END
          PSEdition=Core
          GitCommitId=7.7.0
          PSRemotingProtocolVersion=2.4
          SerializationVersion=1.1.0.1
          PSCompatibleVersions=1.0,2.0,3.0,4.0,5.0,5.1,6.0,7.0
          Platform=Unix
          WSManStackVersion=3.0
          OS=macOS 27.2.0
          PSVersion=7.7.0
        END
      end

      before do
        stub_const("::RbConfig::CONFIG", { "host_os" => os })
      end

      it "runs pwsh with an argument list, so the shell can't expand the script" do
        expect(plugin).to receive(:shell_out).once
          .with(["pwsh", "-NoLogo", "-NonInteractive", "-NoProfile", "-Command", a_string_including("$PSVersionTable.GetEnumerator()")])
          .and_return(mock_shell_out(0, pwsh_output, ""))
        plugin.run
      end

      it "sets languages[:powershell]" do
        allow(plugin).to receive(:shell_out).and_return(mock_shell_out(0, pwsh_output, ""))
        plugin.run
        expect(plugin.languages[:powershell][:version]).to eql("7.7.0")
        expect(plugin.languages[:powershell][:edition]).to eql("Core")
        expect(plugin.languages[:powershell][:compatible_versions]).to eql(["1.0", "2.0", "3.0", "4.0", "5.0", "5.1", "6.0", "7.0"])
        expect(plugin.languages[:powershell][:remoting_protocol_version]).to eql("2.4")
        expect(plugin.languages[:powershell][:clr_version]).to be_nil
        expect(plugin.languages[:powershell][:build_version]).to be_nil
      end

      it "does not set languages[:powershell] when pwsh isn't installed" do
        allow(plugin).to receive(:shell_out).and_wrap_original do
          raise Errno::ENOENT, "pwsh"
        rescue Errno::ENOENT => e
          raise Ohai::Exceptions::Exec, e
        end
        expect(plugin.logger).not_to receive(:warn)
        plugin.run
        expect(plugin.languages).not_to have_key(:powershell)
      end
    end
  end
end
