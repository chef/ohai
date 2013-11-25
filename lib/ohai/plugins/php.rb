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

Ohai.plugin(:PHP) do
  provides "languages/php"

  depends "languages"

  collect_data do
    output = nil

    php = Mash.new

    so = shell_out("php -v")
    if so.exitstatus == 0
      output = /PHP (\S+).+built: ([^)]+)/.match(so.stdout)
      if output
        php[:version] = output[1]
        php[:builddate] = output[2]
      end
      languages[:php] = php if php[:version]
    end
  end
end
