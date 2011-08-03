provides 'etc', 'current_user'

require 'etc'

unless etc
  etc Mash.new

  etc[:passwd] = Mash.new
  etc[:group] = Mash.new

  if File.exists?("/etc/passwd") && File.exists?("/etc/group")
    File.readlines("/etc/passwd").each do |line|
      splitline = line.chomp.split(":")
      etc[:passwd][splitline[0]] = Mash.new(:dir => splitline[5], :gid => splitline[2].to_i, :uid => splitline[3].to_i, :shell => splitline[6], :gecos => splitline[4])
    end
  
    File.readlines("/etc/group").each do |line|
      splitline = line.chomp.split(":")
      g_members = splitline[3..-1].join.split(",")
      etc[:group][splitline[0]] = Mash.new(:gid => splitline[2].to_i, :members => g_members)
    end
  else
    Etc.passwd do |entry|
      etc[:passwd][entry.name] = Mash.new(:dir => entry.dir, :gid => entry.gid, :uid => entry.uid, :shell => entry.shell, :gecos => entry.gecos)
    end
    
    Etc.group do |entry|
      etc[:group][entry.name] = Mash.new(:gid => entry.gid, :members => entry.mem)
    end
  end
  
end

unless current_user
  current_user Etc.getlogin
end