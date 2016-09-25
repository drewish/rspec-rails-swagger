# RSpec Swagger

[![Build Status](https://travis-ci.org/drewish/rspec-swagger.svg?branch=master)](https://travis-ci.org/drewish/rspec-swagger)

The design of this is heavily influenced by the awesome [swagger_rails](https://github.com/domaindrivendev/swagger_rails) gem.

## Setup

- install gem
- `rails generate rspec:install`
- create `spec/swagger_helper.rb` (I'll try to get a generator to automate this)
- define your tests (I definitely need to make this step more explicit)

## Generate the docs

```
bundle exec rspec -f RSpec::Swagger::Formatter --order defined -t swagger_object
```


## Running tests

Set up a test site for a specific version of Rails:
```
RAILS_VERSION=4.2.0
./make_site.sh
```

Re-run the tests:
```
bundle exec rspec
```
