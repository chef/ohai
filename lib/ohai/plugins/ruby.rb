#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

ruby Mash.new

ruby[:platform] = RUBY_PLATFORM
ruby[:version] = RUBY_VERSION
ruby[:release_date] = RUBY_RELEASE_DATE
ruby[:target] = ::Config::CONFIG['target']
ruby[:target_cpu] = ::Config::CONFIG['target_cpu']
ruby[:target_vendor] = ::Config::CONFIG['target_vendor']
ruby[:target_os] = ::Config::CONFIG['target_os']
ruby[:host] = ::Config::CONFIG['host']
ruby[:host_cpu] = ::Config::CONFIG['host_cpu']
ruby[:host_os] = ::Config::CONFIG['host_os']
ruby[:host_vendor] = ::Config::CONFIG['host_vendor']
