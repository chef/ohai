Ohai.plugin(:Passwd) do
  provides "loggedin_user"

  collect_data(:darwin) do
    unless loggedin_user
      loggedin_user shell_out("stat -f \'\%Su\' /dev/console").stdout.chop
    end
  end
end
