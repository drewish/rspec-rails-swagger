source "https://rubygems.org"

gemspec

# Allow the rails version to come from an ENV setting so Tavis can test multiple
# versions. Inspired by http://www.schneems.com/post/50991826838/testing-against-multiple-rails-versions/
rails_version = ENV['RAILS_VERSION'] || '3.2.22'
rails_major = rails_version.split('.').first
rails_gem = case rails_version
            when "default" then
              "~> 5.0.0"
            else
              "~> #{rails_version}"
            end

gem 'rails', rails_gem
gem 'rspec-rails'
gem 'sqlite3'

# Need this for Rails 4 to get the JSON responses from the scaffold
gem 'jbuilder' if rails_major == '4'

