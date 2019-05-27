require 'rspec/core'
require 'rspec/rails/swagger/configuration'
require 'rspec/rails/swagger/document'
require 'rspec/rails/swagger/formatter'
require 'rspec/rails/swagger/formatter_open_api'
require 'rspec/rails/swagger/helpers'
require 'rspec/rails/swagger/response_formatters'
require 'rspec/rails/swagger/request_builder'
require 'rspec/rails/swagger/route_parser'
require 'rspec/rails/swagger/version'

module RSpec
  module Rails
    module Swagger
      initialize_configuration RSpec.configuration

      if defined?(::Rails)
        class Railtie < ::Rails::Railtie
          rake_tasks do
            load 'rspec/rails/swagger/tasks/swagger.rake'
          end
          generators do
            require "generators/rspec/swagger/swagger_generator.rb"
          end
        end
      end
    end
  end
end

