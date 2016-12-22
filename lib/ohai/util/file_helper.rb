# Author:: Lamont Granquist (<lamont@chef.io>)
#
# Copyright:: Copyright (c) 2013-14 Chef Software, Inc.
#
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

# Copied from chef/lib/chef/util/selinux.rb

module Ohai
  module Util
    module FileHelper
      def which(cmd)
        paths = ENV["PATH"].split(File::PATH_SEPARATOR) + [ "/bin", "/usr/bin", "/sbin", "/usr/sbin" ]
        paths.each do |path|
          filename = File.join(path, cmd)
          if File.executable?(filename)
            Ohai::Log.debug("Plugin #{self.name}: found #{cmd} at #{filename}")
            return filename
          end
        end
        Ohai::Log.debug("Plugin #{self.name}: did not find #{cmd}")
        false
      end
    end
  end
end
