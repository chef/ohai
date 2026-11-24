#
# Author:: Thom May (<thom@clearairturbulence.org>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

Ohai.plugin(:Python) do
  provides "languages/python"

  depends "languages".freeze

  # Try "python" first, so systems where it works report what they always
  # have; current distros only install "python3".
  #
  # @return [Mixlib::ShellOut, nil] the first interpreter that reports its version
  def python_version_output
    %w{python python3}.each do |python|
      so = shell_out("#{python} -c \"import sys; print (sys.version)\"")
      return so if so.exitstatus == 0
    rescue Ohai::Exceptions::Exec
      logger.trace("Plugin Python: Could not shell_out \"#{python}\". Trying the next interpreter")
    end
    nil
  end

  collect_data do
    so = python_version_output
    # Sample output:
    # 3.11.2 (main, Mar 13 2023, 12:18:29) [GCC 12.2.0]
    # 2.7.11 (default, Dec 26 2015, 17:47:53)
    # [GCC 4.2.1 Compatible Apple LLVM 7.0.2 (clang-700.1.81)]
    if so
      python = Mash.new
      output = so.stdout.split
      python[:version] = output[0]
      if output.length >= 6
        python[:builddate] = "%s %s %s %s" % [output[2], output[3], output[4], output[5].delete!(")")]
      end
      languages[:python] = python unless python.empty?
    else
      logger.trace("Plugin Python: Neither python nor python3 reported a version. Skipping plugin")
    end
  end
end
