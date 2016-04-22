#
# Author:: Doug MacEachern <dougm@vmware.com>
# Copyright:: Copyright (c) 2009 VMware, Inc.
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

Ohai.plugin(:Mono) do
  provides "languages/mono"
  depends "languages"

  collect_data do
    begin
      so = shell_out("mono -V")
      # Sample output:
      # Mono JIT compiler version 4.2.3 (Stable 4.2.3.4/832de4b Wed Mar 30 13:57:48 PDT 2016)
      # Copyright (C) 2002-2014 Novell, Inc, Xamarin Inc and Contributors. www.mono-project.com
      # 	TLS:           normal
      # 	SIGSEGV:       altstack
      # 	Notification:  kqueue
      # 	Architecture:  amd64
      # 	Disabled:      none
      # 	Misc:          softdebug
      # 	LLVM:          supported, not enabled.
      # 	GC:            sgen
      if so.exitstatus == 0
        mono = Mash.new
        output = so.stdout.split
        mono[:version] = output[4] unless output[4].nil?
        if output.length >= 12
          mono[:builddate] = "%s %s %s %s %s %s" % [output[7], output[8], output[9], output[10], output[11], output[12].delete!(")")]
        end
        languages[:mono] = mono unless mono.empty?
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Mono plugin: Could not shell_out "mono -V". Skipping plugin')
    end
  end
end
