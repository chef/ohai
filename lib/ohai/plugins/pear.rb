provides "languages/pear"

require_plugin "languages"

output = nil

pear = Mash.new

status, stdout, stderr = run_command(:no_status_check => true, :command => "pear info PEAR")

if status == 0
  output = stdout
  pear[:version] = output.grep(/Release Version/).to_s.chomp.split[2]
  pear[:builddate] = output.grep(/Release Date/).to_s.chomp.split[2]
  languages[:pear] = pear if pear[:version]
end
