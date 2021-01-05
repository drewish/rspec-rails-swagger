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
  s.files       = Dir['*.md', '*.txt', 'lib/**/*']
  s.homepage    = 'https://github.com/drewish/rspec-rails-swagger'

  s.required_ruby_version = '>= 2.0'
  s.add_runtime_dependency 'rspec-rails', '~> 4.0'
end
