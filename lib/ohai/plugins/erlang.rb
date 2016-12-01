#
# Author:: Joe Williams (<joe@joetify.com>)
# Copyright:: Copyright (c) 2008-2016 Chef Software, Inc.
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

Ohai.plugin(:Erlang) do
  provides "languages/erlang"
  depends "languages"

  collect_data do
    erlang = Mash.new

    begin
      so = shell_out("erl -eval '{ok, Ver} = file:read_file(filename:join([code:root_dir(), \"releases\", erlang:system_info(otp_release), \"OTP_VERSION\"])), Vsn = binary:bin_to_list(Ver, {0, byte_size(Ver) - 1}), io:format(\"~s,~s,~s\", [Vsn, erlang:system_info(version), erlang:system_info(nif_version)]), halt().' -noshell")
      # Sample output:
      # 19.1,8.1,2.11
      if so.exitstatus == 0
        output = so.stdout.split(",")
        erlang[:version] = output[0]
        erlang[:erts_version] = output[1]
        erlang[:nif_version] = output[2]
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Erlang plugin: Could not shell_out "erl -eval \'erlang:display(erlang:system_info(otp_release)), erlang:display(erlang:system_info(version)), erlang:display(erlang:system_info(nif_version)), halt().\'  -noshell". Skipping data')
    end

    begin
      so = shell_out("erl +V")
      # Sample output:
      # Erlang (SMP,ASYNC_THREADS,HIPE) (BEAM) emulator version 7.3
      if so.exitstatus == 0
        output = so.stderr.split
        if output.length >= 6
          options = output[1]
          options.gsub!(/(\(|\))/, "")
          erlang[:options] = options.split(",")
          erlang[:emulator] = output[2].gsub!(/(\(|\))/, "")
        end
      end
    rescue Ohai::Exceptions::Exec
      Ohai::Log.debug('Erlang plugin: Could not shell_out "erl +V". Skipping data')
    end

    languages[:erlang] = erlang unless erlang.empty?
  end
end
