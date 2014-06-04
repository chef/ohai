#
# Author:: Benjamin Black (<bb@opscode.com>)
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

describe Ohai::System, "plugin java (Java5 Client VM)" do
  test_plugin([ "languages", "java" ], [ "java" ]) do | p |
    p.test([ "centos-5.9", "centos-6.4", "ubuntu-10.04", "ubuntu-12.04" ], [ "x86", "x64" ], [[]],
           { "languages" => { "java" => nil }})
    p.test([ "ubuntu-13.04" ], [ "x64" ], [[]],
           { "languages" => { "java" => nil }})
    p.test([ "centos-5.9" ], [ "x86" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_24",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.11.11.90)", "build" => "rhel-1.41.1.11.11.90.el5_9-i386" },
                 "hotspot" => { "name" => "OpenJDK Client VM", "build" => "20.0-b12, mixed mode" }}}})
    p.test([ "centos-5.9" ], [ "x64" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_24",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.11.11.90)", "build" => "rhel-1.41.1.11.11.90.el5_9-x86_64" },
                 "hotspot" => { "name" => "OpenJDK 64-Bit Server VM", "build" => "20.0-b12, mixed mode" }}}})
    p.test([ "centos-6.4" ], [ "x86" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_24",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.11.11.90)", "build" => "rhel-1.62.1.11.11.90.el6_4-i386" },
                 "hotspot" => { "name" => "OpenJDK Client VM", "build" => "20.0-b12, mixed mode" }}}})
    p.test([ "centos-6.4" ], [ "x64" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_24",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.11.11.90)", "build" => "rhel-1.62.1.11.11.90.el6_4-x86_64" },
                 "hotspot" => { "name" => "OpenJDK 64-Bit Server VM", "build" => "20.0-b12, mixed mode" }}}})
    p.test([ "ubuntu-10.04" ], [ "x86" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_27",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.12.5)", "build" => "6b27-1.12.5-0ubuntu0.10.04.1" },
                 "hotspot" => { "name" => "OpenJDK Client VM", "build" => "20.0-b12, mixed mode, sharing" }}}})
    p.test([ "ubuntu-10.04" ], [ "x64" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_27",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.12.5)", "build" => "6b27-1.12.5-0ubuntu0.10.04.1" },
                 "hotspot" => { "name" => "OpenJDK 64-Bit Server VM", "build" => "20.0-b12, mixed mode" }}}})
    p.test([ "ubuntu-12.04" ], [ "x86" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_27",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.12.5)", "build" => "6b27-1.12.5-0ubuntu0.12.04.1" },
                 "hotspot" => { "name" => "OpenJDK Client VM", "build" => "20.0-b12, mixed mode, sharing" }}}})
    p.test([ "ubuntu-12.04" ], [ "x64" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_27",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.12.5)", "build" => "6b27-1.12.5-0ubuntu0.12.04.1" },
                 "hotspot" => { "name" => "OpenJDK 64-Bit Server VM", "build" => "20.0-b12, mixed mode" }}}})
    p.test([ "ubuntu-13.04" ], [ "x64" ], [["java"]],
           { "languages" => { "java" => { "version" => "1.6.0_27",
                 "runtime" => { "name" => "OpenJDK Runtime Environment (IcedTea6 1.12.5)", "build" => "6b27-1.12.5-1ubuntu1" },
                 "hotspot" => { "name" => "OpenJDK 64-Bit Server VM", "build" => "20.0-b12, mixed mode" }}}})
  end
end
