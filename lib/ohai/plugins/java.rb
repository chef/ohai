#
# Author:: Benjamin Black (<bb@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

Ohai.plugin(:Java) do
  provides "languages/java"
  depends "languages"

  def get_java_info
    java = Mash.new
    so = shell_out("java -mx64m -version")
    if so.exitstatus == 0
      so.stderr.split(/\r?\n/).each do |line|
        case line
        when /java version \"([0-9\.\_]+)\"/
          java[:version] = $1
        when /^(.+Runtime Environment.*) \((build)\s*(.+)\)$/
          java[:runtime] = { "name" => $1, "build" => $3 }
        when /^(.+ (Client|Server) VM) \(build\s*(.+)\)$/
          java[:hotspot] = { "name" => $1, "build" => $3 }
        end
      end

      languages[:java] = java if java[:version]
    end
  end

  # On Mac OS X, the development tools include "stubs" for JVM executables that
  # prompt the user to install the JVM if they desire. In our case we simply
  # wish to detect if the JVM is there and do not want to trigger a popup
  # window. As a workaround, we can run the java_home executable and check its
  # exit status to determine if the `java` executable is the real one or the OS
  # X stub. In the terminal, it looks like this:
  #
  #   $ /usr/libexec/java_home
  #   Unable to find any JVMs matching version "(null)".
  #   No Java runtime present, try --request to install.
  #
  #   $ echo $?
  #   1
  #
  # This check always returns true when not on darwin because it is just a
  # workaround for this particular annoyance.
  def has_real_java?
    return true unless on_darwin?
    shell_out("/usr/libexec/java_home").status.success?
  end

  def on_darwin?
    RUBY_PLATFORM.downcase.include?("darwin")
  end

  collect_data do
    get_java_info if has_real_java?
  end
end
