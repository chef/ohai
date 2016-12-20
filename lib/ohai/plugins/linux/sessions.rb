#
# Author:: Davide Cavalca <dcavalca@fb.com>
# Copyright:: Copyright (c) 2016 Facebook
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

Ohai.plugin(:Sessions) do
  provides "sessions/by_session", "sessions/by_user"

  collect_data(:linux) do
    loginctl_path = which("loginctl")
    if loginctl_path
      cmd = "#{loginctl_path} --no-pager --no-legend --no-ask-password " +
        "list-sessions"
      loginctl = shell_out(cmd)

      sessions Mash.new unless sessions
      sessions[:by_session] = Mash.new unless sessions[:by_session]
      sessions[:by_user] = Mash.new unless sessions[:by_user]

      loginctl.stdout.split("\n").each do |line|
        session, uid, user, seat = line.split
        s = {
          "session" => session,
          "uid" => uid,
          "user" => user,
          "seat" => seat,
        }
        sessions[:by_session][session] = s
        if sessions[:by_user][user]
          sessions[:by_user][user] << s
        else
          sessions[:by_user][user] = [s]
        end
      end
    else
      Ohai::Log.debug("Plugin Sessions: Could not find loginctl. Skipping plugin.")
    end
  end
end
