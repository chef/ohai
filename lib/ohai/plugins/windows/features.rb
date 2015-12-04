Ohai.plugin(:Features) do
  provides "installed_features"
  collect_data(:default) do
    installed_features Mash.new
    # Grab raw feature information
    raw_list_of_features = shell_out("C:\\Windows\\sysnative\\dism.exe /Get-Features /Online /Format:Table").stdout
    # Remove Quotes and Split into an array
    features_list = raw_list_of_features.split("\r\n")
    features_list.each do | feature_details_raw |
    # Check for Enabled or Enable Pending (Reboot Needed)
      if ( feature_details_raw =~ /Enabled/ || feature_details_raw =~ /Enable Pending/ )
        feature_details_raw = feature_details_raw.gsub(/\s/,'')
        feature_details = feature_details_raw.split("|")
        feature_details.each do | name |
          installed_features[name.strip] = "Enabled"
        end
      end
    end
  end
end
