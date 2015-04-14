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
    # Check for scala
    begin
      output = nil

      scala = Mash.new
      so = shell_out("scala -version")
      if so.exitstatus == 0
        output = so.stdout.split
        scala[:version] = output[4]
        languages[:scala] = scala if scala[:version]
      end
    end

    # Check for sbt
    begin
      output = nil

      so = shell_out("sbt --version")
      if so.exitstatus == 0
        output = so.stdout.split
        scala[:sbt] = output[3] if scala[:version]
      end
    end
  end
end
