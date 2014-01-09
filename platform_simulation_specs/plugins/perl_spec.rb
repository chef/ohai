#
# Author:: Joshua Timberman(<joshua@opscode.com>)
# Author:: Theodore Nordsieck (<theo@opscode.com>)
# Copyright:: Copyright (c) 2009-2013 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require File.expand_path( File.join( File.dirname( __FILE__ ), '..', 'common', 'ohai_plugin_common.rb' ))

describe Ohai::System, "plugin perl" do
  test_plugin([ "languages", "perl" ], [ "perl" ]) do | p |
    p.test([ "centos-5.9" ], [ "x86" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.8.8", "archname" => "i386-linux-thread-multi" }}})
    p.test([ "centos-5.9" ], [ "x64" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.8.8", "archname" => "x86_64-linux-thread-multi" }}})
    p.test([ "centos-6.4" ], [ "x86" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.10.1", "archname" => "i386-linux-thread-multi" }}})
    p.test([ "centos-6.4" ], [ "x64" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.10.1", "archname" => "x86_64-linux-thread-multi" }}})
    p.test([ "ubuntu-10.04" ], [ "x86" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.10.1", "archname" => "i486-linux-gnu-thread-multi" }}})
    p.test([ "ubuntu-10.04" ], [ "x64" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.10.1", "archname" => "x86_64-linux-gnu-thread-multi" }}})
    p.test([ "ubuntu-12.04" ], [ "x86" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.14.2", "archname" => "i686-linux-gnu-thread-multi-64int" }}})
    p.test([ "ubuntu-12.04", "ubuntu-13.04" ], [ "x64" ], [[], [ "perl" ]],
           { "languages" => { "perl" => { "version" => "5.14.2", "archname" => "x86_64-linux-gnu-thread-multi" }}})
  end
end
