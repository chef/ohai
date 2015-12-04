Ohai.plugin(:Programs) do
  provides 'installed_programs'
  collect_data do
    installed_programs Mash.new
    raw_list_of_apps = shell_out('wmic product get /format:csv')
    # Some clean ups.
    app_raw_details = raw_list_of_apps.stdout.gsub(/\r\r/,"")
    # Handle ", Inc" in names  like Google, Inc
    app_raw_details = app_raw_details.gsub(/, I/," I")
    # Handle ", USA" in another field like Dynatrace
    app_raw_details = app_raw_details.gsub(/, U/," U")
    app_raw_details_split = app_raw_details.split("\n")
    app_raw_details_split.each do | app |
     unless app =~ /^Node/ || app == ""
       app_info = app.split(",")
        appname = app_info[2]
        installed_programs[appname] = Mash.new
        details = { "vendor" => "#{app_info[25]}", "version" => "#{app_info[26]}" }
        details.each do |attrib|
          installed_programs[appname][attrib[0]] = attrib[1]
        end
      end
    end
  end
end
