
# Author:: Doug MacEachern <dougm@vmware.com>
# Copyright:: Copyright (c) 2010 VMware, Inc.
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

require 'rbconfig'

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '/spec_helper.rb'))
require File.expand_path( File.join( File.dirname( __FILE__ ), '..', 'common', 'ohai_plugin_common.rb' ))

describe Ohai::System, "plugin c" do
  test_plugin([ "languages", "c" ], [ "/lib/libc.so.6", "/lib64/libc.so.6", "gcc", "cl", "devenv.com", "xlc", "cc", "what" ]) do | p |
    p.test([ "centos-5.5" ], [ "x64" ], [[]], { "languages" => { "c" => {
                 "gcc" => { "version" => "4.1.2", "description" => "gcc version 4.1.2 20080704 (Red Hat 4.1.2-48)" },
                 "glibc" => { "version" => "2.5" , "description" => "GNU C Library stable release version 2.5, by Roland McGrath et al." },
                 "cl" => nil, "vs" => nil, "xlc" => nil, "sunpro" => nil, "hpcc" => nil }}})
    p.test([ "centos-6.2" ], [ "x86", "x64" ], [[]], { "languages" => { "c" => {
                 "gcc" => { "version" => "4.4.6", "description" => "gcc version 4.4.6 20110731 (Red Hat 4.4.6-3) (GCC) " },
                 "glibc" => { "version" => "2.12", "description" => "GNU C Library stable release version 2.12, by Roland McGrath et al." },
                 "cl" => nil, "vs" => nil, "xlc" => nil, "sunpro" => nil, "hpcc" => nil }}})
    p.test([ "ubuntu-10.04" ], [ "x86", "x64" ], [[]],
           { "languages" => { "c" => {
                 "glibc" => { "version" => "2.11.1", "description" => "GNU C Library (Ubuntu EGLIBC 2.11.1-0ubuntu7.12) stable release version 2.11.1, by Roland McGrath et al." },
                 "gcc" => nil, "cl" => nil, "vs" => nil, "xlc" => nil, "sunpro" => nil, "hpcc" => nil }}})
    p.test([ "ubuntu-12.04", "ubuntu-13.04" ], [ "x86", "x64" ], [[]], { "languages" => { "c" => nil }}, "OC-9993")
    p.test([ "ubuntu-12.10" ], [ "x64" ], [[]], { "languages" => { "c" => nil }}, "OC-9993")
    p.test([ "centos-5.5" ], [ "x64" ], [[ "gcc" ]], { "languages" => { "c" => {
                 "gcc" => { "version" => "4.1.2", "description" => "gcc version 4.1.2 20080704 (Red Hat 4.1.2-54)" },
                 "glibc" => { "version" => "2.5", "description" => "GNU C Library stable release version 2.5, by Roland McGrath et al." },
                 "cl" => nil, "vs" => nil, "xlc" => nil, "sunpro" => nil, "hpcc" => nil }}})
    p.test([ "centos-6.2" ], [ "x86", "x64" ], [[ "gcc" ]], { "languages" => { "c" => {
                 "gcc" => { "version" => "4.4.7", "description" => "gcc version 4.4.7 20120313 (Red Hat 4.4.7-3) (GCC) " },
                 "glibc" => { "version" => "2.12", "description" => "GNU C Library stable release version 2.12, by Roland McGrath et al." },
                 "cl" => nil, "vs" => nil, "xlc" => nil, "sunpro" => nil, "hpcc" => nil }}})
    p.test([ "ubuntu-10.04" ], [ "x86", "x64" ], [[ "gcc" ]], { "languages" => { "c" => {
                 "gcc" => { "version" => "4.4.3", "description" => "gcc version 4.4.3 (Ubuntu 4.4.3-4ubuntu5.1) " },
                 "glibc" => { "version" => "2.11.1", "description" => "GNU C Library (Ubuntu EGLIBC 2.11.1-0ubuntu7.12) stable release version 2.11.1, by Roland McGrath et al." },
                 "cl" => nil, "vs" => nil, "xlc" => nil, "sunpro" => nil, "hpcc" => nil }}})
    p.test([ "ubuntu-12.04" ], [ "x86", "x64" ], [[ "gcc" ]], { "languages" => { "c" => {
                 "gcc" => { "version" => "4.6.3", "description" => "gcc verison 4.6.3 (Ubuntu/Linaro 4.6.3-1ubuntu5) " },
                 "glibc" => nil, "cl" => nil, "vs" => nil, "xlc" => nil, "sunpro" => nil, "hpcc" => nil }}}, "OC-9993" )
  end
end
