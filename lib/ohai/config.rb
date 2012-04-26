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

require 'mixlib/config'

module Ohai
  class Config
    extend Mixlib::Config
    
    # from chef/config.rb, should maybe be moved to mixlib-config?
    def self.platform_specific_path(path)
      if RUBY_PLATFORM =~ /mswin|mingw|windows/
        # turns /etc/chef/client.rb into C:/chef/client.rb
        path = File.join(ENV['SYSTEMDRIVE'], path.split('/')[2..-1])
        # ensure all forward slashes are backslashes
        path.gsub!(File::SEPARATOR, (File::ALT_SEPARATOR || '\\'))
      end
      path
    end
    

    log_level :info
    log_location STDOUT
    plugin_path [ File.expand_path(File.join(File.dirname(__FILE__), 'plugins'))]
    disabled_plugins []
    hints_path [ platform_specific_path('/etc/chef/ohai/hints') ]
  end
end
