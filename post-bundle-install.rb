#!/usr/bin/env ruby

gem_home = Gem.paths.home

puts "fixing bundle installed gems in #{gem_home}"

# Install gems from git repos.  This makes the assumption that there is a <gem_name>.gemspec and
# you can simply gem build + gem install the resulting gem, so nothing fancy.  This does not use
# rake install since we need --conservative --minimal-deps in order to not install duplicate gems.
#
#
puts "gem path #{gem_home}"

Dir["#{gem_home}/bundler/gems/*"].each do |gempath|
  matches = File.basename(gempath).match(/.*-[A-Fa-f0-9]{12}/)
  next unless matches

  %w[chef-utils chef-config].each do |gem_need_install|
    dir_path = "#{gempath}/#{gem_need_install}"
    gem_name = File.basename(Dir["#{dir_path}/*.gemspec"].first, ".gemspec") 
    # FIXME: should strip any valid ruby platform off of the gem_name if it matches

    next unless gem_name

    puts "re-installing #{gem_name}..."

    Dir.chdir(dir_path) do
      system("gem build #{gem_name}.gemspec") or raise "gem build failed" 
      system("gem install #{gem_name}*.gem --conservative --minimal-deps --no-document") or raise "gem install failed" 
    end
  end
end
