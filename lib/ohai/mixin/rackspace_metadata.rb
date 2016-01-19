#
# Author:: Alexey Karpik <alexey.karpik@rightscale.com>
# Author:: Cary Penniman (<cary@rightscale.com>)
# Author:: Peter Schroeter <peter.schroeter@rightscale.com>
# Author:: Stas Turlo <stanislav.turlo@rightscale.com>
# Copyright:: Copyright (c) 2010-2014 RightScale Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "resolv"
require "json"

module ::Ohai::Mixin::RackspaceMetadata
  def on_windows?
    RUBY_PLATFORM =~ /windows|cygwin|mswin|mingw|bccwin|wince|emx/
  end

  def xenstore_command(command, args)
    if on_windows?
      xen_store_client_path = '"c:\Program Files\Citrix\XenTools\xenstore_client.exe"'
      xen_store_client_alt  = "powershell -NoProfile -NonInteractive -InputFormat None -ExecutionPolicy Bypass \"#{File.join(File.dirname(__FILE__), "xenstore_client.ps1")}\""
      client = File.exists?(xen_store_client_path.tr('"', '')) ? xen_store_client_path : xen_store_client_alt
      if command == "ls"
        command = "dir"
      end
    else
      client = "xenstore"
    end
    command = "#{client} #{command} #{args}"
    begin
      status, stdout, stderr = run_command(:no_status_check => true, :command => command)
      status = status.exitstatus if status.respond_to?(:exitstatus)
    rescue Ohai::Exceptions::Exec => e
      Ohai::Log.debug("xenstore command '#{command}' failed (#{e.class}: #{e.message})")
      stdout = stderr = nil
      status = 1
    end
    [status, stdout, stderr]
  end
end
