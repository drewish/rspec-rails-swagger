$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "rspec/swagger/version"

Gem::Specification.new do |s|
  s.name        = 'rspec-swagger'
  s.version     = RSpec::Swagger::Version::STRING
  s.licenses    = ['MIT']
  s.summary     = "Generate Swagger docs from RSpec integration tests"
  s.description = "Inspired by swagger_rails"
  s.author      = "andrew morton"
  s.email       = 'drewish@katherinehouse.com'
  s.files       = [
    'lib/rspec/swagger.rb',
    'lib/rspec/swagger/configuration.rb',
    'lib/rspec/swagger/document.rb',
    'lib/rspec/swagger/formatter.rb',
    'lib/rspec/swagger/helpers.rb',
    'lib/rspec/swagger/request_builder.rb',
    'lib/rspec/swagger/version.rb',
  ]
  s.homepage    = 'https://github.com/drewish/rspec-swagger'

  s.required_ruby_version = '~> 2.0'
  s.add_runtime_dependency 'rails', '>= 3.1'
  s.add_runtime_dependency 'rspec-rails', '~> 3.0'
end
