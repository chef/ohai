#
# Author:: Doug MacEachern <dougm@vmware.com>
# Author:: Tim Smith <tim@cozy.co>
# Copyright:: Copyright (c) 2009 VMware, Inc.
# Copyright:: Copyright (c) 2014 Cozy Services, Ltd.
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
    php = Mash.new

    so = shell_out("php -v")
    if so.exitstatus == 0
      so.stdout.each_line do |line|
        case line
        when /PHP (\S+).+built: ([^)]+)/
          php[:version] = $1
          php[:builddate] = $2
        when /Zend Engine v([^\s]+),/
          php[:zend_engine_version] = $1
        when /Zend OPcache v([^\s]+),/
          php[:zend_opcache_version] = $1
        end
      end

      languages[:php] = php if php[:version]
    end
  end
end
