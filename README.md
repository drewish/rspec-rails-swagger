# RSpec Rails Swagger

[![Build Status](https://travis-ci.org/drewish/rspec-rails-swagger.svg?branch=master)](https://travis-ci.org/drewish/rspec-rails-swagger)
[![Code Climate](https://codeclimate.com/github/drewish/rspec-rails-swagger/badges/gpa.svg)](https://codeclimate.com/github/drewish/rspec-rails-swagger)

This gem helps you generate Swagger docs by using RSpec to document the paths.
You execute a command to run the tests and generate the `.yaml` or `.json` output.
Running the tests ensures that your API and docs are in agreement, and generates
output that can be saved as response examples.

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

## Generate the JSON or YAML

To create the Swagger files use the rake task:

```
bundle exec rake swagger
```

Now you can use Swagger UI or the renderer of your choice to display the
formatted documentation. [swagger_engine](https://github.com/batdevis/swagger_engine)
works pretty well and supports multiple documents.

## RSpec DSL

The DSL follows the hierachy of the Swagger Schema:

- [Paths Object](http://swagger.io/specification/#paths-object-29)
  - [Path Item Object](http://swagger.io/specification/#path-item-object-32)
    - [Parameter Object](http://swagger.io/specification/#parameter-object-44)s (Optional)
    - [Operation Object](http://swagger.io/specification/#operation-object-36)
      - [Parameter Object](http://swagger.io/specification/#parameter-object-44)s (Optional)
      - [Responses Object](http://swagger.io/specification/#responses-object-54)
        - [Response Object](http://swagger.io/specification/#response-object-58)
          - [Example Object](http://swagger.io/specification/#example-object-65)s (Optional)

Here's an example of a spec with comments to for the corresponding objects:

```rb
require 'swagger_helper'

# Paths Object
RSpec.describe "Posts Controller", type: :request do
  before { Post.new.save }

  # Path Item Object
  path '/posts' do
    # Operation Object
    operation "GET", summary: "fetch list" do
      # Response Object
      response 200, description: "successful"
    end
  end

  # Path Object
  path '/posts/{post_id}' do
    # Parameter Object
    parameter "post_id", {in: :path, type: :integer}
    let(:post_id) { 1 }

    # Operation Object
    get summary: "fetch item" do
      # Response Object
      response 200, description: "success"
    end
  end

  # Path Post Object
  path '/posts/' do
    # Parameter Object for content type could be defined like:
    consumes 'application/json'
    # or:
    parameter 'Content-Type', {in: :header, type: :string}
    let(:'Content-Type') { 'application/json' }
    # one of them would be considered

    # authorization token in the header:
    parameter 'Authorization', {in: :header, type: :string}
    let(:'Authorization') { 'Bearer <token-here>' }

    # Parameter Object
    parameter "post_id", {in: :path, type: :integer}
    let(:post_id) { 1 }

    # Parameter Object for Body
    parameter "body", {in: :body, required: true, schema: {
      type: :object,
        properties: {
          title: { type: :string },
          author_email: { type: :email }
        }
    }
    let (:body) {
      { post: 
        { title: 'my example', 
          author_email: 'me@example.com' } 
        }
      }
    }
	# checkout http://swagger.io/specification/#parameter-object-44 for more information, options and details

    # Operation Object
    post summary: "update an item" do
      # Response Object
      response 200, description: "success"
    end
    # ...
end
```


### Paths Object
These methods are available inside of an RSpec contexts with the `type: :request` tag.

#### `path(template, attributes = {}, &block)`
Defines a new Path Item.

### Path Item Object
These methods are available inside of blocks passed to the `path` method.

#### `operation(method, attributes = {}, &block)`
Defines a new Operation Object. The `method` is case insensitive.

#### `delete(attributes = {}, &block)`
Alias for `operation(:delete, attributes, block)`.

#### `get(attributes = {}, &block)`
Alias for `operation(:get, attributes, block)`.

#### `head(attributes = {}, &block)`
Alias for `operation(:head, attributes, block)`.

#### `options(attributes = {}, &block)`
Alias for `operation(:options, attributes, block)`.

#### `patch(attributes = {}, &block)`
Alias for `operation(:patch, attributes, block)`.

#### `post(attributes = {}, &block)`
Alias for `operation(:post, attributes, block)`.

#### `put(attributes = {}, &block)`
Alias for `operation(:put, attributes, block)`.


### Parameters
These methods are available inside of blocks passed to the `path` or `operation` method.

#### `parameter(name, attributes = {})`
Defines a new Parameter Object. You can define the parameter inline:
```rb
parameter :callback_url, in: :query, type: :string, required: true
```

Or, via reference:
```rb
parameter ref: "#/parameters/site_id"
```

Values for the parameters are set using `let`:
```rb
post summary: "create" do
  parameter "body", in: :body, schema: { foo: :bar}
  let(:body) { { post: { title: 'asdf', body: "blah" } } }
  # ...
end
```


### Operation Object
These methods are available inside of blocks passed to the `operation` method.

#### `consumes(*mime_types)`
Use this to add MIME types that are specific to the operation. They will be merged
with the Swagger Object's consumes field.
```rb
consumes 'application/json', 'application/xml'
```

#### `produces(*mime_types)`
Use this to add MIME types that are specific to the operation. They will be merged
with the Swagger Object's consumes field.
```rb
produces 'application/json', 'application/xml'
```

#### `response(status_code, attributes = {}, &block)`
Defines a new Response Object. `status_code` must be between 1 and 599. `attributes`
must include a `description`.

#### `tags(*tags)`
Adds operation specific tags.
```rb
tags :accounts, :pets
```

You can also provide tags through the RSpec context block and/or `path` method:
```rb
RSpec.describe "Sample Requests", type: :request, tags: [:context_tag] do
  path '/posts', tags: ['path_tag'] do
    operation "GET", summary: "fetch list" do
      produces 'application/json'
      tags 'operation_tag'

      response(200, {description: "successful"})
    end
  end
end
```
These tags will be merged with those of the operation. The `GET /posts` operation
in this example will be tagged with `["context_tag", "path_tag", "operation_tag"]`.


### Response Object
These methods are available inside of blocks passed to the `response` method.

#### `capture_example()`
This method will capture the response body from the test and create an Example
Object for the Response.

You could also set this in an RSpec context block if you'd like examples for
multiple operations or paths:
```rb
describe 'Connections', type: :request, capture_examples: true do
  # Any requests in this block will capture example responses
end
```

#### `schema(definition)`
Sets the schema field for the Response Object. You can define it inline:
```rb
schema(
  type: :array,
  items: {
    type: :object,
    properties: {
      id: { type: :string },
      name: { type: :string },
    },
  }
)
```

Or, by reference:
```rb
schema ref: '#/definitions/Account'
```
