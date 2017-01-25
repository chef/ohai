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

require_relative "../../spec_helper.rb"
require_relative "../common/ohai_plugin_common.rb"

describe Ohai::System, "plugin groovy" do
  test_plugin(%w{languages groovy}, [ "groovy" ]) do |p|
    p.test([ "centos-5.5", "ubuntu-12.10" ], [ "x64" ], [[]],
           { "languages" => { "groovy" => nil } })
    p.test([ "centos-6.2", "ubuntu-12.04", "ubuntu-13.04" ], %w{x86 x64}, [[]],
           { "languages" => { "groovy" => nil } })
    p.test([ "centos-5.5" ], [ "x64" ], [%w{java groovy}],
           { "languages" => { "groovy" => { "version" => "2.1.7" } } })
    p.test([ "centos-6.2" ], %w{x86 x64}, [%w{java groovy}],
           { "languages" => { "groovy" => { "version" => "2.1.7" } } })
    p.test([ "ubuntu-10.04" ], %w{x86 x64}, [%w{java groovy}],
           { "languages" => { "groovy" => { "version" => "1.6.4" } } })
    p.test([ "ubuntu-12.04", "ubuntu-13.04" ], %w{x86 x64}, [%w{java groovy}],
           { "languages" => { "groovy" => { "version" => "1.8.6" } } })
    p.test([ "ubuntu-12.10" ], [ "x64" ], [%w{java groovy}],
           { "languages" => { "groovy" => { "version" => "1.8.6" } } })
  end
end
