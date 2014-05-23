#
# Author:: Jacques Marneweck (<jacques@powertrip.co.za>)
# Author:: Theodore Nordsieck (<theo@opscode.com>)
# Copyright:: Copyright (c) Jacques Marneweck
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '/spec_helper.rb'))
require File.expand_path( File.join( File.dirname( __FILE__ ), '..', 'common', 'ohai_plugin_common.rb' ))

describe Ohai::System, "plugin nodejs" do
  test_plugin([ "languages", "nodejs" ], [ "node" ]) do | p |
    p.test([ "centos-6.4", "ubuntu-10.04", "ubuntu-12.04" ], [ "x86", "x64" ], [[]],
           { "languages" => { "nodejs" => nil }})
    p.test([ "ubuntu-13.04" ], [ "x64" ], [[]],
           { "languages" => { "nodejs" => nil }})
    p.test([ "centos-6.4", "ubuntu-10.04", "ubuntu-12.04" ], [ "x86", "x64" ], [[ "nodejs" ]],
           { "languages" => { "nodejs" => { "version" => "0.10.2" }}})
    p.test([ "ubuntu-13.04" ], [ "x64" ], [[ "nodejs" ]],
           { "languages" => { "nodejs" => { "version" => "0.10.2" }}})
  end
end
