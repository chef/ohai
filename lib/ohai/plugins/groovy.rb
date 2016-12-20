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

Ohai.plugin(:Groovy) do
  provides "languages/groovy"
  depends "languages"

  collect_data do
    begin
      so = shell_out("groovy -v")
      # Sample output:
      # Groovy Version: 2.4.6 JVM: 1.8.0_60 Vendor: Oracle Corporation OS: Mac OS X
      if so.exitstatus == 0 && so.stdout =~ /Groovy Version: (\S+).*JVM: (\S+)/
        groovy = Mash.new
        groovy[:version] = $1
        groovy[:jvm] = $2
        languages[:groovy] = groovy
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Plugin Groovy: Could not shell_out "groovy -v". Skipping plugin')
    end
  end
end
