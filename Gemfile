source "https://rubygems.org"

gemspec

# Allow the rails version to come from an ENV setting so Tavis can test multiple
# versions.
rails_version = ENV['RAILS_VERSION'] || '5.2.0'
rails_major = rails_version.split('.').first

gem 'rails', "~> #{rails_version}"
gem 'pry'
gem 'pry-byebug'
gem 'sqlite3', '~> 1.3.13'

case rails_major
when '3'
  # Rails 3 requires this but it was removed in Ruby 2.2
  gem 'test-unit', '~> 3.0'
when '4'
  # Need this for Rails 4 to get the JSON responses from the scaffold
  gem 'jbuilder'
when '5'
  # Required for 5.2+
  gem 'bootsnap'
end
