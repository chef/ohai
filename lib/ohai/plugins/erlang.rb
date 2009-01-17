require_plugin "languages"
require "open3"

languages[:erlang] = Mash.new

stdin, stdout, stderr = Open3.popen3('erl +V')

output = stderr.gets
info = output.split

languages[:erlang][:version] = info[5]
languages[:erlang][:options] = info[1]
languages[:erlang][:emulator] = info[2]
