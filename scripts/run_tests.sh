#!/bin/bash
set -x -e

bundle exec rspec
# Duplicating the body of the rake task. Need to figure out how to call it directly.
bundle exec rspec -f RSpec::Rails::Swagger::Formatter --order defined -t swagger_object
bundle exec rspec -f RSpec::Rails::Swagger::FormatterOpenApi --order defined -t swagger_object
