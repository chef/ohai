
require "etc"

Ohai.plugin(:Passwd) do
  provides "etc", "current_user"

  def fix_encoding(str)
    str.force_encoding(Encoding.default_external) if str.respond_to?(:force_encoding)
    str
  end

  collect_data do
    unless etc
      etc Mash.new

      etc[:passwd] = Mash.new
      etc[:group] = Mash.new

      Etc.passwd do |entry|
        user_passwd_entry = Mash.new(:dir => entry.dir, :gid => entry.gid, :uid => entry.uid, :shell => entry.shell, :gecos => entry.gecos)
        user_passwd_entry.each_value { |v| fix_encoding(v) }
        entry_name = fix_encoding(entry.name)
        etc[:passwd][entry_name] = user_passwd_entry unless etc[:passwd].has_key?(entry_name)
      end

      Etc.group do |entry|
        group_entry = Mash.new(:gid => entry.gid,
                               :members => entry.mem.map { |u| fix_encoding(u) })

        etc[:group][fix_encoding(entry.name)] = group_entry
      end
    end

    unless current_user
      current_user fix_encoding(Etc.getpwuid(Process.euid).name)
    end
  end

  collect_data(:windows) do
    # Etc returns nil on Windows
  end
end
