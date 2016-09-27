$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "rspec/rails/swagger/version"

Gem::Specification.new do |s|
  s.name        = 'rspec-rails-swagger'
  s.version     = RSpec::Rails::Swagger::Version::STRING
  s.licenses    = ['MIT']
  s.summary     = "Generate Swagger docs from RSpec integration tests"
  s.description = "Inspired by swagger_rails"
  s.author      = "andrew morton"
  s.email       = 'drewish@katherinehouse.com'
  s.files       = [
    'lib/rspec/rails/swagger.rb',
    'lib/rspec/rails/swagger/configuration.rb',
    'lib/rspec/rails/swagger/document.rb',
    'lib/rspec/rails/swagger/formatter.rb',
    'lib/rspec/rails/swagger/helpers.rb',
    'lib/rspec/rails/swagger/request_builder.rb',
    'lib/rspec/rails/swagger/version.rb',
    'lib/rspec/rails/swagger/tasks/swagger.rake',
  ]
  s.homepage    = 'https://github.com/drewish/rspec-rails-swagger'

  s.required_ruby_version = '~> 2.0'
  s.add_runtime_dependency 'rails', '>= 3.1'
  s.add_runtime_dependency 'rspec-rails', '~> 3.0'
end
