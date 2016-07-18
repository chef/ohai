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
    begin
      so = shell_out("php -v")
      # Sample output:
      # PHP 5.5.31 (cli) (built: Feb 20 2016 20:33:10)
      # Copyright (c) 1997-2015 The PHP Group
      # Zend Engine v2.5.0, Copyright (c) 1998-2015 Zend Technologies
      if so.exitstatus == 0
        php = Mash.new
        so.stdout.each_line do |line|
          case line
          when /^PHP (\S+)(?:.*built: ([^)]+))?/
            php[:version] = $1
            php[:builddate] = $2
          when /Zend Engine v([^\s]+),/
            php[:zend_engine_version] = $1
          when /Zend OPcache v([^\s]+),/
            php[:zend_opcache_version] = $1
          end
        end

        languages[:php] = php unless php.empty?
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Php plugin: Could not shell_out "php -v". Skipping plugin')
    end
  end
end
