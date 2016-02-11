source "https://rubygems.org"

gemspec

group :maintenance do
  gem "tomlrb"

  # To sync maintainers with github
  gem "octokit"
  gem "netrc"
end

group :development do
  gem "chef", github: "chef/chef", branch: "master"

  gem "sigar", :platform => "ruby"
  gem 'plist'

  gem "chefstyle", "= 0.1.0"
  # gem 'pry-byebug'
  # gem 'pry-stack_explorer'
end
