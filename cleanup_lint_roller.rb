#!/usr/bin/env ruby
# Removes stray Gemfile.lock shipped inside gems to appease scanners.
require "rubygems"

# List of gems that ship with Gemfile.lock files that should be removed
GEMS_WITH_LOCKFILES = %w{lint_roller stackprof-webnav ohai}.freeze

def cleanup_gem_lockfile(gem_name)
  puts "Cleaning up #{gem_name} Gemfile.lock..."
  specs = Gem::Specification.find_all_by_name(gem_name)
  if specs.empty?
    puts "  No #{gem_name} gem installed"
    return
  end

  specs.each do |spec|
    gemfile_lock_path = File.join(spec.gem_dir, "Gemfile.lock")
    if File.exist?(gemfile_lock_path)
      puts "  Removing #{gemfile_lock_path}"
      File.delete(gemfile_lock_path)
      puts "  Successfully removed #{gem_name} Gemfile.lock"
    else
      puts "  No Gemfile.lock found in #{spec.gem_dir}"
    end
  end
rescue StandardError => e
  warn "  Warning: Failed to clean up #{gem_name} Gemfile.lock: #{e.message}"
end

GEMS_WITH_LOCKFILES.each { |gem_name| cleanup_gem_lockfile(gem_name) }
