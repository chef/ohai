# Author:: Christopher M Luciano (<cmlucian@us.ibm.com>)
# © Copyright IBM Corporation 2015.
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

Ohai.plugin(:Scala) do
  provides "languages/scala", "languages/scala/sbt"
  depends "languages"

  collect_data(:default) do
    scala = Mash.new
    begin
      so = shell_out("scala -version")
      # Sample output:
      # Scala code runner version 2.11.8 -- Copyright 2002-2016, LAMP/EPFL
      if so.exitstatus == 0
        scala[:version] = so.stderr.split[4]
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Plugin Scala: Could not shell_out "scala -version". Skipping data')
    end

    # Check for sbt
    begin
      # sbt launcher version 0.13.7
      so = shell_out("sbt --version")
      if so.exitstatus == 0
        scala[:sbt] = Mash.new
        scala[:sbt][:version] = so.stdout.split[3]
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Plugin Scala: Could not shell_out "sbt --version". Skipping data')
    end

    languages[:scala] = scala unless scala.empty?
  end
end
