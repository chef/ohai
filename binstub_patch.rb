unless ENV["APPBUNDLER_ALLOW_RVM"]
  ENV["APPBUNDLER_ALLOW_RVM"] = "true"
end

# Prepend the package vendor dir, the current user's gem dir, and the Chef gem dir to
# GEM_PATH so that:
#   1. Ohai's vendored dependencies are always found.
#   2. Plugins installed via `gem install <plugin>` are discoverable on both
#      Linux (~/.gem/ruby/VERSION) and Windows (%USERPROFILE%\.gem\ruby\VERSION).
#   3. Gems installed via `chef gem install` (~/.chef/ruby/VERSION/gems) are immediately available.
#
# This block runs before appbundler's env_sanitizer (which calls Gem.clear_paths and
# re-reads GEM_PATH from ENV), so these additions are always picked up correctly.
ohai_vendor = File.expand_path(File.join(__dir__, "..", "vendor"))
# chef-cli gem install places gems under ~/.chef/ruby/RUBY_API_VERSION/gems
chef_gem_dir = File.join(Dir.home, ".chef", "ruby", RbConfig::CONFIG["ruby_version"], "gems")
existing_paths = ENV["GEM_PATH"]&.split(File::PATH_SEPARATOR) || []
ENV["GEM_PATH"] = ([ohai_vendor, Gem.user_dir, chef_gem_dir] + existing_paths).uniq.join(File::PATH_SEPARATOR)
