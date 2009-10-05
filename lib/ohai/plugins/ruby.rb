#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

provides "languages/ruby"

require_plugin "languages"

def run_ruby(command)
  cmd = "ruby -e \"require 'rbconfig'; #{command}\""
  status, stdout, stderr = run_command(:no_status_check => true, :command => cmd)
  stdout.strip
end

languages[:ruby] = Mash.new

languages[:ruby][:platform] = run_ruby "puts RUBY_PLATFORM"
languages[:ruby][:version] = run_ruby "puts RUBY_VERSION"
languages[:ruby][:release_date] = run_ruby "puts RUBY_RELEASE_DATE"
languages[:ruby][:target] = run_ruby "puts ::Config::CONFIG['target']"
languages[:ruby][:target_cpu] = run_ruby "puts ::Config::CONFIG['target_cpu']"
languages[:ruby][:target_vendor] = run_ruby "puts ::Config::CONFIG['target_vendor']"
languages[:ruby][:target_os] = run_ruby "puts ::Config::CONFIG['target_os']"
languages[:ruby][:host] = run_ruby "puts ::Config::CONFIG['host']"
languages[:ruby][:host_cpu] = run_ruby "puts ::Config::CONFIG['host_cpu']"
languages[:ruby][:host_os] = run_ruby "puts ::Config::CONFIG['host_os']"
languages[:ruby][:host_vendor] = run_ruby "puts ::Config::CONFIG['host_vendor']"

bin_dir = run_ruby("puts ::Config::CONFIG['bindir']")
if File.exist?("#{bin_dir}\/gem")
	languages[:ruby][:gems_dir] = run_ruby "puts %x{#{bin_dir}\/gem env gemdir}.chomp!"
end
languages[:ruby][:ruby_bin] = run_ruby "puts File.join(::Config::CONFIG['bindir'], ::Config::CONFIG['ruby_install_name'])"
