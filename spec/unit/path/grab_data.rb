
# Author:: Theodore Nordsieck <theo@opscode.com>
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

##
## This is a simple tool to grab shell command output from the local machine.
##
## To use, edit the parameters before running the command.  This tool is meant
##   integrate the built in fake command data in spec/data/plugins.  If the
##   appropriate yaml file is in this directory, this tool will append/overwrite
##   the data in that file as appropriate.
##

require 'yaml'
require 'set'
require 'mixlib/shellout'
require File.expand_path(File.dirname(__FILE__) + '/ohai_plugin_common.rb')

####################################
#                                  #
#           Parameters             #
#                                  #
####################################
cmd = "ls"
params = ["", "-l", "-alF"]
platform = "osx"
arch = "intel"
env = []
opc = OhaiPluginCommon.new

# read in data
filename = cmd + ".output"

Mixlib::ShellOut.new("touch #{filename}").run_command
data = opc.read_output cmd, File.expand_path( File.dirname(__FILE__))
data ||= {}
data[platform] ||= {}
data[platform][arch] ||= []

# collect output

results = params.map do |p|
  m = Mixlib::ShellOut.new(cmd + ' ' + p)
  begin
    m.run_command
    {:env => env, :params => p, :stdout => m.stdout, :stderr => m.stderr, :exit_status => m.exitstatus }
  rescue Errno::ENOENT
    {:env => env, :params => p, :stdout => '', :stderr => 'command not found', :exit_status => 127 }
  end
end

# write out data

results.each do |r|
  data[platform][arch] = data[platform][arch].reject { |e| e[:params] == r[:params] && e[:env] == r[:env] }
  data[platform][arch] << r
end

File.write( filename, OhaiPluginCommon.new.data_to_string( data ))
