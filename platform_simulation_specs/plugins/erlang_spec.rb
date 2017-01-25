#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Theodore Nordsieck (<theo@chef.io>)
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

require_relative "../../spec_helper.rb"
require_relative "../common/ohai_plugin_common.rb"

describe Ohai::System, "plugin erlang" do
  test_plugin(%w{languages erlang}, [ "erl" ]) do |p|
    p.test([ "centos-5.9", "centos-6.4", "ubuntu-10.04", "ubuntu-12.04" ], %w{x86 x64}, [[]],
           { "languages" => { "erlang" => nil } })
    p.test([ "ubuntu-13.04" ], [ "x64" ], [[]],
           { "languages" => { "erlang" => nil } })
    p.test([ "centos-5.9", "centos-6.4" ], %w{x86 x64}, [[ "erlang" ]],
           { "languages" => { "erlang" => { "version" => "5.8.5", "options" => [ "ASYNC_THREADS" ], "emulator" => "BEAM" } } })
    p.test([ "ubuntu-10.04" ], %w{x86 x64}, [[ "erlang" ]],
           { "languages" => { "erlang" => { "version" => "5.7.4", "options" => %w{ASYNC_THREADS HIPE}, "emulator" => "BEAM" } } })
    p.test([ "ubuntu-12.04" ], %w{x86 x64}, [[ "erlang" ]],
           { "languages" => { "erlang" => { "version" => "5.8.5", "options" => [ "ASYNC_THREADS" ], "emulator" => "BEAM" } } })
    p.test([ "ubuntu-13.04" ], [ "x64" ], [[ "erlang" ]],
           { "languages" => { "erlang" => { "version" => "5.9.1", "options" => [ "ASYNC_THREADS" ], "emulator" => "BEAM" } } })
  end
end
