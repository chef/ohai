#
# Author:: Paul Rossman (<paulrossman@google.com>)
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
    module DmiSignature

      # Checks for a simple signature from dmidecode.

      def has_signature?(signature)
        if File.exists?("/usr/sbin/dmidecode")
          d = Mixlib::ShellOut.new("/usr/sbin/dmidecode")
          d.run_command
          d.stdout.include?("#{signature}")
        end
      end

    end
  end
end
