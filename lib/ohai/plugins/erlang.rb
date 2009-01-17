require_plugin "languages"
require "open3"
 
languages[:erlang] = Mash.new
 
stdin, stdout, stderr = Open3.popen3('erl +V')
 
output = stderr.gets.split

languages[:erlang][:version] = output[5]
languages[:erlang][:options] = output[1]
languages[:erlang][:emulator] = output[2]
