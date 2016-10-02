# RSpec Rails Swagger

[![Build Status](https://travis-ci.org/drewish/rspec-rails-swagger.svg?branch=master)](https://travis-ci.org/drewish/rspec-rails-swagger)
[![Code Climate](https://codeclimate.com/github/drewish/rspec-rails-swagger/badges/gpa.svg)](https://codeclimate.com/github/drewish/rspec-rails-swagger)

This gem helps you generate Swagger docs by using RSpec to document the paths.
You execute a command to run the tests and generate the `.json` output. Running
the tests ensures that your API and docs are in agreement, and generates output
that can be used as examples.

The design of this was heavily influenced by the awesome [swagger_rails gem](https://github.com/domaindrivendev/swagger_rails).

## Setup

Add the gem to your Rails app's `Gemfile`:
```rb
group :development, :test do
  gem 'rspec-rails-swagger'
end
```

Update your bundle:
```
bundle install
```

If you don't have a `spec/rails_helper.rb` file:
```
rails generate rspec:install
```

Create the `spec/swagger_helper.rb` file:
```
rails generate rspec:swagger_install
```

## Documenting Your API

Now you can edit `spec/swagger_helper.rb` and start filling in the top level
Swagger documention, e.g. basePath, [definitions](http://swagger.io/specification/#definitionsObject),
[parameters](http://swagger.io/specification/#parametersDefinitionsObject),
[tags](http://swagger.io/specification/#tagObject), etc.

You can use the generator to create a spec to documentation a controller:

```
rails generate rspec:swagger PostsController
```

That will create a `spec/requests/posts_spec.rb` file with the paths, operations
and some default requests filled in. With the structure in place you should only
need to add `before` calls to create records and then update the `let`s to
return the appropriate values.

## Generate the JSON

To create the Swagger JSON files use the rake task:

```
bundle exec rake swagger
```

Now you can use Swagger UI or the renderer of your choice to display the
formatted documentation.
