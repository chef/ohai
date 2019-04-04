
Ohai.plugin(:Passwd) do
  provides "etc", "current_user"
  optional true

  collect_data do
    unless etc
      etc Mash.new

      etc[:passwd] = Mash.new
      etc[:group] = Mash.new

      file_read('/etc/passwd').lines.each do |line|
        name, has_password, uid, gid, gecos, dir, shell = line.strip.split(':')
        user_passwd_entry = Mash.new(dir: dir, gid: gid.to_i, uid: uid.to_i, shell: shell, gecos: gecos)
        etc[:passwd][name] = user_passwd_entry unless etc[:passwd].key?(name)
      end

      file_read('/etc/group').lines.each do |line|
        name, has_password, gid, members = line.strip.split(':')
        etc[:group][name] = Mash.new(gid: gid.to_i, members: members.to_s.split(","))
      end
    end

    unless current_user
      current_user shell_out('whoami').stdout.chomp
    end
  end

  collect_data(:windows) do
    # Etc returns nil on Windows
  end
end
