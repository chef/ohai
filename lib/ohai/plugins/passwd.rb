# frozen_string_literal: true

Ohai.plugin(:Passwd) do
  provides "etc", "current_user"
  optional true

  # @param [String] str
  #
  # @return [String]
  #
  def fix_encoding(str)
    str.force_encoding(Encoding.default_external) if str.respond_to?(:force_encoding)
    str
  end

  collect_data do
    require "etc" unless defined?(Etc)

    unless etc
      etc Mash.new

      etc[:passwd] = Mash.new
      etc[:group] = Mash.new

      Etc.passwd do |entry|
        user_passwd_entry = Mash.new(dir: entry.dir, gid: entry.gid, uid: entry.uid, shell: entry.shell, gecos: entry.gecos)
        user_passwd_entry.each_value { |v| fix_encoding(v) }
        entry_name = fix_encoding(entry.name)
        etc[:passwd][entry_name] = user_passwd_entry unless etc[:passwd].key?(entry_name)
      end

      Etc.group do |entry|
        group_entry = Mash.new(gid: entry.gid,
                               members: entry.mem.map { |u| fix_encoding(u) })

        etc[:group][fix_encoding(entry.name)] = group_entry
      end
    end

    unless current_user
      current_user fix_encoding(Etc.getpwuid(Process.euid).name)
    end
  end

  collect_data(:windows) do
    require "wmi-lite/wmi" unless defined?(WmiLite::Wmi)

    unless etc
      etc Mash.new

      wmi = WmiLite::Wmi.new

      etc[:passwd] = Mash.new
      users = wmi.query("SELECT * FROM Win32_UserAccount WHERE LocalAccount = True")
      users.each do |user|
        uname = user["Name"].strip.downcase
        Ohai::Log.debug("processing user #{uname}")
        etc[:passwd][uname] = Mash.new
        wmi_obj = user.wmi_ole_object
        wmi_obj.properties_.each do |key|
          etc[:passwd][uname][key.name.downcase] = user[key.name]
        end
      end

      etc[:group] = Mash.new
      groups = wmi.query("SELECT * FROM Win32_Group WHERE LocalAccount = True")
      groups.each do |group|
        gname = group["Name"].strip.downcase
        Ohai::Log.debug("processing group #{gname}")
        etc[:group][gname] = Mash.new
        wmi_obj = group.wmi_ole_object
        wmi_obj.properties_.each do |key|
          etc[:group][gname][key.name.downcase] = group[key.name]
        end

        # This is the primary reason that we're using WMI instead of powershell
        # cmdlets - the powershell start up cost is huge, and you *must* do this
        # query for every. single. group. individually.

        # The query returns nothing unless you specify domain *and* name, it's
        # a path, not a set of queries.
        subq = "Win32_Group.Domain='#{group["Domain"]}',Name='#{group["Name"]}'"
        members = wmi.query(
          "SELECT * FROM Win32_GroupUser WHERE GroupComponent=\"#{subq}\""
        )
        etc[:group][gname]["members"] = members.map do |member|
          mi = {}
          info = Hash[
            member["partcomponent"].split(",").map { |x| x.split("=") }.map { |a, b| [a, b.undump] }
          ]
          if info.keys.any? { |x| x.match?("Win32_UserAccount") }
            mi["type"] = :user
          else
            # NOTE: the type here is actually Win32_SystemAccount, because,
            # that's what groups are in the Windows universe.
            mi["type"] = :group
          end
          mi["name"] = info["Name"]
          mi
        end
      end
    end
  end
end
