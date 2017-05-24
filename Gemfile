source "https://rubygems.org"

gemspec

# NOTE: do not submit PRs to add pry as a dep, add to your Gemfile.local
group :development do
  gem "chefstyle"
  gem "rake", ">= 10.1.0"
  gem "rspec-core", "~> 3.0"
  gem "rspec-expectations", "~> 3.0"
  gem "rspec-mocks", "~> 3.0"
  gem "rspec-collection_matchers", "~> 1.0"
  gem "ipaddr_extensions"
end

group :ci do
  gem "rspec_junit_formatter"
end

group :changelog do
  gem "github_changelog_generator", git: "https://github.com/chef/github-changelog-generator"
end

instance_eval(ENV["GEMFILE_MOD"]) if ENV["GEMFILE_MOD"]

# If you want to load debugging tools into the bundle exec sandbox,
# add these additional dependencies into chef/Gemfile.local
eval(IO.read(__FILE__ + ".local"), binding) if File.exist?(__FILE__ + ".local")
