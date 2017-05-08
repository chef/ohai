source "https://rubygems.org"

gemspec

group :development do
  gem "sigar", :platform => "ruby"

  gem "chefstyle", "0.4.0"
  gem "overcommit", ">= 0.34.1"
  gem "pry-byebug"
  gem "pry-stack_explorer"
  gem "rb-readline"
  gem "rake", ">= 10.1.0", "< 12.0.0"
  gem "rspec-core", "~> 3.0"
  gem "rspec-expectations", "~> 3.0"
  gem "rspec-mocks", "~> 3.0"
  gem "rspec-collection_matchers", "~> 1.0"
  gem "rspec_junit_formatter"
  gem "github_changelog_generator", git: "https://github.com/tduffield/github-changelog-generator", branch: "adjust-tag-section-mapping"
  gem "activesupport", "< 5.0" if RUBY_VERSION <= "2.2.2" # github_changelog_generator dep
end
