#
# Author:: Joshua Timberman (<joshua@chef.io>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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

Ohai.plugin(:Perl) do
  provides "languages/perl"
  depends "languages"

  collect_data do
    begin
      so = shell_out("perl -V:version -V:archname")
      # Sample output:
      # version='5.18.2';
      # archname='darwin-thread-multi-2level';
      if so.exitstatus == 0
        perl = Mash.new
        so.stdout.split(/\r?\n/).each do |line|
          case line
          when /^version=\'(.+)\';$/
            perl[:version] = $1
          when /^archname=\'(.+)\';$/
            perl[:archname] = $1
          end
        end
        languages[:perl] = perl unless perl.empty?
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Perl plugin: Could not shell_out "perl -V:version -V:archname". Skipping plugin')
    end
  end
end
