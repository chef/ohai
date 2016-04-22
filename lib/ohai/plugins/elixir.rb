# Author:: Christopher M Luciano (<cmlucian@us.ibm.com>)
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

Ohai.plugin(:Elixir) do
  provides "languages/elixir"
  depends "languages"

  collect_data do
    begin
      so = shell_out("elixir -v")
      # Sample output:
      # Erlang/OTP 18 [erts-7.3] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]
      #
      # Elixir 1.2.4
      if so.exitstatus == 0 && so.stdout =~ /^Elixir (\S*)/
        elixir = Mash.new
        elixir[:version] = $1
        languages[:elixir] = elixir
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Elixir plugin: Could not shell_out "elixir -v". Skipping plugin')
    end
  end
end
