# RSpec Rails Swagger

[![Build Status](https://travis-ci.org/drewish/rspec-rails-swagger.svg?branch=master)](https://travis-ci.org/drewish/rspec-rails-swagger)
[![Code Climate](https://codeclimate.com/github/drewish/rspec-rails-swagger/badges/gpa.svg)](https://codeclimate.com/github/drewish/rspec-rails-swagger)

This gem helps you generate Swagger docs by using RSpec to document the paths.
You execute a command to run the tests and generate the `.json` output. Running
the tests ensures that your API and docs are in agreement, and generates output
that can be used as examples.

The design of this was heavily influenced by the awesome [swagger_rails gem](https://github.com/domaindrivendev/swagger_rails).

## Setup

- Add the gem to your Rails app's `Gemfile`:
```rb
group :development, :test do
  gem 'rspec-rails-swagger'
end
```
- If you don't already have a `spec/rails_helper.rb` file run:
```shell
rails generate rspec:install
```
- Create `spec/swagger_helper.rb` file (eventually [this will become a
generator](https://github.com/drewish/rspec-rails-swagger/issues/3)):
```rb
require 'rspec/rails/swagger'
require 'rails_helper'

RSpec.configure do |config|
  # Specify a root directory where the generated Swagger files will be saved.
  config.swagger_root = Rails.root.to_s + '/swagger'

  # Define one or more Swagger documents and global metadata for each.
  config.swagger_docs = {
    'v1/swagger.json' => {
      swagger: '2.0',
      info: {
        title: 'API V1',
        version: 'v1'
      }
    },
    'v2/swagger.json' => {
      swagger: '2.0',
      info: {
        title: 'API V2',
        version: 'v2'
      }
    }
  }
end
```
- Define your API (I definitely need to make this step more explicit)

## Generate the docs

Eventually [this will become a rake task](https://github.com/drewish/rspec-rails-swagger/issues/2):
```
bundle exec rspec -f RSpec::Rails::Swagger::Formatter --order defined -t swagger_object
```

## Running tests

The `make_site.sh` script will create a test site for a specific version of
Rails and run the tests:
```
RAILS_VERSION=4.2.0
./make_site.sh
```

Once the test site is created you can just re-run the tests:
```
bundle exec rspec
```
