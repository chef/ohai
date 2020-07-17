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

module Ohai
  module Util
    module FileHelper
      def which(cmd)
        path_cmd = (collect_os == :windows) ? "echo %PATH%" : "echo $PATH"
        path = connection.run_command(path_cmd).stdout
        paths = path.split(File::PATH_SEPARATOR) + %w{/bin /usr/bin /sbin /usr/sbin}

        paths.each do |pathdir|
          filename = File.join(pathdir, cmd)
          backend_file_stat = connection.file(filename).stat

          # Train does not return stat information for Windows yet
          next if collect_os != :windows && backend_file_stat.empty?

          # Blanket accept for Windows or octal mode check for others
          if collect_os == :windows || (backend_file_stat[:mode] & 0111) > 0
            logger.trace("Plugin #{name}: found #{cmd} at #{filename}")
            return filename
          end
        end

        logger.trace("Plugin #{name}: did not find #{cmd}")
        false
      end

      def file_exist?(path)
        connection.file(path).exist?
      end

      def file_read(path)
        connection.file(path).content
      end
    end
  end
end
