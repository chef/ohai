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

# read in data
filename = cmd + ".yaml"

Mixlib::ShellOut.new("touch #{filename}").run_command
data = YAML::load_file filename
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

File.write( filename, data.to_yaml )
