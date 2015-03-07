# Author:: Dave Parfitt (<dparfitt@chef.io>)
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

Ohai.plugin(:Haskell) do
  provides "languages/haskell"
  depends "languages"

  collect_data do
    output = nil
    haskell = Mash.new
    so = shell_out("ghc --version")
    if so.exitstatus == 0
      output =  so.stdout.split
      haskell[:version] = output[7]
      languages[:haskell] = haskell if haskell[:version]
    end
  end
end
