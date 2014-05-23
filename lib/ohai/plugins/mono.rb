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
    output = nil

    mono = Mash.new

    so = shell_out("mono -V")
    if so.exitstatus == 0
      output = so.stdout.split
      if output.length >= 4
        mono[:version] = output[4]
      end
      if output.length >= 11
        mono[:builddate] = "%s %s %s %s" % [output[6],output[7],output[8],output[11].gsub!(/\)/,'')]
      end
      languages[:mono] = mono if mono[:version]
    end
  end
end
