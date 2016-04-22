# Author:: Christian Vozar (<christian@rogueethic.com>)
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

Ohai.plugin(:Go) do
  provides "languages/go"
  depends "languages"

  collect_data do
    begin
      so = shell_out("go version")
      # Sample output:
      # go version go1.6.1 darwin/amd64
      if so.exitstatus == 0 && so.stdout =~ /go(\S+)/
        go = Mash.new
        go[:version] = $1
        languages[:go] = go
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Go plugin: Could not shell_out "go version". Skipping plugin')
    end
  end
end
