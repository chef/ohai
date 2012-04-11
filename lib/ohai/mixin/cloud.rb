#
# Author:: Eric Hankins (<ehankins@rednovalabs.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


module Ohai
  module Mixin
    module Cloud
      CLOUD_FILE = File.join(File::SEPARATOR, 'etc', 'cloud')

      def cloud_file?(check)
        if File.exist? CLOUD_FILE
          contents = File.read(CLOUD_FILE)
          has_it = contents == check
        else
          has_it = false
        end
        Ohai::Log.debug("cloud_file? == #{has_it}")
        has_it
      end
      
    end
  end
end

